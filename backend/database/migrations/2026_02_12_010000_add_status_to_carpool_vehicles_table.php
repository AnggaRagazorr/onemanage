<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('carpool_vehicles', function (Blueprint $table) {
            $table->string('status')->default('available')->after('plate');
            // status: available, in_use, pending_key
        });
    }

    public function down(): void
    {
        Schema::table('carpool_vehicles', function (Blueprint $table) {
            $table->dropColumn('status');
        });
    }
};
