<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CarpoolDriver;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class CarpoolDriverController extends Controller
{
    public function index()
    {
        $busyDriverIds = \App\Models\CarpoolLog::whereIn('status', ['approved', 'confirmed', 'in_use', 'pending_key'])
            ->whereNotNull('driver_id')
            ->pluck('driver_id')
            ->unique()
            ->toArray();

        return CarpoolDriver::with('user:id,name,username')->orderBy('name')->get()->map(function ($driver) use ($busyDriverIds) {
            $driver->is_busy = in_array($driver->id, $busyDriverIds);
            return $driver;
        });
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string',
            'nip' => 'required|string|unique:carpool_drivers,nip',
            'user_id' => [
                'nullable',
                'integer',
                Rule::exists('users', 'id')->where(fn($q) => $q->where('role', 'driver')),
            ],
        ]);

        $linkedUserId = $request->integer('user_id');
        if (!$linkedUserId) {
            $name = (string) $request->string('name');
            $nip = (string) $request->string('nip');
            $linkedUserId = User::query()
                ->where('role', 'driver')
                ->where(function ($q) use ($name, $nip) {
                    $q->whereRaw('LOWER(name) = ?', [strtolower($name)])
                        ->orWhere('username', $nip);
                })
                ->value('id');
        }

        $driver = CarpoolDriver::create([
            'name' => $request->string('name'),
            'nip' => $request->string('nip'),
            'user_id' => $linkedUserId ?: null,
        ]);
        $driver->load('user:id,name,username');

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
