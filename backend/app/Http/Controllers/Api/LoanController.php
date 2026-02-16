<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Loan;
use App\Models\LoanNotification;
use Illuminate\Http\Request;

class LoanController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();

        $loansGiven = Loan::where('lender_id', $user->id)
            ->with(['borrower', 'payments'])
            ->orderBy('created_at', 'desc')
            ->get();

        $loansTaken = Loan::where('borrower_id', $user->id)
            ->with(['lender', 'payments'])
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'loans_given' => $loansGiven,
            'loans_taken' => $loansTaken,
        ]);
    }

    public function show(Request $request, $id)
    {
        $user = $request->user();

        $loan = Loan::where('id', $id)
            ->where(function ($query) use ($user) {
                $query->where('lender_id', $user->id)
                    ->orWhere('borrower_id', $user->id);
            })
            ->with(['lender', 'borrower', 'payments'])
            ->firstOrFail();

        return response()->json([
            'loan' => $loan,
        ]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'borrower_id' => 'required|exists:users,id',
            'amount' => 'required|numeric|min:0.01',
            'currency' => 'sometimes|string|max:10',
            'description' => 'nullable|string|max:500',
            'due_date' => 'nullable|date|after:today',
        ]);

        $user = $request->user();

        if ($request->borrower_id == $user->id) {
            return response()->json(['message' => 'Cannot create loan to yourself'], 400);
        }

        $loan = Loan::create([
            'lender_id' => $user->id,
            'borrower_id' => $request->borrower_id,
            'amount' => $request->amount,
            'currency' => $request->currency ?? 'MMK',
            'description' => $request->description,
            'due_date' => $request->due_date,
            'status' => 'pending',
            'remaining_amount' => $request->amount,
        ]);

        // Notify borrower
        $message = "{$user->name} created a loan of {$loan->amount} {$loan->currency}";
        if ($loan->due_date) {
            $message .= " (Due: {$loan->due_date->format('M d, Y')})";
        }

        LoanNotification::create([
            'user_id' => $loan->borrower_id,
            'sender_id' => $user->id,
            'loan_id' => $loan->id,
            'type' => 'loan_created',
            'title' => 'New Loan Created',
            'message' => $message,
        ]);

        return response()->json([
            'message' => 'Loan created successfully',
            'loan' => $loan->load(['lender', 'borrower']),
        ], 201);
    }

    public function update(Request $request, $id)
    {
        $user = $request->user();

        $loan = Loan::where('id', $id)
            ->where('lender_id', $user->id)
            ->where('status', '!=', 'paid')
            ->firstOrFail();

        $request->validate([
            'description' => 'sometimes|nullable|string|max:500',
            'due_date' => 'sometimes|nullable|date',
        ]);

        $oldDueDate = $loan->due_date;
        $newDueDate = $request->has('due_date') ? $request->due_date : $oldDueDate;

        $loan->update($request->only(['description', 'due_date']));

        // Notify borrower about due date changes
        if ($request->has('due_date') && $oldDueDate != $newDueDate) {
            if ($oldDueDate === null && $newDueDate !== null) {
                LoanNotification::create([
                    'user_id' => $loan->borrower_id,
                    'sender_id' => $user->id,
                    'loan_id' => $loan->id,
                    'type' => 'due_date_set',
                    'title' => 'Due Date Set',
                    'message' => "{$user->name} set due date to " . $loan->due_date->format('M d, Y'),
                ]);
            } elseif ($oldDueDate !== null && $newDueDate === null) {
                LoanNotification::create([
                    'user_id' => $loan->borrower_id,
                    'sender_id' => $user->id,
                    'loan_id' => $loan->id,
                    'type' => 'due_date_removed',
                    'title' => 'Due Date Removed',
                    'message' => "{$user->name} removed the due date. Pay anytime.",
                ]);
            } else {
                LoanNotification::create([
                    'user_id' => $loan->borrower_id,
                    'sender_id' => $user->id,
                    'loan_id' => $loan->id,
                    'type' => 'due_date_changed',
                    'title' => 'Due Date Changed',
                    'message' => "{$user->name} changed due date to " . $loan->due_date->format('M d, Y'),
                ]);
            }
        }

        return response()->json([
            'message' => 'Loan updated successfully',
            'loan' => $loan->load(['lender', 'borrower']),
        ]);
    }

    public function destroy(Request $request, $id)
    {
        $user = $request->user();

        $loan = Loan::where('id', $id)
            ->where('lender_id', $user->id)
            ->where('status', 'pending')
            ->whereDoesntHave('payments')
            ->firstOrFail();

        $loan->delete();

        return response()->json([
            'message' => 'Loan deleted successfully',
        ]);
    }

    public function loansWithFriend(Request $request, $friendId)
    {
        $user = $request->user();

        $loansGiven = Loan::where('lender_id', $user->id)
            ->where('borrower_id', $friendId)
            ->with(['payments'])
            ->get();

        $loansTaken = Loan::where('lender_id', $friendId)
            ->where('borrower_id', $user->id)
            ->with(['payments'])
            ->get();

        $totalGiven = $loansGiven->where('status', '!=', 'paid')->sum('remaining_amount');
        $totalOwed = $loansTaken->where('status', '!=', 'paid')->sum('remaining_amount');
        $netBalance = $totalGiven - $totalOwed;

        return response()->json([
            'loans_given' => $loansGiven,
            'loans_taken' => $loansTaken,
            'total_given' => $totalGiven,
            'total_owed' => $totalOwed,
            'net_balance' => $netBalance,
        ]);
    }
}
