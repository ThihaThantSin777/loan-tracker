<?php

namespace Database\Seeders;

use App\Models\Friendship;
use App\Models\Loan;
use App\Models\LoanNotification;
use App\Models\Payment;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Create test users
        $user1 = User::create([
            'name' => 'John Doe',
            'email' => 'john@test.com',
            'phone' => '09123456789',
            'password' => Hash::make('password123'),
        ]);

        $user2 = User::create([
            'name' => 'Jane Smith',
            'email' => 'jane@test.com',
            'phone' => '09987654321',
            'password' => Hash::make('password123'),
        ]);

        $user3 = User::create([
            'name' => 'Bob Wilson',
            'email' => 'bob@test.com',
            'phone' => '09111222333',
            'password' => Hash::make('password123'),
        ]);

        $user4 = User::create([
            'name' => 'Alice Brown',
            'email' => 'alice@test.com',
            'phone' => '09444555666',
            'password' => Hash::make('password123'),
        ]);

        // Create friendships
        // John and Jane are friends
        Friendship::create([
            'user_id' => $user1->id,
            'friend_id' => $user2->id,
            'status' => 'accepted',
        ]);

        // John and Bob are friends
        Friendship::create([
            'user_id' => $user1->id,
            'friend_id' => $user3->id,
            'status' => 'accepted',
        ]);

        // Jane and Alice are friends
        Friendship::create([
            'user_id' => $user2->id,
            'friend_id' => $user4->id,
            'status' => 'accepted',
        ]);

        // Alice sent pending request to John
        Friendship::create([
            'user_id' => $user4->id,
            'friend_id' => $user1->id,
            'status' => 'pending',
        ]);

        // Create loans
        // John lent 50000 MMK to Jane (pending)
        $loan1 = Loan::create([
            'lender_id' => $user1->id,
            'borrower_id' => $user2->id,
            'amount' => 50000,
            'currency' => 'MMK',
            'description' => 'Lunch money',
            'due_date' => now()->addDays(7),
            'status' => 'pending',
            'remaining_amount' => 50000,
        ]);

        // John lent 100000 MMK to Bob (partial paid)
        $loan2 = Loan::create([
            'lender_id' => $user1->id,
            'borrower_id' => $user3->id,
            'amount' => 100000,
            'currency' => 'MMK',
            'description' => 'Emergency fund',
            'due_date' => now()->addDays(14),
            'status' => 'partial',
            'remaining_amount' => 60000,
        ]);

        // Jane lent 30000 MMK to John (pending)
        $loan3 = Loan::create([
            'lender_id' => $user2->id,
            'borrower_id' => $user1->id,
            'amount' => 30000,
            'currency' => 'MMK',
            'description' => 'Coffee and snacks',
            'due_date' => now()->addDays(3),
            'status' => 'pending',
            'remaining_amount' => 30000,
        ]);

        // Bob lent 200000 MMK to John (paid)
        $loan4 = Loan::create([
            'lender_id' => $user3->id,
            'borrower_id' => $user1->id,
            'amount' => 200000,
            'currency' => 'MMK',
            'description' => 'Project expenses',
            'due_date' => now()->subDays(5),
            'status' => 'paid',
            'remaining_amount' => 0,
        ]);

        // Jane lent 75000 MMK to Alice (overdue)
        $loan5 = Loan::create([
            'lender_id' => $user2->id,
            'borrower_id' => $user4->id,
            'amount' => 75000,
            'currency' => 'MMK',
            'description' => 'Shopping',
            'due_date' => now()->subDays(3),
            'status' => 'pending',
            'remaining_amount' => 75000,
        ]);

        // Create payments
        // Bob paid 40000 to John's loan (accepted)
        Payment::create([
            'loan_id' => $loan2->id,
            'payer_id' => $user3->id,
            'amount' => 40000,
            'payment_method' => 'cash',
            'status' => 'accepted',
            'verified_at' => now()->subDays(2),
            'verified_by' => $user1->id,
        ]);

        // John paid full amount to Bob's loan (accepted)
        Payment::create([
            'loan_id' => $loan4->id,
            'payer_id' => $user1->id,
            'amount' => 200000,
            'payment_method' => 'e_wallet',
            'screenshot_url' => 'https://example.com/screenshot.jpg',
            'status' => 'accepted',
            'verified_at' => now()->subDays(5),
            'verified_by' => $user3->id,
        ]);

        // Create some notifications
        LoanNotification::create([
            'user_id' => $user2->id,
            'sender_id' => $user1->id,
            'loan_id' => $loan1->id,
            'type' => 'loan_created',
            'title' => 'New Loan Created',
            'message' => 'John Doe created a loan of 50000 MMK',
            'is_read' => false,
        ]);

        LoanNotification::create([
            'user_id' => $user1->id,
            'sender_id' => $user4->id,
            'type' => 'friend_request',
            'title' => 'New Friend Request',
            'message' => 'Alice Brown sent you a friend request',
            'is_read' => false,
        ]);

        LoanNotification::create([
            'user_id' => $user1->id,
            'sender_id' => $user3->id,
            'loan_id' => $loan2->id,
            'type' => 'payment_verified',
            'title' => 'Payment Received (Cash)',
            'message' => 'Bob Wilson paid 40000 MMK in cash',
            'is_read' => true,
        ]);

        $this->command->info('Seed data created successfully!');
        $this->command->info('');
        $this->command->info('Test Users:');
        $this->command->info('  - john@test.com / password123');
        $this->command->info('  - jane@test.com / password123');
        $this->command->info('  - bob@test.com / password123');
        $this->command->info('  - alice@test.com / password123');
    }
}
