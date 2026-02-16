<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LoanNotification extends Model
{
    protected $table = 'notifications';

    protected $fillable = [
        'user_id',
        'sender_id',
        'loan_id',
        'type',
        'title',
        'message',
        'is_read',
    ];

    protected function casts(): array
    {
        return [
            'is_read' => 'boolean',
        ];
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function sender()
    {
        return $this->belongsTo(User::class, 'sender_id');
    }

    public function loan()
    {
        return $this->belongsTo(Loan::class);
    }

    public function scopeUnread($query)
    {
        return $query->where('is_read', false);
    }

    public function markAsRead()
    {
        $this->update(['is_read' => true]);
    }
}
