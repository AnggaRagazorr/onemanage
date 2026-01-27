<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Patrol;
use App\Models\SecurityShift;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\Request;

class SecurityStatsController extends Controller
{
    /**
     * Get list of all security personnel with their statistics
     */
    public function index(Request $request)
    {
        if ($request->user()->role !== 'admin') {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $securities = User::where('role', 'security')
            ->select('id', 'name', 'username', 'email')
            ->get();

        $now = Carbon::now();
        $startOfMonth = $now->copy()->startOfMonth();
        $twelveHoursAgo = $now->copy()->subHours(12);

        $stats = $securities->map(function ($user) use ($startOfMonth, $twelveHoursAgo, $now) {
            // Count patrols this month
            $patrolCountMonth = Patrol::where('user_id', $user->id)
                ->where('captured_at', '>=', $startOfMonth)
                ->count();

            // Count patrols today
            $patrolCountToday = Patrol::where('user_id', $user->id)
                ->whereDate('captured_at', $now->toDateString())
                ->count();

            // Last activity
            $lastPatrol = Patrol::where('user_id', $user->id)
                ->latest('captured_at')
                ->first();

            // Is working (has active shift)
            $activeShift = SecurityShift::where('user_id', $user->id)
                ->whereNull('clock_out')
                ->first();
            $isWorking = $activeShift !== null;

            // Calculate score for this month
            $score = $this->calculateMonthlyScore($user->id, $startOfMonth, $now);

            return [
                'id' => $user->id,
                'name' => $user->name,
                'username' => $user->username,
                'patrol_count_today' => $patrolCountToday,
                'patrol_count_month' => $patrolCountMonth,
                'is_working' => $isWorking,
                'last_activity' => $lastPatrol?->captured_at,
                'score' => $score['total'],
                'score_percentage' => $score['percentage'],
            ];
        });

        return response()->json([
            'data' => $stats,
            'month' => $now->format('F Y'),
        ]);
    }

    /**
     * Get detailed statistics for a specific security
     */
    public function show(Request $request, User $user)
    {
        if ($request->user()->role !== 'admin') {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        if ($user->role !== 'security') {
            return response()->json(['message' => 'User is not a security'], 404);
        }

        $now = Carbon::now();
        $startOfMonth = $now->copy()->startOfMonth();
        $startOfWeek = $now->copy()->startOfWeek();
        $twelveHoursAgo = $now->copy()->subHours(12);

        // Patrol counts
        $patrolCountToday = Patrol::where('user_id', $user->id)
            ->whereDate('captured_at', $now->toDateString())
            ->count();

        $patrolCountWeek = Patrol::where('user_id', $user->id)
            ->where('captured_at', '>=', $startOfWeek)
            ->count();

        $patrolCountMonth = Patrol::where('user_id', $user->id)
            ->where('captured_at', '>=', $startOfMonth)
            ->count();

        // Patrol by area today
        $patrolByAreaToday = Patrol::where('user_id', $user->id)
            ->whereDate('captured_at', $now->toDateString())
            ->selectRaw('area, COUNT(*) as count')
            ->groupBy('area')
            ->pluck('count', 'area')
            ->toArray();

        // Last activity
        $lastPatrol = Patrol::where('user_id', $user->id)
            ->latest('captured_at')
            ->first();

        $isWorking = SecurityShift::where('user_id', $user->id)
            ->whereNull('clock_out')
            ->exists();

        // Score calculation
        $score = $this->calculateMonthlyScore($user->id, $startOfMonth, $now);

        // Shift history (days worked this month)
        $shiftsWorked = Patrol::where('user_id', $user->id)
            ->where('captured_at', '>=', $startOfMonth)
            ->selectRaw('DATE(captured_at) as date')
            ->distinct()
            ->count();

        return response()->json([
            'id' => $user->id,
            'name' => $user->name,
            'username' => $user->username,
            'email' => $user->email,
            'patrol_count_today' => $patrolCountToday,
            'patrol_count_week' => $patrolCountWeek,
            'patrol_count_month' => $patrolCountMonth,
            'patrol_by_area_today' => $patrolByAreaToday,
            'is_working' => $isWorking,
            'last_activity' => $lastPatrol?->captured_at,
            'shifts_worked_month' => $shiftsWorked,
            'score' => $score['total'],
            'score_percentage' => $score['percentage'],
            'score_breakdown' => $score['breakdown'],
            'month' => $now->format('F Y'),
        ]);
    }

    /**
     * Calculate monthly score for a security
     * 
     * Scoring:
     * - 1 point per patrol
     * - 3 bonus points if daily target (12 patrols = 4x per 3 areas) is reached
     * - Max 15 points per shift
     */
    private function calculateMonthlyScore(int $userId, Carbon $startOfMonth, Carbon $now): array
    {
        // Get patrol counts per day this month
        $patrolsPerDay = Patrol::where('user_id', $userId)
            ->where('captured_at', '>=', $startOfMonth)
            ->selectRaw('DATE(captured_at) as date, COUNT(*) as count')
            ->groupBy('date')
            ->pluck('count', 'date')
            ->toArray();

        $totalPoints = 0;
        $bonusPoints = 0;
        $patrolPoints = 0;
        $shiftsWithBonus = 0;

        foreach ($patrolsPerDay as $date => $count) {
            // Points for patrols (max 12 counted for scoring per day)
            $dailyPatrolPoints = min($count, 12);
            $patrolPoints += $dailyPatrolPoints;

            // Bonus if target reached (12 patrols = 4 rounds x 3 areas)
            if ($count >= 12) {
                $bonusPoints += 3;
                $shiftsWithBonus++;
            }
        }

        $totalPoints = $patrolPoints + $bonusPoints;

        // Calculate percentage based on expected performance
        // Assuming ~20 working days per month, max 15 points per day = 300 max
        $daysWorked = count($patrolsPerDay);
        $maxPossible = $daysWorked * 15;
        $percentage = $maxPossible > 0 ? round(($totalPoints / $maxPossible) * 100) : 0;

        return [
            'total' => $totalPoints,
            'percentage' => min($percentage, 100),
            'breakdown' => [
                'patrol_points' => $patrolPoints,
                'bonus_points' => $bonusPoints,
                'shifts_with_bonus' => $shiftsWithBonus,
                'days_worked' => $daysWorked,
            ],
        ];
    }
}
