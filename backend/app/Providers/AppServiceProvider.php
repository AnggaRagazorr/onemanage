<?php

namespace App\Providers;

use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        RateLimiter::for('login', function (Request $request) {
            $username = strtolower((string) $request->input('username', ''));
            $tooManyAttempts = static fn() => response()->json([
                'message' => 'Terlalu banyak percobaan login. Coba lagi dalam 1 menit.',
            ], 429);

            return [
                Limit::perMinute(30)->by($request->ip())->response($tooManyAttempts),
                Limit::perMinute(10)->by(($username ?: 'unknown') . '|' . $request->ip())->response($tooManyAttempts),
            ];
        });
    }
}
