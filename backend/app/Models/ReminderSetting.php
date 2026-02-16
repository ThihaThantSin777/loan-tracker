<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ReminderSetting extends Model
{
    protected $fillable = [
        'user_id',
        'auto_remind',
        'days_before',
        'quiet_hour_start',
        'quiet_hour_end',
    ];

    protected function casts(): array
    {
        return [
            'auto_remind' => 'boolean',
            'days_before' => 'integer',
        ];
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
