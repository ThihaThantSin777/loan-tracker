<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('payments', function (Blueprint $table) {
            $table->dropForeign(['e_wallet_id']);
            $table->dropColumn('e_wallet_id');
        });

        Schema::dropIfExists('e_wallets');
    }

    public function down(): void
    {
        Schema::create('e_wallets', function (Blueprint $table) {
            $table->id();
            $table->string('name', 100);
            $table->string('icon_url', 500)->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::table('payments', function (Blueprint $table) {
            $table->foreignId('e_wallet_id')->nullable()->constrained('e_wallets');
        });
    }
};
