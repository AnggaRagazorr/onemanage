<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Patrol extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'area',
        'barcode',
        'photo_count',
        'photos',
        'captured_at',
    ];

    protected $casts = [
        'photos' => 'array',
        'captured_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
