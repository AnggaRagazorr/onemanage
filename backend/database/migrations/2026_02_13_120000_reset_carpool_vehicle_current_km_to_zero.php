<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Reset all existing system KM to zero.
     */
    public function up(): void
    {
        DB::table('carpool_vehicles')->update([
            'current_km' => 0,
        ]);
    }

    /**
     * No rollback data for one-time reset.
     */
    public function down(): void
    {
        // Intentionally left blank.
    }
};

