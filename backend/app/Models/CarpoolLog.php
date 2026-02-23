<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CarpoolLog extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'user_name',
        'passenger_names',
        'vehicle_id',
        'driver_id',
        'date',
        'destination',
        'start_time',
        'end_time',
        'last_km',
        'status',
        'approved_by',
        'approved_at',
        'trip_started_at',
        'trip_finished_at',
        'key_validated_by',
        'key_returned_at',
    ];

    protected $casts = [
        'approved_at' => 'datetime',
        'trip_started_at' => 'datetime',
        'trip_finished_at' => 'datetime',
        'key_returned_at' => 'datetime',
    ];

    public function vehicle()
    {
        return $this->belongsTo(CarpoolVehicle::class, 'vehicle_id');
    }

    public function driver()
    {
        return $this->belongsTo(CarpoolDriver::class, 'driver_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function approver()
    {
        return $this->belongsTo(User::class, 'approved_by');
    }

    public function keyValidator()
    {
        return $this->belongsTo(User::class, 'key_validated_by');
    }
}
