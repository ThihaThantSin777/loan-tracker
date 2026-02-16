<?php

namespace App\Console\Commands;

use App\Models\Loan;
use App\Models\LoanNotification;
use App\Services\FirebaseNotificationService;
use Carbon\Carbon;
use Illuminate\Console\Command;

class SendLoanReminders extends Command
{
    protected $signature = 'loans:send-reminders';
    protected $description = 'Send automatic reminders for loans due soon or overdue';

    protected $firebase;

    public function __construct()
    {
        parent::__construct();
    }

    public function handle()
    {
        $this->firebase = new FirebaseNotificationService();

        $this->info('Starting loan reminder process...');

        // Send reminders for different scenarios
        $this->sendDueTodayReminders();
        $this->sendDueTomorrowReminders();
        $this->sendDueIn3DaysReminders();
        $this->sendOverdueReminders();

        $this->info('Loan reminder process completed!');

        return Command::SUCCESS;
    }

    /**
     * Send reminders for loans due today
     */
    private function sendDueTodayReminders()
    {
        $loans = Loan::where('status', '!=', 'paid')
            ->whereDate('due_date', Carbon::today())
            ->with(['borrower', 'lender'])
            ->get();

        foreach ($loans as $loan) {
            $this->sendReminderNotification(
                $loan,
                'Payment Due Today',
                "Your loan of {$loan->remaining_amount} {$loan->currency} to {$loan->lender->name} is due today!",
                'due_today'
            );
        }

        $this->info("Sent {$loans->count()} 'due today' reminders.");
    }

    /**
     * Send reminders for loans due tomorrow
     */
    private function sendDueTomorrowReminders()
    {
        $loans = Loan::where('status', '!=', 'paid')
            ->whereDate('due_date', Carbon::tomorrow())
            ->with(['borrower', 'lender'])
            ->get();

        foreach ($loans as $loan) {
            $this->sendReminderNotification(
                $loan,
                'Payment Due Tomorrow',
                "Reminder: Your loan of {$loan->remaining_amount} {$loan->currency} to {$loan->lender->name} is due tomorrow.",
                'due_tomorrow'
            );
        }

        $this->info("Sent {$loans->count()} 'due tomorrow' reminders.");
    }

    /**
     * Send reminders for loans due in 3 days
     */
    private function sendDueIn3DaysReminders()
    {
        $loans = Loan::where('status', '!=', 'paid')
            ->whereDate('due_date', Carbon::today()->addDays(3))
            ->with(['borrower', 'lender'])
            ->get();

        foreach ($loans as $loan) {
            $this->sendReminderNotification(
                $loan,
                'Payment Due in 3 Days',
                "Upcoming: Your loan of {$loan->remaining_amount} {$loan->currency} to {$loan->lender->name} is due in 3 days.",
                'due_soon'
            );
        }

        $this->info("Sent {$loans->count()} 'due in 3 days' reminders.");
    }

    /**
     * Send reminders for overdue loans (once per day)
     */
    private function sendOverdueReminders()
    {
        $loans = Loan::where('status', '!=', 'paid')
            ->whereNotNull('due_date')
            ->whereDate('due_date', '<', Carbon::today())
            ->with(['borrower', 'lender'])
            ->get();

        foreach ($loans as $loan) {
            $daysOverdue = Carbon::parse($loan->due_date)->diffInDays(Carbon::today());

            $this->sendReminderNotification(
                $loan,
                'Payment Overdue',
                "Your loan of {$loan->remaining_amount} {$loan->currency} to {$loan->lender->name} is {$daysOverdue} days overdue!",
                'overdue'
            );
        }

        $this->info("Sent {$loans->count()} 'overdue' reminders.");
    }

    /**
     * Send reminder notification to borrower
     */
    private function sendReminderNotification(Loan $loan, string $title, string $message, string $type)
    {
        // Check if we already sent this type of reminder today
        $alreadySent = LoanNotification::where('loan_id', $loan->id)
            ->where('user_id', $loan->borrower_id)
            ->where('type', 'auto_reminder')
            ->whereDate('created_at', Carbon::today())
            ->whereRaw("JSON_EXTRACT(data, '$.reminder_type') = ?", [$type])
            ->exists();

        if ($alreadySent) {
            return; // Skip if already sent today
        }

        // Create database notification
        LoanNotification::create([
            'user_id' => $loan->borrower_id,
            'sender_id' => null, // System notification
            'loan_id' => $loan->id,
            'type' => 'auto_reminder',
            'title' => $title,
            'message' => $message,
            'data' => json_encode(['reminder_type' => $type]),
        ]);

        // Send push notification
        $this->firebase->sendToUser($loan->borrower, $title, $message, [
            'type' => 'auto_reminder',
            'loan_id' => (string) $loan->id,
            'reminder_type' => $type,
        ]);
    }
}
