<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CarpoolVehicle;
use Illuminate\Http\Request;

class CarpoolVehicleController extends Controller
{
    public function index()
    {
        return CarpoolVehicle::with(['activeLog.driver', 'lastAudit'])
            ->orderBy('brand')
            ->get()
            ->map(function ($v) {
                $activeLog = $v->activeLog;
                return [
                    'id' => $v->id,
                    'brand' => $v->brand,
                    'plate' => $v->plate,
                    'status' => $v->status,
                    'current_km' => $v->current_km,
                    'driver_name' => $activeLog && $activeLog->driver ? $activeLog->driver->name : null,
                    'driver_nip' => $activeLog && $activeLog->driver ? $activeLog->driver->nip : null,
                    'last_audit' => $v->lastAudit,
                ];
            });
    }

    public function store(Request $request)
    {
        $request->validate([
            'brand' => 'required|string',
            'plate' => 'required|string|unique:carpool_vehicles,plate',
            'current_km' => 'nullable|numeric|min:0',
        ]);

        $vehicle = CarpoolVehicle::create([
            'brand' => $request->string('brand'),
            'plate' => $request->string('plate'),
            'current_km' => $request->input('current_km', 0),
        ]);

        return response()->json([
            'message' => 'Mobil ditambahkan',
            'data' => $vehicle,
        ], 201);
    }

    public function update(Request $request, CarpoolVehicle $vehicle)
    {
        if (!$vehicle->isAvailable()) {
            return response()->json([
                'message' => 'Kendaraan tidak bisa diedit saat sedang digunakan',
            ], 422);
        }

        $request->validate([
            'brand' => 'required|string',
            'plate' => ['required', 'string', \Illuminate\Validation\Rule::unique('carpool_vehicles', 'plate')->ignore($vehicle->id)],
            'current_km' => 'nullable|numeric|min:0',
        ]);

        $vehicle->update([
            'brand' => $request->string('brand'),
            'plate' => $request->string('plate'),
            'current_km' => $request->input('current_km', $vehicle->current_km),
        ]);

        return response()->json([
            'message' => 'Kendaraan diperbarui',
            'data' => $vehicle->fresh(),
        ]);
    }

    public function destroy(CarpoolVehicle $vehicle)
    {
        $hasActiveTrip = \App\Models\CarpoolLog::where('vehicle_id', $vehicle->id)
            ->whereIn('status', ['approved', 'confirmed', 'in_use', 'pending_key'])
            ->exists();

        if ($hasActiveTrip || !$vehicle->isAvailable()) {
            return response()->json([
                'message' => 'Kendaraan tidak bisa dihapus karena masih ada trip aktif',
            ], 422);
        }

        $vehicle->delete();

        return response()->json([
            'message' => 'Mobil dihapus',
        ]);
    }
}
