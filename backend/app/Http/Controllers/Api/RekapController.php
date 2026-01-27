<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Rekap;
use Illuminate\Http\Request;

class RekapController extends Controller
{
    public function index(Request $request)
    {
        $query = Rekap::query();

        if ($request->user()->role !== 'admin') {
            $query->where('user_id', $request->user()->id);
        }

        if ($request->filled('date')) {
            $query->whereDate('date', $request->string('date'));
        }

        return $query->latest()->paginate(20);
    }

    public function store(Request $request)
    {
        $request->validate([
            'date' => 'required|date',
            'start_time' => 'required|string',
            'end_time' => 'required|string',
            'activity' => 'required|string',
            'guard' => 'required|string',
            'shift' => 'required|string',
        ]);

        $rekap = Rekap::create([
            'user_id' => $request->user()->id,
            'date' => $request->string('date'),
            'start_time' => $request->string('start_time'),
            'end_time' => $request->string('end_time'),
            'activity' => $request->string('activity'),
            'guard' => $request->string('guard'),
            'shift' => $request->string('shift'),
        ]);

        // Send Push Notification to Admin
        \App\Services\FCMService::sendToTopic(
            'admin_rekap_updates',
            'Laporan Rekap Baru',
            'User ' . $request->user()->name . ' baru saja mengirim laporan rekap harian.',
            ['rekap_id' => $rekap->id]
        );

        return response()->json([
            'message' => 'Rekap tersimpan',
            'data' => $rekap,
        ], 201);
    }
}
