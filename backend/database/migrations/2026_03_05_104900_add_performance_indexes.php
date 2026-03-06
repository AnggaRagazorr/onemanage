<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('patrols', function (Blueprint $table) {
            $table->index('user_id');
            $table->index('captured_at');
        });

        Schema::table('carpool_logs', function (Blueprint $table) {
            $table->index('status');
            $table->index('date');
            $table->index('user_id');
            $table->index('driver_id');
            $table->index('vehicle_id');
        });

        Schema::table('rekaps', function (Blueprint $table) {
            $table->index('user_id');
            $table->index('created_at');
        });

        Schema::table('patrol_condition_reports', function (Blueprint $table) {
            $table->index('user_id');
            $table->index('date');
        });
    }

    public function down(): void
    {
        Schema::table('patrols', function (Blueprint $table) {
            $table->dropIndex(['user_id']);
            $table->dropIndex(['captured_at']);
        });

        Schema::table('carpool_logs', function (Blueprint $table) {
            $table->dropIndex(['status']);
            $table->dropIndex(['date']);
            $table->dropIndex(['user_id']);
            $table->dropIndex(['driver_id']);
            $table->dropIndex(['vehicle_id']);
        });

        Schema::table('rekaps', function (Blueprint $table) {
            $table->dropIndex(['user_id']);
            $table->dropIndex(['created_at']);
        });

        Schema::table('patrol_condition_reports', function (Blueprint $table) {
            $table->dropIndex(['user_id']);
            $table->dropIndex(['date']);
        });
    }
};
