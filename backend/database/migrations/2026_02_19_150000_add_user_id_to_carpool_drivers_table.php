<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('carpool_drivers', function (Blueprint $table) {
            $table->foreignId('user_id')->nullable()->after('nip')->constrained()->nullOnDelete();
            $table->index('user_id');
        });

        // Auto-link existing drivers by exact name (case-insensitive) or NIP -> username.
        DB::statement("
            UPDATE carpool_drivers cd
            JOIN users u
              ON u.role = 'driver'
             AND (LOWER(u.name) = LOWER(cd.name) OR u.username = cd.nip)
            SET cd.user_id = u.id
            WHERE cd.user_id IS NULL
        ");
    }

    public function down(): void
    {
        Schema::table('carpool_drivers', function (Blueprint $table) {
            $table->dropConstrainedForeignId('user_id');
        });
    }
};

