<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DokumenMasuk;
use Illuminate\Http\Request;

class DokumenMasukController extends Controller
{
    public function index(Request $request)
    {
        $query = DokumenMasuk::query();

        if ($request->user()->role !== 'admin') {
            $query->where('user_id', $request->user()->id);
        }

        if ($request->filled('date')) {
            $query->whereDate('date', $request->string('date'));
        }

        if ($request->filled('search')) {
            $search = $request->string('search');
            $query->where(function ($q) use ($search) {
                $q->where('origin', 'like', "%{$search}%")
                    ->orWhere('item_name', 'like', "%{$search}%")
                    ->orWhere('owner', 'like', "%{$search}%")
                    ->orWhere('receiver', 'like', "%{$search}%");
            });
        }

        return $query->latest()->paginate(20);
    }

    public function store(Request $request)
    {
        $request->validate([
            'date' => 'required|date',
            'day' => 'required|string',
            'time' => 'required|string',
            'origin' => 'required|string',
            'item_name' => 'required|string',
            'qty' => 'required|string',
            'owner' => 'required|string',
            'receiver' => 'required|string',
        ]);

        $doc = DokumenMasuk::create([
            'user_id' => $request->user()->id,
            'date' => $request->string('date'),
            'day' => $request->string('day'),
            'time' => $request->string('time'),
            'origin' => $request->string('origin'),
            'item_name' => $request->string('item_name'),
            'qty' => $request->string('qty'),
            'owner' => $request->string('owner'),
            'receiver' => $request->string('receiver'),
        ]);

        return response()->json([
            'message' => 'Dokumen masuk tersimpan',
            'data' => $doc,
        ], 201);
    }
}
