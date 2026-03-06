<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\PatrolToken;
use Illuminate\Support\Str;

class PatrolTokenController extends Controller
{
    public function store(Request $request)
    {
        // 1. Validasi Device Key
        $deviceKey = env('PATROL_DEVICE_KEY');
        if (empty($deviceKey) || $request->header('X-Device-Key') !== $deviceKey) {
            return response()->json(['message' => 'Unauthorized device'], 401);
        }

        // 2. Cek area valid
        $request->validate([
            'area' => 'required|string'
        ]);

        // 3. Generate token & expired time (5 menit)
        $area = $request->string('area')->toString();
        $randomStr = Str::random(32);
        // Format token: TOKEN:Area:RandomString
        $tokenStr = "TOKEN:{$area}:{$randomStr}";

        $token = PatrolToken::create([
            'token' => $tokenStr,
            'area' => $area,
            'expires_at' => now()->addMinutes(5),
            'used' => false,
        ]);

        return response()->json([
            'token' => $token->token,
            'area' => $token->area,
            'expires_at' => $token->expires_at,
        ]);
    }
}
