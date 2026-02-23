<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Patrol;
use Illuminate\Support\Facades\Storage;

class PatrolController extends Controller
{
    public function index(Request $request)
    {
        $query = Patrol::query()->with('user:id,name');

        if ($request->user()->role !== 'admin') {
            $query->where('user_id', $request->user()->id);
        }

        if ($request->filled('start_date')) {
            $query->whereDate('captured_at', '>=', $request->string('start_date'));
        }
        if ($request->filled('end_date')) {
            $query->whereDate('captured_at', '<=', $request->string('end_date'));
        }

        if ($request->filled('user_id') && $request->user()->role === 'admin') {
            $query->where('user_id', $request->integer('user_id'));
        }

        if ($request->filled('search')) {
            $search = $request->string('search');
            $query->where(function ($q) use ($search) {
                $q->where('area', 'like', "%{$search}%")
                    ->orWhere('barcode', 'like', "%{$search}%")
                    ->orWhereHas('user', fn($q) => $q->where('name', 'like', "%{$search}%"));
            });
        }

        return $query->latest()->paginate(20);
    }

    public function store(Request $request)
    {
        $request->validate([
            'area' => 'required|string',
            'barcode' => 'required|string',
            'photos' => 'required|array|min:2|max:2',
            'photos.*' => 'image|max:10240',
        ]);

        // --- QR Token Validation (pipe-separated format) ---
        $barcode = $request->string('barcode')->toString();
        $parts = explode('|', $barcode);

        if (count($parts) === 3) {
            // Format: NamaArea|UnixTimestamp|HmacSignature
            [$qrArea, $qrTimestamp, $qrSignature] = $parts;
            $secret = config('app.qr_patrol_secret', '');

            if (empty($secret)) {
                return response()->json([
                    'message' => 'Konfigurasi QR belum di-set di server (QR_PATROL_SECRET).',
                ], 500);
            }

            // Re-compute HMAC and compare
            $expectedSignature = hash_hmac('sha256', "{$qrArea}|{$qrTimestamp}", $secret);
            if (!hash_equals($expectedSignature, $qrSignature)) {
                return response()->json([
                    'message' => 'QR tidak valid — signature tidak cocok.',
                ], 422);
            }

            // Check expiry (30 seconds tolerance)
            $now = time();
            $tokenTime = (int) $qrTimestamp;
            if (abs($now - $tokenTime) > 30) {
                return response()->json([
                    'message' => 'QR sudah expired. Scan ulang QR terbaru dari alat.',
                ], 422);
            }
        }
        // If not pipe-separated (manual input / legacy), skip token validation

        $paths = [];
        foreach ($request->file('photos', []) as $photo) {
            $paths[] = $photo->store('patrols', 'public');
        }

        $patrol = Patrol::create([
            'user_id' => $request->user()->id,
            'area' => $request->string('area'),
            'barcode' => $barcode,
            'photo_count' => count($paths),
            'photos' => $paths,
            'captured_at' => now(),
        ]);
        $patrol->load('user:id,name');

        return response()->json([
            'message' => 'Patroli tersimpan',
            'data' => $patrol,
        ], 201);
    }
}
