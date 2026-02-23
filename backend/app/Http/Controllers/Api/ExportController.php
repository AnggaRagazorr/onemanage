<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Controllers\Api\Traits\FiltersDateRange;
use App\Models\Patrol;
use App\Models\CarpoolLog;
use App\Models\Rekap;
use App\Models\DokumenMasuk;
use App\Models\KmAudit;
use Illuminate\Http\Request;
use Barryvdh\DomPDF\Facade\Pdf;

class ExportController extends Controller
{
    use FiltersDateRange;

    public function exportPatrols(Request $request)
    {
        $query = Patrol::with('user')->latest();

        $this->applyDateFilter($query, $request, 'captured_at');

        if ($request->filled('search')) {
            $search = $request->string('search');
            $query->where(function ($q) use ($search) {
                $q->where('area', 'like', "%{$search}%")
                    ->orWhere('barcode', 'like', "%{$search}%")
                    ->orWhereHas('user', fn($q) => $q->where('name', 'like', "%{$search}%"));
            });
        }

        $data = $query->get();

        $pdf = Pdf::loadView('pdf.patrol', [
            'data' => $data,
            'start_date' => $request->start_date,
            'end_date' => $request->end_date
        ])->setPaper('a4', 'landscape');

        return $pdf->download('laporan-patroli.pdf');
    }

    public function exportCarpool(Request $request)
    {
        $query = CarpoolLog::with(['vehicle', 'driver', 'user', 'keyValidator'])->latest();

        $this->applyDateFilter($query, $request, 'date');

        if ($request->filled('search')) {
            $search = $request->string('search');
            $query->where(function ($q) use ($search) {
                $q->where('user_name', 'like', "%{$search}%")
                    ->orWhere('destination', 'like', "%{$search}%")
                    ->orWhereHas('user', fn($q) => $q->where('name', 'like', "%{$search}%"))
                    ->orWhereHas('vehicle', fn($q) => $q->where('plate', 'like', "%{$search}%")->orWhere('brand', 'like', "%{$search}%"))
                    ->orWhereHas('driver', fn($q) => $q->where('name', 'like', "%{$search}%"));
            });
        }

        $data = $query->get();

        $pdf = Pdf::loadView('pdf.carpool', [
            'data' => $data
        ])->setPaper('a4', 'landscape');

        return $pdf->download('laporan-carpool.pdf');
    }

    public function exportRekap(Request $request)
    {
        $query = Rekap::latest();

        $this->applyDateFilter($query, $request, 'date');

        if ($request->filled('search')) {
            $search = $request->string('search');
            $query->where(function ($q) use ($search) {
                $q->where('guard', 'like', "%{$search}%")
                    ->orWhere('activity', 'like', "%{$search}%");
            });
        }

        $data = $query->get();

        $pdf = Pdf::loadView('pdf.rekap', [
            'data' => $data
        ])->setPaper('a4', 'portrait');

        return $pdf->download('laporan-rekap.pdf');
    }

    public function exportKmAudits(Request $request)
    {
        $query = KmAudit::with(['vehicle', 'user'])
            ->orderByDesc('date')
            ->orderByDesc('created_at');

        $this->applySingleDateFilter($query, $request, 'date');

        $data = $query->get();

        $pdf = Pdf::loadView('pdf.km-audits', [
            'data' => $data,
            'date' => $request->input('date'),
        ])->setPaper('a4', 'landscape');

        return $pdf->download('laporan-audit-km.pdf');
    }

    public function exportDokumen(Request $request)
    {
        $query = DokumenMasuk::query()->latest();

        $this->applySingleDateFilter($query, $request, 'date');

        if ($request->filled('search')) {
            $search = $request->string('search');
            $query->where(function ($q) use ($search) {
                $q->where('origin', 'like', "%{$search}%")
                    ->orWhere('item_name', 'like', "%{$search}%")
                    ->orWhere('owner', 'like', "%{$search}%")
                    ->orWhere('receiver', 'like', "%{$search}%");
            });
        }

        $data = $query->get();

        $pdf = Pdf::loadView('pdf.dokumen', [
            'data' => $data,
            'date' => $request->input('date'),
        ])->setPaper('a4', 'landscape');

        return $pdf->download('laporan-dokumen.pdf');
    }
}
