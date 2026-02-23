<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('carpool_logs', function (Blueprint $table) {
            $table->foreignId('approved_by')->nullable()->constrained('users')->nullOnDelete()->after('status');
            $table->timestamp('approved_at')->nullable()->after('approved_by');
            $table->timestamp('trip_started_at')->nullable()->after('approved_at');
            $table->timestamp('trip_finished_at')->nullable()->after('trip_started_at');
            $table->foreignId('key_validated_by')->nullable()->constrained('users')->nullOnDelete()->after('trip_finished_at');
            $table->timestamp('key_returned_at')->nullable()->after('key_validated_by');
        });

        // Update existing logs to 'completed' status
        \Illuminate\Support\Facades\DB::table('carpool_logs')
            ->where('status', 'In Progress')
            ->update(['status' => 'completed']);
        \Illuminate\Support\Facades\DB::table('carpool_logs')
            ->where('status', 'Done')
            ->update(['status' => 'completed']);
    }

    public function down(): void
    {
        Schema::table('carpool_logs', function (Blueprint $table) {
            $table->dropForeign(['approved_by']);
            $table->dropForeign(['key_validated_by']);
            $table->dropColumn([
                'approved_by',
                'approved_at',
                'trip_started_at',
                'trip_finished_at',
                'key_validated_by',
                'key_returned_at',
            ]);
        });
    }
};
