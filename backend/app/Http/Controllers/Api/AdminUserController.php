<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class AdminUserController extends Controller
{
    public function index(Request $request)
    {
        if ($request->user()->role !== 'admin') {
            return response()->json([
                'message' => 'Forbidden',
            ], 403);
        }

        return User::query()
            ->select('id', 'name', 'username', 'email', 'role')
            ->orderBy('name')
            ->get();
    }

    public function store(Request $request)
    {
        if ($request->user()->role !== 'admin') {
            return response()->json([
                'message' => 'Forbidden',
            ], 403);
        }

        $request->validate([
            'name' => 'required|string',
            'username' => 'required|string|unique:users,username',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string',
            'role' => 'nullable|in:admin,security',
        ]);

        $role = $request->input('role', 'security');

        $user = User::create([
            'name' => $request->string('name'),
            'username' => $request->string('username'),
            'email' => $request->string('email'),
            'password' => Hash::make($request->input('password')),
            'role' => $role,
        ]);

        return response()->json([
            'message' => 'User dibuat',
            'data' => [
                'id' => $user->id,
                'name' => $user->name,
                'username' => $user->username,
                'email' => $user->email,
                'role' => $user->role,
            ],
        ], 201);
    }

    public function update(Request $request, User $user)
    {
        if ($request->user()->role !== 'admin') {
            return response()->json([
                'message' => 'Forbidden',
            ], 403);
        }

        $request->validate([
            'name' => 'required|string',
            'username' => [
                'required',
                'string',
                Rule::unique('users', 'username')->ignore($user->id),
            ],
            'email' => [
                'required',
                'email',
                Rule::unique('users', 'email')->ignore($user->id),
            ],
            'password' => 'nullable|string',
            'role' => 'nullable|in:admin,security',
        ]);

        $user->name = $request->string('name');
        $user->username = $request->string('username');
        $user->email = $request->string('email');
        $user->role = $request->input('role', $user->role);
        if ($request->filled('password')) {
            $user->password = Hash::make($request->input('password'));
        }
        $user->save();

        return response()->json([
            'message' => 'User diperbarui',
            'data' => [
                'id' => $user->id,
                'name' => $user->name,
                'username' => $user->username,
                'email' => $user->email,
                'role' => $user->role,
            ],
        ]);
    }

    public function destroy(Request $request, User $user)
    {
        if ($request->user()->role !== 'admin') {
            return response()->json([
                'message' => 'Forbidden',
            ], 403);
        }

        $user->delete();

        return response()->json([
            'message' => 'User dihapus',
        ]);
    }
}
