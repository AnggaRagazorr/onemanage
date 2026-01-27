<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CarpoolDriver;
use Illuminate\Http\Request;

class CarpoolDriverController extends Controller
{
    public function index()
    {
        return CarpoolDriver::orderBy('name')->get();
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string',
            'nip' => 'required|string|unique:carpool_drivers,nip',
        ]);

        $driver = CarpoolDriver::create([
            'name' => $request->string('name'),
            'nip' => $request->string('nip'),
        ]);

        return response()->json([
            'message' => 'Driver ditambahkan',
            'data' => $driver,
        ], 201);
    }

    public function destroy(CarpoolDriver $driver)
    {
        $driver->delete();

        return response()->json([
            'message' => 'Driver dihapus',
        ]);
    }
}
