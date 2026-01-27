<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CarpoolLog;
use Illuminate\Http\Request;

class CarpoolLogController extends Controller
{
    public function index(Request $request)
    {
        $query = CarpoolLog::with(['vehicle', 'driver', 'user']);

        if ($request->user()->role !== 'admin') {
            $query->where('user_id', $request->user()->id);
        }

        if ($request->filled('date')) {
            $query->whereDate('date', $request->string('date'));
        }

        if ($request->filled('status')) {
            $query->where('status', $request->string('status'));
        }

        $logs = $query->latest()->paginate(20);
        $logs->getCollection()->transform(function ($log) {
            return $this->formatLog($log);
        });

        return $logs;
    }

    public function store(Request $request)
    {
        $request->validate([
            'vehicle_id' => 'required|exists:carpool_vehicles,id',
            'driver_id' => 'nullable|exists:carpool_drivers,id',
            'date' => 'required|date',
            'destination' => 'required|string',
            'start_time' => 'required|string',
            'end_time' => 'nullable|string',
            'last_km' => 'nullable|string',
            'status' => 'nullable|string',
            'user_name' => 'nullable|string',
        ]);

        $userName = $request->input('user_name');
        if (!is_string($userName) || trim($userName) === '') {
            $userName = $request->input('user');
        }
        if (!is_string($userName) || trim($userName) === '') {
            $userName = $request->user()->name;
        }

        $log = CarpoolLog::create([
            'user_id' => $request->user()->id,
            'user_name' => $userName,
            'vehicle_id' => $request->integer('vehicle_id'),
            'driver_id' => $request->input('driver_id'),
            'date' => $request->string('date'),
            'destination' => $request->string('destination'),
            'start_time' => $request->string('start_time'),
            'end_time' => $request->input('end_time'),
            'last_km' => $request->input('last_km'),
            'status' => $request->input('status', 'In Progress'),
        ]);

        $log->load(['vehicle', 'driver', 'user']);

        return response()->json([
            'message' => 'Log carpool tersimpan',
            'data' => $this->formatLog($log),
        ], 201);
    }

    public function update(Request $request, CarpoolLog $log)
    {
        $request->validate([
            'end_time' => 'nullable|string',
            'last_km' => 'nullable|string',
            'status' => 'nullable|string',
        ]);

        $log->update($request->only(['end_time', 'last_km', 'status']));
        $log->load(['vehicle', 'driver', 'user']);

        return response()->json([
            'message' => 'Log carpool diperbarui',
            'data' => $this->formatLog($log),
        ]);
    }

    private function formatLog(CarpoolLog $log): array
    {
        return [
            'id' => $log->id,
            'vehicle_id' => $log->vehicle_id,
            'driver_id' => $log->driver_id,
            'date' => $log->date,
            'destination' => $log->destination,
            'start_time' => $log->start_time,
            'end_time' => $log->end_time,
            'last_km' => $log->last_km,
            'status' => $log->status,
            'vehicle_display' => $log->vehicle ? $log->vehicle->brand . ' (' . $log->vehicle->plate . ')' : '-',
            'driver_display' => $log->driver ? $log->driver->name . ' (' . $log->driver->nip . ')' : '-',
            'user_name' => $log->user_name ?: ($log->user ? $log->user->name : '-'),
        ];
    }
}
