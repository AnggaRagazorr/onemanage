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

    public function destroy(CarpoolVehicle $vehicle)
    {
        $vehicle->delete();

        return response()->json([
            'message' => 'Mobil dihapus',
        ]);
    }
}
