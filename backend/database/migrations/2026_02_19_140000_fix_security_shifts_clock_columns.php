<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
    public function up(): void
    {
        // Fix MySQL implicit ON UPDATE on first TIMESTAMP column.
        DB::statement("ALTER TABLE security_shifts MODIFY clock_in DATETIME NOT NULL");
        DB::statement("ALTER TABLE security_shifts MODIFY clock_out DATETIME NULL DEFAULT NULL");

        // Repair corrupted rows where clock_in was overwritten during clock_out update.
        DB::statement(<<<'SQL'
            UPDATE security_shifts
            SET clock_in = created_at
            WHERE clock_out IS NOT NULL
              AND created_at IS NOT NULL
              AND clock_out <= clock_in
              AND created_at <= clock_in
        SQL);
    }

    public function down(): void
    {
        // Revert type only (do not rollback repaired historical data).
        DB::statement("ALTER TABLE security_shifts MODIFY clock_in TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP");
        DB::statement("ALTER TABLE security_shifts MODIFY clock_out TIMESTAMP NULL DEFAULT NULL");
    }
};
