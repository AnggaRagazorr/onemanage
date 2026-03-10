<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\RekapController;
use App\Http\Controllers\Api\DokumenMasukController;
use App\Http\Controllers\Api\CarpoolVehicleController;
use App\Http\Controllers\Api\CarpoolDriverController;
use App\Http\Controllers\Api\CarpoolLogController;
use App\Http\Controllers\Api\KmAuditController;
use App\Http\Controllers\Api\PatrolController;
use App\Http\Controllers\Api\PatrolConditionReportController;
use App\Http\Controllers\Api\AdminUserController;
use App\Http\Controllers\Api\ExportController;
use App\Http\Controllers\Api\UserNotificationController;
use App\Http\Controllers\Api\SecurityStatsController;
use App\Http\Controllers\Api\PatrolTokenController;

Route::post('/auth/login', [AuthController::class, 'login'])->middleware('throttle:login');

// Endpoint untuk alat ESP32 (diproteksi via X-Device-Key, bukan Sanctum)
Route::post('/patrol-tokens', [PatrolTokenController::class, 'store']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/auth/me', [AuthController::class, 'me']);
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::get('/dashboard', [\App\Http\Controllers\Api\DashboardController::class, 'index']);
    Route::get('/notifications', [UserNotificationController::class, 'index']);
    Route::post('/notifications/{notification}/read', [UserNotificationController::class, 'markRead']);

    Route::get('/rekaps', [RekapController::class, 'index']);
    Route::post('/rekaps', [RekapController::class, 'store']);

    Route::get('/dokumen', [DokumenMasukController::class, 'index']);
    Route::post('/dokumen', [DokumenMasukController::class, 'store']);

    // Carpool - vehicles & drivers (read endpoints)
    Route::get('/carpool/vehicles', [CarpoolVehicleController::class, 'index']);
    Route::get('/carpool/drivers', [CarpoolDriverController::class, 'index']);

    // Carpool - trip workflow
    Route::get('/carpool/logs', [CarpoolLogController::class, 'index']);
    Route::post('/carpool/logs', [CarpoolLogController::class, 'store']);
    Route::post('/carpool/logs/{log}/respond', [CarpoolLogController::class, 'driverConfirm']);
    Route::post('/carpool/logs/{log}/trip-start', [CarpoolLogController::class, 'tripStart']);
    Route::post('/carpool/logs/{log}/trip-finish', [CarpoolLogController::class, 'tripFinish']);
    Route::post('/carpool/logs/{log}/validate-key', [CarpoolLogController::class, 'validateKey']);

    // KM Audit
    Route::get('/km-audits', [KmAuditController::class, 'index']);
    Route::post('/km-audits', [KmAuditController::class, 'store']);
    Route::get('/km-audits/alerts', [KmAuditController::class, 'alerts']);

    // Patrols
    Route::get('/patrols', [PatrolController::class, 'index']);
    Route::post('/patrols', [PatrolController::class, 'store']);
    Route::get('/patrol-conditions', [PatrolConditionReportController::class, 'index']);
    Route::post('/patrol-conditions', [PatrolConditionReportController::class, 'store']);

    Route::get('/shifts/current', [\App\Http\Controllers\Api\ShiftController::class, 'current']);
    Route::post('/shifts/clock-in', [\App\Http\Controllers\Api\ShiftController::class, 'clockIn']);
    Route::post('/shifts/clock-out', [\App\Http\Controllers\Api\ShiftController::class, 'clockOut']);

    Route::middleware('role.admin')->group(function () {
        // Admin only - Carpool master data and approvals
        Route::post('/carpool/vehicles', [CarpoolVehicleController::class, 'store']);
        Route::put('/carpool/vehicles/{vehicle}', [CarpoolVehicleController::class, 'update']);
        Route::delete('/carpool/vehicles/{vehicle}', [CarpoolVehicleController::class, 'destroy']);
        Route::post('/carpool/drivers', [CarpoolDriverController::class, 'store']);
        Route::delete('/carpool/drivers/{driver}', [CarpoolDriverController::class, 'destroy']);
        Route::post('/carpool/logs/{log}/approve', [CarpoolLogController::class, 'approve']);
        Route::post('/carpool/logs/{log}/cancel', [CarpoolLogController::class, 'cancel']);

        // Admin - Active Shifts
        Route::get('/admin/shifts/active', [\App\Http\Controllers\Api\ShiftController::class, 'activeShifts']);
        Route::get('/admin/shifts/history', [\App\Http\Controllers\Api\ShiftController::class, 'history']);

        // Admin
        Route::get('/admin/users', [AdminUserController::class, 'index']);
        Route::post('/admin/users', [AdminUserController::class, 'store']);
        Route::put('/admin/users/{user}', [AdminUserController::class, 'update']);
        Route::delete('/admin/users/{user}', [AdminUserController::class, 'destroy']);

        Route::get('/admin/security-stats', [SecurityStatsController::class, 'index']);
        Route::get('/admin/security-stats/{user}', [SecurityStatsController::class, 'show']);

        // Export Routes
        Route::get('/export/patrols', [ExportController::class, 'exportPatrols']);
        Route::get('/export/carpool', [ExportController::class, 'exportCarpool']);
        Route::get('/export/rekap', [ExportController::class, 'exportRekap']);
        Route::get('/export/km-audits', [ExportController::class, 'exportKmAudits']);
        Route::get('/export/dokumen', [ExportController::class, 'exportDokumen']);
    });
});
