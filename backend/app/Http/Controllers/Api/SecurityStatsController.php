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
        $now = Carbon::now();
        $startOfMonth = $now->copy()->startOfMonth();
        $today = $now->toDateString();

        $securities = User::where('role', 'security')
            ->select('id', 'name', 'username', 'email')
            ->get();

        $securityIds = $securities->pluck('id');

        // Batch: patrol counts this month per user
        $patrolCountsMonth = Patrol::whereIn('user_id', $securityIds)
            ->where('captured_at', '>=', $startOfMonth)
            ->selectRaw('user_id, COUNT(*) as count')
            ->groupBy('user_id')
            ->pluck('count', 'user_id');

        // Batch: patrol counts today per user
        $patrolCountsToday = Patrol::whereIn('user_id', $securityIds)
            ->whereDate('captured_at', $today)
            ->selectRaw('user_id, COUNT(*) as count')
            ->groupBy('user_id')
            ->pluck('count', 'user_id');

        // Batch: last patrol per user
        $lastPatrols = Patrol::whereIn('user_id', $securityIds)
            ->selectRaw('user_id, MAX(captured_at) as last_captured')
            ->groupBy('user_id')
            ->pluck('last_captured', 'user_id');

        // Batch: active shifts
        $activeShiftUserIds = SecurityShift::whereIn('user_id', $securityIds)
            ->whereNull('clock_out')
            ->pluck('user_id')
            ->flip();

        // Batch: patrol counts per day per user (for score calculation)
        $patrolsPerDayAll = Patrol::whereIn('user_id', $securityIds)
            ->where('captured_at', '>=', $startOfMonth)
            ->selectRaw('user_id, DATE(captured_at) as date, COUNT(*) as count')
            ->groupBy('user_id', 'date')
            ->get()
            ->groupBy('user_id');

        $stats = $securities->map(function ($user) use ($patrolCountsMonth, $patrolCountsToday, $lastPatrols, $activeShiftUserIds, $patrolsPerDayAll) {
            $patrolsPerDay = ($patrolsPerDayAll[$user->id] ?? collect())->pluck('count', 'date')->toArray();
            $score = $this->calculateMonthlyScoreFromData($patrolsPerDay);

            return [
                'id' => $user->id,
                'name' => $user->name,
                'username' => $user->username,
                'patrol_count_today' => $patrolCountsToday[$user->id] ?? 0,
                'patrol_count_month' => $patrolCountsMonth[$user->id] ?? 0,
                'is_working' => $activeShiftUserIds->has($user->id),
                'last_activity' => $lastPatrols[$user->id] ?? null,
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
     * Calculate monthly score for a security (single-user query).
     * Used by show() method.
     */
    private function calculateMonthlyScore(int $userId, Carbon $startOfMonth, Carbon $now): array
    {
        $patrolsPerDay = Patrol::where('user_id', $userId)
            ->where('captured_at', '>=', $startOfMonth)
            ->selectRaw('DATE(captured_at) as date, COUNT(*) as count')
            ->groupBy('date')
            ->pluck('count', 'date')
            ->toArray();

        return $this->calculateMonthlyScoreFromData($patrolsPerDay);
    }

    /**
     * Calculate monthly score from pre-fetched patrol-per-day data.
     * Used by both index() (batch) and calculateMonthlyScore() (single).
     *
     * Scoring:
     * - 1 point per patrol (max 12 per day)
     * - 3 bonus points if daily target (12 patrols) is reached
     * - Max 15 points per shift
     */
    private function calculateMonthlyScoreFromData(array $patrolsPerDay): array
    {
        $bonusPoints = 0;
        $patrolPoints = 0;
        $shiftsWithBonus = 0;

        foreach ($patrolsPerDay as $date => $count) {
            $dailyPatrolPoints = min($count, 12);
            $patrolPoints += $dailyPatrolPoints;

            if ($count >= 12) {
                $bonusPoints += 3;
                $shiftsWithBonus++;
            }
        }

        $totalPoints = $patrolPoints + $bonusPoints;
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
