<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Loan;
use App\Models\LoanNotification;
use App\Models\User;
use App\Services\FirebaseNotificationService;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    protected $firebase;

    public function __construct(FirebaseNotificationService $firebase)
    {
        $this->firebase = $firebase;
    }

    public function index(Request $request)
    {
        $user = $request->user();

        $notifications = LoanNotification::where('user_id', $user->id)
            ->with(['sender', 'loan'])
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        return response()->json($notifications);
    }

    public function unreadCount(Request $request)
    {
        $count = LoanNotification::where('user_id', $request->user()->id)
            ->where('is_read', false)
            ->count();

        return response()->json([
            'unread_count' => $count,
        ]);
    }

    public function markAsRead(Request $request, $id)
    {
        $notification = LoanNotification::where('id', $id)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        $notification->update(['is_read' => true]);

        return response()->json([
            'message' => 'Notification marked as read',
        ]);
    }

    public function markAllAsRead(Request $request)
    {
        LoanNotification::where('user_id', $request->user()->id)
            ->where('is_read', false)
            ->update(['is_read' => true]);

        return response()->json([
            'message' => 'All notifications marked as read',
        ]);
    }

    public function sendReminder(Request $request, $loanId)
    {
        $request->validate([
            'message' => 'nullable|string|max:500',
        ]);

        $user = $request->user();

        $loan = Loan::where('id', $loanId)
            ->where('lender_id', $user->id)
            ->where('status', '!=', 'paid')
            ->with('borrower')
            ->firstOrFail();

        $customMessage = $request->message ?? "Please pay back the loan of {$loan->remaining_amount} {$loan->currency}";
        $title = 'Payment Reminder';
        $message = "{$user->name}: {$customMessage}";

        LoanNotification::create([
            'user_id' => $loan->borrower_id,
            'sender_id' => $user->id,
            'loan_id' => $loan->id,
            'type' => 'reminder',
            'title' => $title,
            'message' => $message,
        ]);

        // Send push notification
        $this->firebase->sendToUser($loan->borrower, $title, $message, [
            'type' => 'reminder',
            'loan_id' => (string) $loan->id,
        ]);

        return response()->json([
            'message' => 'Reminder sent successfully',
        ]);
    }

    public function delete(Request $request, $id)
    {
        $notification = LoanNotification::where('id', $id)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        $notification->delete();

        return response()->json([
            'message' => 'Notification deleted',
        ]);
    }
}
