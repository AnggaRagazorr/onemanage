<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CarpoolVehicle;
use Illuminate\Http\Request;

class CarpoolVehicleController extends Controller
{
    public function index()
    {
        return CarpoolVehicle::orderBy('brand')->get();
    }

    public function store(Request $request)
    {
        $request->validate([
            'brand' => 'required|string',
            'plate' => 'required|string|unique:carpool_vehicles,plate',
        ]);

        $vehicle = CarpoolVehicle::create([
            'brand' => $request->string('brand'),
            'plate' => $request->string('plate'),
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
