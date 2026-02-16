<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasFactory, Notifiable, HasApiTokens;

    protected $fillable = [
        'name',
        'email',
        'phone',
        'password',
        'avatar_url',
        'fcm_token',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    // Friendships where user sent request
    public function sentFriendRequests()
    {
        return $this->hasMany(Friendship::class, 'user_id');
    }

    // Friendships where user received request
    public function receivedFriendRequests()
    {
        return $this->hasMany(Friendship::class, 'friend_id');
    }

    // Get all accepted friends
    public function friends()
    {
        $sentFriends = $this->belongsToMany(User::class, 'friendships', 'user_id', 'friend_id')
            ->wherePivot('status', 'accepted');

        $receivedFriends = $this->belongsToMany(User::class, 'friendships', 'friend_id', 'user_id')
            ->wherePivot('status', 'accepted');

        return $sentFriends->union($receivedFriends);
    }

    // Loans where user is the lender
    public function loansGiven()
    {
        return $this->hasMany(Loan::class, 'lender_id');
    }

    // Loans where user is the borrower
    public function loansTaken()
    {
        return $this->hasMany(Loan::class, 'borrower_id');
    }

    // Payments made by user
    public function payments()
    {
        return $this->hasMany(Payment::class, 'payer_id');
    }

    // Notifications received
    public function notifications()
    {
        return $this->hasMany(LoanNotification::class, 'user_id');
    }

    // Reminder settings
    public function reminderSetting()
    {
        return $this->hasOne(ReminderSetting::class);
    }
}
