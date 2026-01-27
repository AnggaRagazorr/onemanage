<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('carpool_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('vehicle_id')->constrained('carpool_vehicles')->cascadeOnDelete();
            $table->foreignId('driver_id')->nullable()->constrained('carpool_drivers')->nullOnDelete();
            $table->date('date');
            $table->string('destination');
            $table->string('start_time', 8);
            $table->string('end_time', 8)->nullable();
            $table->string('last_km', 20)->nullable();
            $table->string('status')->default('In Progress');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('carpool_logs');
    }
};
