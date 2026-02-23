<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('km_audits', function (Blueprint $table) {
            $table->id();
            $table->foreignId('vehicle_id')->constrained('carpool_vehicles')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->date('date');
            $table->decimal('recorded_km', 10, 1);
            $table->decimal('actual_km', 10, 1);
            $table->decimal('difference', 10, 1)->default(0);
            $table->boolean('is_alert')->default(false);
            $table->text('notes')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('km_audits');
    }
};
