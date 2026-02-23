<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('carpool_vehicles', function (Blueprint $table) {
            $table->decimal('current_km', 10, 1)->default(0)->after('status');
        });
    }

    public function down(): void
    {
        Schema::table('carpool_vehicles', function (Blueprint $table) {
            $table->dropColumn('current_km');
        });
    }
};
