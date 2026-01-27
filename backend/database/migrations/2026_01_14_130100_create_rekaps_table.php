<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('rekaps', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->date('date');
            $table->string('start_time', 8);
            $table->string('end_time', 8);
            $table->text('activity');
            $table->string('guard');
            $table->string('shift');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('rekaps');
    }
};
