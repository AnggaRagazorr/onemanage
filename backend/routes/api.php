<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\RekapController;
use App\Http\Controllers\Api\DokumenMasukController;
use App\Http\Controllers\Api\CarpoolVehicleController;
use App\Http\Controllers\Api\CarpoolDriverController;
use App\Http\Controllers\Api\CarpoolLogController;
use App\Http\Controllers\Api\PatrolController;
use App\Http\Controllers\Api\PatrolConditionReportController;
use App\Http\Controllers\Api\AdminUserController;

Route::post('/auth/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/auth/me', [AuthController::class, 'me']);
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::get('/dashboard', [\App\Http\Controllers\Api\DashboardController::class, 'index']);

    Route::get('/rekaps', [RekapController::class, 'index']);
    Route::post('/rekaps', [RekapController::class, 'store']);

    Route::get('/dokumen', [DokumenMasukController::class, 'index']);
    Route::post('/dokumen', [DokumenMasukController::class, 'store']);

    Route::get('/carpool/vehicles', [CarpoolVehicleController::class, 'index']);
    Route::post('/carpool/vehicles', [CarpoolVehicleController::class, 'store']);
    Route::delete('/carpool/vehicles/{vehicle}', [CarpoolVehicleController::class, 'destroy']);
    Route::get('/carpool/drivers', [CarpoolDriverController::class, 'index']);
    Route::post('/carpool/drivers', [CarpoolDriverController::class, 'store']);
    Route::delete('/carpool/drivers/{driver}', [CarpoolDriverController::class, 'destroy']);
    Route::get('/carpool/logs', [CarpoolLogController::class, 'index']);
    Route::post('/carpool/logs', [CarpoolLogController::class, 'store']);
    Route::post('/carpool/logs/{log}', [CarpoolLogController::class, 'update']);

    Route::get('/patrols', [PatrolController::class, 'index']);
    Route::post('/patrols', [PatrolController::class, 'store']);
    Route::get('/patrol-conditions', [PatrolConditionReportController::class, 'index']);
    Route::post('/patrol-conditions', [PatrolConditionReportController::class, 'store']);

    Route::get('/admin/users', [AdminUserController::class, 'index']);
    Route::post('/admin/users', [AdminUserController::class, 'store']);
    Route::post('/admin/users/{user}', [AdminUserController::class, 'update']);
    Route::post('/admin/users/{user}/delete', [AdminUserController::class, 'destroy']);

    Route::get('/admin/security-stats', [\App\Http\Controllers\Api\SecurityStatsController::class, 'index']);
    Route::get('/admin/security-stats/{user}', [\App\Http\Controllers\Api\SecurityStatsController::class, 'show']);

    Route::get('/shifts/current', [\App\Http\Controllers\Api\ShiftController::class, 'current']);
    Route::post('/shifts/clock-in', [\App\Http\Controllers\Api\ShiftController::class, 'clockIn']);
    Route::post('/shifts/clock-out', [\App\Http\Controllers\Api\ShiftController::class, 'clockOut']);
});
