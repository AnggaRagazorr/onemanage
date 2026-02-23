<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CarpoolVehicle;
use App\Models\KmAudit;
use Illuminate\Http\Request;

class KmAuditController extends Controller
{
    /**
     * List KM audits, optionally filtered by vehicle or date.
     */
    public function index(Request $request)
    {
        $perPage = max(1, min(500, $request->integer('per_page', 20)));
        $query = KmAudit::with(['vehicle', 'user']);

        if ($request->filled('vehicle_id')) {
            $query->where('vehicle_id', $request->integer('vehicle_id'));
        }

        if ($request->filled('date')) {
            $query->whereDate('date', $request->input('date'));
        }

        if ($request->filled('alerts_only') && $request->boolean('alerts_only')) {
            $query->where('is_alert', true);
        }

        return $query
            ->orderByDesc('date')
            ->orderByDesc('created_at')
            ->paginate($perPage);
    }

    /**
     * Store or update today's KM audit entry per vehicle.
     */
    public function store(Request $request)
    {
        $request->validate([
            'vehicle_id' => 'required|exists:carpool_vehicles,id',
            'actual_km' => 'required|numeric|min:0',
            'notes' => 'nullable|string',
        ]);

        $vehicle = CarpoolVehicle::findOrFail($request->integer('vehicle_id'));
        $recorded = (float) $vehicle->current_km;
        $actual = (float) $request->input('actual_km');
        $difference = abs($actual - $recorded);
        $isAlert = $difference > 50;
        $auditDate = now()->toDateString();

        $payload = [
            'vehicle_id' => $vehicle->id,
            'user_id' => $request->user()->id,
            'date' => $auditDate,
            'recorded_km' => $recorded,
            'actual_km' => $actual,
            'difference' => $difference,
            'is_alert' => $isAlert,
            'notes' => $request->input('notes'),
        ];

        $audit = KmAudit::query()
            ->where('vehicle_id', $vehicle->id)
            ->whereDate('date', $auditDate)
            ->orderByDesc('id')
            ->first();

        $wasUpdated = (bool) $audit;
        if ($audit) {
            $audit->fill($payload);
            $audit->save();
        } else {
            $audit = KmAudit::create($payload);
        }

        $audit->load(['vehicle', 'user']);

        return response()->json([
            'message' => $isAlert
                ? 'ALERT: Selisih KM melebihi batas! (' . $difference . ' KM)'
                : ($wasUpdated
                    ? 'Audit harian berhasil diperbarui (selisih: ' . $difference . ' KM)'
                    : 'Audit harian berhasil disimpan (selisih: ' . $difference . ' KM)'),
            'data' => $audit,
            'is_alert' => $isAlert,
            'updated' => $wasUpdated,
        ], $wasUpdated ? 200 : 201);
    }

    /**
     * Get only alert entries (large discrepancies).
     */
    public function alerts(Request $request)
    {
        $alerts = KmAudit::with(['vehicle', 'user'])
            ->where('is_alert', true)
            ->orderByDesc('date')
            ->orderByDesc('created_at')
            ->paginate(20);

        return $alerts;
    }
}
