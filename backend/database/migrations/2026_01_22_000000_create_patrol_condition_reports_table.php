<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('patrol_condition_reports', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->date('date');
            $table->string('time');
            $table->text('situasi');
            $table->text('aght');
            $table->string('cuaca');
            $table->string('pdam')->nullable();
            $table->unsignedInteger('wfo')->default(0);
            $table->unsignedInteger('tambahan')->default(0);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('patrol_condition_reports');
    }
};
