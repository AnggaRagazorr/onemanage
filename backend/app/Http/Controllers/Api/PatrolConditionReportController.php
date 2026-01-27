<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PatrolConditionReport;
use Illuminate\Http\Request;

class PatrolConditionReportController extends Controller
{
    public function index(Request $request)
    {
        $query = PatrolConditionReport::query()->with('user:id,name');

        if ($request->user()->role !== 'admin') {
            $query->where('user_id', $request->user()->id);
        }

        if ($request->filled('date')) {
            $query->whereDate('date', $request->string('date'));
        }

        if ($request->filled('user_id') && $request->user()->role === 'admin') {
            $query->where('user_id', $request->integer('user_id'));
        }

        return $query->latest()->paginate(20);
    }

    public function store(Request $request)
    {
        $payload = $request->validate([
            'date' => 'required|date',
            'time' => 'required|string',
            'situasi' => 'required|string',
            'aght' => 'required|string',
            'cuaca' => 'required|string',
            'pdam' => 'nullable|string',
            'wfo' => 'nullable|integer|min:0',
            'tambahan' => 'nullable|integer|min:0',
        ]);

        $report = PatrolConditionReport::create([
            'user_id' => $request->user()->id,
            'date' => $payload['date'],
            'time' => $payload['time'],
            'situasi' => $payload['situasi'],
            'aght' => $payload['aght'],
            'cuaca' => $payload['cuaca'],
            'pdam' => $payload['pdam'] ?? null,
            'wfo' => $payload['wfo'] ?? 0,
            'tambahan' => $payload['tambahan'] ?? 0,
        ]);

        $report->load('user:id,name');

        return response()->json([
            'message' => 'Laporan kondisi tersimpan',
            'data' => $report,
        ], 201);
    }
}
