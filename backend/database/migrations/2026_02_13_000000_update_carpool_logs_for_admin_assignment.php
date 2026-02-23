<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('carpool_logs', function (Blueprint $table) {
            if (!Schema::hasColumn('carpool_logs', 'passenger_names')) {
                $table->text('passenger_names')->nullable()->after('user_name');
            }
        });

        $driver = DB::getDriverName();
        if (in_array($driver, ['mysql', 'mariadb'], true)) {
            try {
                DB::statement('ALTER TABLE carpool_logs DROP FOREIGN KEY carpool_logs_vehicle_id_foreign');
            } catch (\Throwable $e) {
            }

            DB::statement('ALTER TABLE carpool_logs MODIFY vehicle_id BIGINT UNSIGNED NULL');
            DB::statement('ALTER TABLE carpool_logs ADD CONSTRAINT carpool_logs_vehicle_id_foreign FOREIGN KEY (vehicle_id) REFERENCES carpool_vehicles(id) ON DELETE SET NULL');
        } elseif ($driver === 'pgsql') {
            DB::statement('ALTER TABLE carpool_logs DROP CONSTRAINT IF EXISTS carpool_logs_vehicle_id_foreign');
            DB::statement('ALTER TABLE carpool_logs ALTER COLUMN vehicle_id DROP NOT NULL');
            DB::statement('ALTER TABLE carpool_logs ADD CONSTRAINT carpool_logs_vehicle_id_foreign FOREIGN KEY (vehicle_id) REFERENCES carpool_vehicles(id) ON DELETE SET NULL');
        }
    }

    public function down(): void
    {
        Schema::table('carpool_logs', function (Blueprint $table) {
            if (Schema::hasColumn('carpool_logs', 'passenger_names')) {
                $table->dropColumn('passenger_names');
            }
        });

        $driver = DB::getDriverName();
        if (in_array($driver, ['mysql', 'mariadb'], true)) {
            try {
                DB::statement('ALTER TABLE carpool_logs DROP FOREIGN KEY carpool_logs_vehicle_id_foreign');
            } catch (\Throwable $e) {
            }

            DB::statement('ALTER TABLE carpool_logs ADD CONSTRAINT carpool_logs_vehicle_id_foreign FOREIGN KEY (vehicle_id) REFERENCES carpool_vehicles(id) ON DELETE CASCADE');
        } elseif ($driver === 'pgsql') {
            DB::statement('ALTER TABLE carpool_logs DROP CONSTRAINT IF EXISTS carpool_logs_vehicle_id_foreign');
            DB::statement('ALTER TABLE carpool_logs ADD CONSTRAINT carpool_logs_vehicle_id_foreign FOREIGN KEY (vehicle_id) REFERENCES carpool_vehicles(id) ON DELETE CASCADE');
        }
    }
};

