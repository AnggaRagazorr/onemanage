<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Patrol;
use App\Models\Rekap;
use App\Models\DokumenMasuk;
use App\Models\CarpoolVehicle;

class DashboardController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();
        $today = now()->toDateString();
        $startOfDay = now()->startOfDay();
        $endOfDay = now()->endOfDay();

        // 1. Patroli Hari Ini
        $patrolCount = Patrol::whereDate('captured_at', $today)
            ->where('user_id', $user->id)
            ->count();
        // Assume daily target is 3 for now, or fetch from config
        $patrolTarget = 3;

        // 2. Rekap Kejadian Hari Ini
        $rekapQuery = Rekap::whereBetween('created_at', [$startOfDay, $endOfDay]);
        if ($user->role !== 'admin') {
            $rekapQuery->where('user_id', $user->id);
        }
        $rekapCount = $rekapQuery->count();

        // 3. Carpool Stats (Available / Total)
        // Use current vehicle status instead of legacy end_time-based log count.
        $totalVehicles = CarpoolVehicle::count();
        $availableVehicles = CarpoolVehicle::where('status', 'available')->count();

        // 4. Barang/Dokumen Masuk Hari Ini
        $dokumenCount = DokumenMasuk::whereDate('created_at', $today)->count();

        return response()->json([
            'patrol_today' => $patrolCount,
            'patrol_target' => $patrolTarget,

            'rekap_today' => $rekapCount,

            'carpool_available' => $availableVehicles,
            'carpool_total' => $totalVehicles,

            'dokumen_today' => $dokumenCount,

            // Keep legacy field if needed
            'last_activity' => Patrol::where('user_id', $user->id)->latest()->first(),
        ]);
    }
}
