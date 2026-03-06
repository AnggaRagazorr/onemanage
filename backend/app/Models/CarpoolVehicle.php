<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CarpoolVehicle extends Model
{
    use HasFactory;

    protected $fillable = [
        'brand',
        'plate',
        'status',
        'current_km',
    ];

    protected $casts = [
        'current_km' => 'decimal:1',
    ];

    public function isAvailable(): bool
    {
        return $this->status === 'available';
    }

    public function markInUse(): void
    {
        $this->update(['status' => 'in_use']);
    }

    public function markPendingKey(): void
    {
        $this->update(['status' => 'pending_key']);
    }

    public function markAvailable(): void
    {
        $this->update(['status' => 'available']);
    }

    public function logs()
    {
        return $this->hasMany(CarpoolLog::class, 'vehicle_id');
    }

    public function kmAudits()
    {
        return $this->hasMany(KmAudit::class, 'vehicle_id');
    }

    public function lastAudit()
    {
        return $this->hasOne(KmAudit::class, 'vehicle_id')->latest();
    }

    /**
     * Get the driver currently assigned (from active trip)
     */
    public function activeLog()
    {
        return $this->hasOne(CarpoolLog::class, 'vehicle_id')
            ->whereIn('status', ['approved', 'confirmed', 'in_use', 'pending_key'])
            ->latest();
    }
}
