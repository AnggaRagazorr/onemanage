<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SecurityShift;
use Illuminate\Http\Request;

class ShiftController extends Controller
{
    /**
     * Get current active shift for the user
     */
    public function current(Request $request)
    {
        $user = $request->user();

        if ($user->role !== 'security') {
            return response()->json(['message' => 'Only security can access shifts'], 403);
        }

        $activeShift = SecurityShift::where('user_id', $user->id)
            ->whereNull('clock_out')
            ->latest('clock_in')
            ->first();

        if (!$activeShift) {
            return response()->json([
                'is_active' => false,
                'shift' => null,
            ]);
        }

        return response()->json([
            'is_active' => true,
            'shift' => [
                'id' => $activeShift->id,
                'shift_type' => $activeShift->shift_type,
                'clock_in' => $activeShift->clock_in,
            ],
        ]);
    }

    /**
     * Clock in - start a new shift
     */
    public function clockIn(Request $request)
    {
        $user = $request->user();

        if ($user->role !== 'security') {
            return response()->json(['message' => 'Only security can clock in'], 403);
        }

        $request->validate([
            'shift_type' => 'required|in:pagi,malam',
        ]);

        // Check if already has active shift
        $activeShift = SecurityShift::where('user_id', $user->id)
            ->whereNull('clock_out')
            ->first();

        if ($activeShift) {
            return response()->json([
                'message' => 'Anda masih memiliki shift aktif. Selesaikan shift terlebih dahulu.',
            ], 400);
        }

        $shift = SecurityShift::create([
            'user_id' => $user->id,
            'shift_type' => $request->shift_type,
            'clock_in' => now(),
        ]);

        return response()->json([
            'message' => 'Shift berhasil dimulai',
            'shift' => [
                'id' => $shift->id,
                'shift_type' => $shift->shift_type,
                'clock_in' => $shift->clock_in,
            ],
        ]);
    }

    /**
     * Clock out - end current shift
     */
    public function clockOut(Request $request)
    {
        $user = $request->user();

        if ($user->role !== 'security') {
            return response()->json(['message' => 'Only security can clock out'], 403);
        }

        $activeShift = SecurityShift::where('user_id', $user->id)
            ->whereNull('clock_out')
            ->first();

        if (!$activeShift) {
            return response()->json([
                'message' => 'Tidak ada shift aktif untuk diselesaikan.',
            ], 400);
        }

        $activeShift->update([
            'clock_out' => now(),
        ]);

        return response()->json([
            'message' => 'Shift berhasil diselesaikan',
            'shift' => [
                'id' => $activeShift->id,
                'shift_type' => $activeShift->shift_type,
                'clock_in' => $activeShift->clock_in,
                'clock_out' => $activeShift->clock_out,
            ],
        ]);
    }
}
