<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Loan;
use App\Models\LoanNotification;
use App\Models\Payment;
use App\Services\FirebaseNotificationService;
use CloudinaryLabs\CloudinaryLaravel\Facades\Cloudinary;
use Illuminate\Http\Request;

class PaymentController extends Controller
{
    protected $firebase;

    public function __construct(FirebaseNotificationService $firebase)
    {
        $this->firebase = $firebase;
    }

    public function store(Request $request)
    {
        $request->validate([
            'loan_id' => 'required|exists:loans,id',
            'amount' => 'required|numeric|min:0.01',
            'payment_method' => 'required|in:cash,e_wallet',
            'screenshot' => 'required_if:payment_method,e_wallet|image|max:5120',
        ]);

        $user = $request->user();

        $loan = Loan::where('id', $request->loan_id)
            ->where('borrower_id', $user->id)
            ->where('status', '!=', 'paid')
            ->with('lender')
            ->firstOrFail();

        if ($request->amount > $loan->remaining_amount) {
            return response()->json([
                'message' => 'Payment amount exceeds remaining balance',
            ], 400);
        }

        $screenshotUrl = null;

        // Upload screenshot to Cloudinary if e_wallet
        if ($request->payment_method === 'e_wallet' && $request->hasFile('screenshot')) {
            $uploadedFile = Cloudinary::upload($request->file('screenshot')->getRealPath(), [
                'folder' => 'loan_tracker/payments',
            ]);
            $screenshotUrl = $uploadedFile->getSecurePath();
        }

        // For cash payment, auto-accept
        $status = $request->payment_method === 'cash' ? 'accepted' : 'pending';

        $payment = Payment::create([
            'loan_id' => $loan->id,
            'payer_id' => $user->id,
            'amount' => $request->amount,
            'payment_method' => $request->payment_method,
            'screenshot_url' => $screenshotUrl,
            'status' => $status,
            'verified_at' => $status === 'accepted' ? now() : null,
            'verified_by' => $status === 'accepted' ? $loan->lender_id : null,
        ]);

        // Update loan if cash payment (auto-accepted)
        if ($status === 'accepted') {
            $this->updateLoanAfterPayment($loan, $request->amount);
        }

        // Notify lender
        $notificationType = $request->payment_method === 'cash' ? 'payment_verified' : 'payment_received';
        $title = $request->payment_method === 'cash' ? 'Payment Received (Cash)' : 'Payment Proof Submitted';
        $message = $request->payment_method === 'cash'
            ? "{$user->name} paid {$payment->amount} {$loan->currency} in cash"
            : "{$user->name} submitted payment proof of {$payment->amount} {$loan->currency}. Please verify.";

        LoanNotification::create([
            'user_id' => $loan->lender_id,
            'sender_id' => $user->id,
            'loan_id' => $loan->id,
            'type' => $notificationType,
            'title' => $title,
            'message' => $message,
        ]);

        // Send push notification to lender
        $this->firebase->sendToUser($loan->lender, $title, $message, [
            'type' => $notificationType,
            'loan_id' => (string) $loan->id,
            'payment_id' => (string) $payment->id,
        ]);

        return response()->json([
            'message' => 'Payment submitted successfully',
            'payment' => $payment->load(['loan', 'payer']),
        ], 201);
    }

    public function accept(Request $request, $id)
    {
        $user = $request->user();

        $payment = Payment::where('id', $id)
            ->where('status', 'pending')
            ->whereHas('loan', function ($query) use ($user) {
                $query->where('lender_id', $user->id);
            })
            ->with(['loan', 'payer'])
            ->firstOrFail();

        $payment->update([
            'status' => 'accepted',
            'verified_at' => now(),
            'verified_by' => $user->id,
        ]);

        // Update loan remaining amount
        $this->updateLoanAfterPayment($payment->loan, $payment->amount);

        // Notify payer
        $title = 'Payment Accepted';
        $message = "{$user->name} accepted your payment of {$payment->amount} {$payment->loan->currency}";

        LoanNotification::create([
            'user_id' => $payment->payer_id,
            'sender_id' => $user->id,
            'loan_id' => $payment->loan_id,
            'type' => 'payment_verified',
            'title' => $title,
            'message' => $message,
        ]);

        // Send push notification to payer
        $this->firebase->sendToUser($payment->payer, $title, $message, [
            'type' => 'payment_verified',
            'loan_id' => (string) $payment->loan_id,
            'payment_id' => (string) $payment->id,
        ]);

        return response()->json([
            'message' => 'Payment accepted',
            'payment' => $payment->load(['loan', 'payer']),
        ]);
    }

    public function reject(Request $request, $id)
    {
        $request->validate([
            'reason' => 'required|string|max:500',
        ]);

        $user = $request->user();

        $payment = Payment::where('id', $id)
            ->where('status', 'pending')
            ->whereHas('loan', function ($query) use ($user) {
                $query->where('lender_id', $user->id);
            })
            ->with(['loan', 'payer'])
            ->firstOrFail();

        $payment->update([
            'status' => 'rejected',
            'rejected_reason' => $request->reason,
            'verified_at' => now(),
            'verified_by' => $user->id,
        ]);

        // Notify payer
        $title = 'Payment Rejected';
        $message = "{$user->name} rejected your payment: {$request->reason}";

        LoanNotification::create([
            'user_id' => $payment->payer_id,
            'sender_id' => $user->id,
            'loan_id' => $payment->loan_id,
            'type' => 'payment_rejected',
            'title' => $title,
            'message' => $message,
        ]);

        // Send push notification to payer
        $this->firebase->sendToUser($payment->payer, $title, $message, [
            'type' => 'payment_rejected',
            'loan_id' => (string) $payment->loan_id,
            'payment_id' => (string) $payment->id,
        ]);

        return response()->json([
            'message' => 'Payment rejected',
            'payment' => $payment->load(['loan', 'payer']),
        ]);
    }

    public function pendingVerifications(Request $request)
    {
        $user = $request->user();

        $payments = Payment::where('status', 'pending')
            ->whereHas('loan', function ($query) use ($user) {
                $query->where('lender_id', $user->id);
            })
            ->with(['loan', 'payer'])
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'payments' => $payments,
        ]);
    }

    private function updateLoanAfterPayment(Loan $loan, float $amount)
    {
        $newRemaining = $loan->remaining_amount - $amount;

        if ($newRemaining <= 0) {
            $loan->update([
                'remaining_amount' => 0,
                'status' => 'paid',
            ]);
        } else {
            $loan->update([
                'remaining_amount' => $newRemaining,
                'status' => 'partial',
            ]);
        }
    }
}
