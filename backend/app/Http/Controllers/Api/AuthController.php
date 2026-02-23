<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Laravel\Sanctum\PersonalAccessToken;

class AuthController extends Controller
{
    private const COOKIE_NAME = 'om_auth_token';
    private const COOKIE_MINUTES = 10080; // 7 hari

    public function login(Request $request)
    {
        $request->validate([
            'username' => 'required|string',
            'password' => 'required',
            'device_name' => 'nullable|string',
        ]);

        if (!Auth::attempt($request->only('username', 'password'))) {
            return response()->json([
                'message' => 'Username atau password salah'
            ], 401);
        }

        $user = Auth::user();

        $tokenName = $request->input('device_name', 'mobile-token');
        $token = $user->createToken($tokenName)->plainTextToken;
        $isWebClient = $tokenName === 'web';

        $payload = [
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'username' => $user->username,
                'email' => $user->email,
                'role' => $user->role,
            ]
        ];

        if (!$isWebClient) {
            $payload['token'] = $token;
        }

        return response()->json($payload)->cookie(
            self::COOKIE_NAME,
            $token,
            self::COOKIE_MINUTES,
            '/',
            null,
            $request->isSecure(),
            true,
            false,
            'lax'
        );
    }

    public function me(Request $request)
    {
        return response()->json([
            'user' => $request->user(),
        ]);
    }

    public function logout(Request $request)
    {
        $token = $request->bearerToken() ?: $request->cookie(self::COOKIE_NAME);

        if (is_string($token) && str_contains($token, '|')) {
            [$id] = explode('|', $token, 2);
            if (is_numeric($id)) {
                PersonalAccessToken::whereKey((int) $id)->delete();
            }
        }

        return response()->json([
            'message' => 'Logout berhasil'
        ])->withoutCookie(self::COOKIE_NAME);
    }
}
