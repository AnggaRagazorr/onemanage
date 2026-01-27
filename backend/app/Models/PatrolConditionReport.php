<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PatrolConditionReport extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'date',
        'time',
        'situasi',
        'aght',
        'cuaca',
        'pdam',
        'wfo',
        'tambahan',
    ];

    protected $casts = [
        'date' => 'date',
        'wfo' => 'integer',
        'tambahan' => 'integer',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
