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
        'vehicle_id',
        'driver_id',
        'date',
        'destination',
        'start_time',
        'end_time',
        'last_km',
        'status',
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
}
