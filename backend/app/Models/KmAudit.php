<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class KmAudit extends Model
{
    use HasFactory;

    protected $fillable = [
        'vehicle_id',
        'user_id',
        'date',
        'recorded_km',
        'actual_km',
        'difference',
        'is_alert',
        'notes',
    ];

    protected $casts = [
        'recorded_km' => 'decimal:1',
        'actual_km' => 'decimal:1',
        'difference' => 'decimal:1',
        'is_alert' => 'boolean',
    ];

    public function vehicle()
    {
        return $this->belongsTo(CarpoolVehicle::class, 'vehicle_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
