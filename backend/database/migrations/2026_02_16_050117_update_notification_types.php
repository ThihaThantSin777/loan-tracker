<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // Update enum to include more notification types
        DB::statement("ALTER TABLE notifications MODIFY COLUMN type ENUM(
            'reminder',
            'payment_received',
            'payment_verified',
            'payment_rejected',
            'due_soon',
            'overdue',
            'due_date_set',
            'due_date_changed',
            'due_date_removed',
            'loan_created',
            'friend_request',
            'friend_accepted'
        )");
    }

    public function down(): void
    {
        DB::statement("ALTER TABLE notifications MODIFY COLUMN type ENUM(
            'reminder',
            'payment_received',
            'payment_verified',
            'payment_rejected',
            'due_soon',
            'overdue'
        )");
    }
};
