<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Loan;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AnalyticsController extends Controller
{
    public function summary(Request $request)
    {
        $user = $request->user();

        // Total you are owed (loans given, not paid)
        $totalOwedToYou = Loan::where('lender_id', $user->id)
            ->where('status', '!=', 'paid')
            ->sum('remaining_amount');

        // Total you owe (loans taken, not paid)
        $totalYouOwe = Loan::where('borrower_id', $user->id)
            ->where('status', '!=', 'paid')
            ->sum('remaining_amount');

        // Net balance (positive = others owe you, negative = you owe others)
        $netBalance = $totalOwedToYou - $totalYouOwe;

        // Counts
        $pendingLoansGiven = Loan::where('lender_id', $user->id)
            ->where('status', '!=', 'paid')
            ->count();

        $pendingLoansTaken = Loan::where('borrower_id', $user->id)
            ->where('status', '!=', 'paid')
            ->count();

        // Overdue loans
        $overdueLoansGiven = Loan::where('lender_id', $user->id)
            ->where('status', '!=', 'paid')
            ->whereNotNull('due_date')
            ->where('due_date', '<', now())
            ->count();

        $overdueLoansOwed = Loan::where('borrower_id', $user->id)
            ->where('status', '!=', 'paid')
            ->whereNotNull('due_date')
            ->where('due_date', '<', now())
            ->count();

        return response()->json([
            'total_owed_to_you' => $totalOwedToYou,
            'total_you_owe' => $totalYouOwe,
            'net_balance' => $netBalance,
            'pending_loans_given' => $pendingLoansGiven,
            'pending_loans_taken' => $pendingLoansTaken,
            'overdue_loans_given' => $overdueLoansGiven,
            'overdue_loans_owed' => $overdueLoansOwed,
        ]);
    }

    public function byFriend(Request $request)
    {
        $user = $request->user();

        // Get all friends with loan balances
        $loansGiven = Loan::where('lender_id', $user->id)
            ->where('status', '!=', 'paid')
            ->select('borrower_id', DB::raw('SUM(remaining_amount) as total'))
            ->groupBy('borrower_id')
            ->with('borrower:id,name,avatar_url')
            ->get()
            ->mapWithKeys(function ($loan) {
                return [$loan->borrower_id => [
                    'user' => $loan->borrower,
                    'they_owe_you' => $loan->total,
                    'you_owe_them' => 0,
                ]];
            });

        $loansTaken = Loan::where('borrower_id', $user->id)
            ->where('status', '!=', 'paid')
            ->select('lender_id', DB::raw('SUM(remaining_amount) as total'))
            ->groupBy('lender_id')
            ->with('lender:id,name,avatar_url')
            ->get();

        foreach ($loansTaken as $loan) {
            if (isset($loansGiven[$loan->lender_id])) {
                $loansGiven[$loan->lender_id]['you_owe_them'] = $loan->total;
            } else {
                $loansGiven[$loan->lender_id] = [
                    'user' => $loan->lender,
                    'they_owe_you' => 0,
                    'you_owe_them' => $loan->total,
                ];
            }
        }

        // Calculate net balance for each friend
        $friendBalances = collect($loansGiven)->map(function ($data) {
            $data['net_balance'] = $data['they_owe_you'] - $data['you_owe_them'];
            return $data;
        })->sortByDesc('net_balance')->values();

        return response()->json([
            'friend_balances' => $friendBalances,
        ]);
    }

    public function monthly(Request $request)
    {
        $user = $request->user();
        $months = $request->query('months', 6);

        $startDate = now()->subMonths($months)->startOfMonth();

        // Loans given per month
        $loansGiven = Loan::where('lender_id', $user->id)
            ->where('created_at', '>=', $startDate)
            ->select(
                DB::raw('YEAR(created_at) as year'),
                DB::raw('MONTH(created_at) as month'),
                DB::raw('SUM(amount) as total'),
                DB::raw('COUNT(*) as count')
            )
            ->groupBy('year', 'month')
            ->orderBy('year')
            ->orderBy('month')
            ->get();

        // Loans taken per month
        $loansTaken = Loan::where('borrower_id', $user->id)
            ->where('created_at', '>=', $startDate)
            ->select(
                DB::raw('YEAR(created_at) as year'),
                DB::raw('MONTH(created_at) as month'),
                DB::raw('SUM(amount) as total'),
                DB::raw('COUNT(*) as count')
            )
            ->groupBy('year', 'month')
            ->orderBy('year')
            ->orderBy('month')
            ->get();

        return response()->json([
            'loans_given' => $loansGiven,
            'loans_taken' => $loansTaken,
        ]);
    }

    public function upcomingDueDates(Request $request)
    {
        $user = $request->user();
        $days = $request->query('days', 7);

        // Loans you need to pay (due soon)
        $loansToPay = Loan::where('borrower_id', $user->id)
            ->where('status', '!=', 'paid')
            ->whereNotNull('due_date')
            ->whereBetween('due_date', [now(), now()->addDays($days)])
            ->with('lender:id,name')
            ->orderBy('due_date')
            ->get();

        // Loans others need to pay you (due soon)
        $loansToReceive = Loan::where('lender_id', $user->id)
            ->where('status', '!=', 'paid')
            ->whereNotNull('due_date')
            ->whereBetween('due_date', [now(), now()->addDays($days)])
            ->with('borrower:id,name')
            ->orderBy('due_date')
            ->get();

        return response()->json([
            'loans_to_pay' => $loansToPay,
            'loans_to_receive' => $loansToReceive,
        ]);
    }
}
