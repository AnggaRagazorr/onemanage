<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CarpoolLog;
use App\Models\CarpoolVehicle;
use App\Services\CarpoolNotificationService;
use Illuminate\Http\Request;

class CarpoolLogController extends Controller
{
    public function __construct(private CarpoolNotificationService $carpoolNotifier)
    {
    }

    /**
     * List carpool logs — filtered by role.
     * Admin sees all, others see only their own or assigned trips.
     */
    public function index(Request $request)
    {
        $query = CarpoolLog::with(['vehicle', 'driver', 'user', 'approver', 'keyValidator']);
        $user = $request->user();

        if (in_array($user->role, ['admin', 'security'])) {
            // Admin & Security see all
        } elseif ($user->role === 'driver') {
            $query->where(function ($q) use ($user) {
                $q->where('driver_id', function ($sub) use ($user) {
                    $sub->select('id')
                        ->from('carpool_drivers')
                        ->where('user_id', $user->id);
                })->orWhere('user_id', $user->id);
            });
        } else {
            // security & staff see only their own requests
            $query->where('user_id', $user->id);
        }

        if ($request->filled('start_date')) {
            $query->whereDate('date', '>=', $request->string('start_date'));
        }
        if ($request->filled('end_date')) {
            $query->whereDate('date', '<=', $request->string('end_date'));
        }

        if ($request->filled('status')) {
            $query->where('status', $request->string('status'));
        }

        if ($request->filled('search')) {
            $search = $request->string('search');
            $query->where(function ($q) use ($search) {
                $q->where('user_name', 'like', "%{$search}%")
                    ->orWhere('destination', 'like', "%{$search}%")
                    ->orWhere('passenger_names', 'like', "%{$search}%")
                    ->orWhereHas('user', fn($q) => $q->where('name', 'like', "%{$search}%"))
                    ->orWhereHas('vehicle', fn($q) => $q->where('plate', 'like', "%{$search}%")->orWhere('brand', 'like', "%{$search}%"))
                    ->orWhereHas('driver', fn($q) => $q->where('name', 'like', "%{$search}%"));
            });
        }

        $logs = $query->latest()->paginate(20);
        $logs->getCollection()->transform(function ($log) {
            return $this->formatLog($log);
        });

        return $logs;
    }

    /**
     * Step 1: Create a trip request.
     * Staff creates as 'requested', Admin creates as 'approved'.
     */
    public function store(Request $request)
    {
        $user = $request->user();
        $isAdmin = $user->role === 'admin';

        $request->validate([
            'vehicle_id' => $isAdmin ? 'required|exists:carpool_vehicles,id' : 'nullable|exists:carpool_vehicles,id',
            'driver_id' => $isAdmin ? 'required|exists:carpool_drivers,id' : 'nullable|exists:carpool_drivers,id',
            'date' => 'required|date',
            'destination' => 'required|string',
            'start_time' => $isAdmin ? 'nullable|string' : 'required|string',
            'end_time' => 'nullable|string',
            'last_km' => 'nullable|string',
            'user_name' => 'nullable|string',
            'passenger_names' => 'nullable|string',
        ]);

        $userName = $request->input('user_name');
        if (!is_string($userName) || trim($userName) === '') {
            $userName = $user->name;
        }

        $passengerNames = trim((string) $request->input('passenger_names', ''));
        if (!$isAdmin && $passengerNames === '') {
            return response()->json([
                'message' => 'Data penumpang wajib diisi',
            ], 422);
        }

        $vehicle = null;
        if ($isAdmin) {
            $vehicle = $this->ensureVehicleAvailable($request->integer('vehicle_id'));
            $this->ensureDriverAvailable($request->integer('driver_id'));
        }

        $log = CarpoolLog::create([
            'user_id' => $user->id,
            'user_name' => $userName,
            'passenger_names' => $passengerNames ?: null,
            'vehicle_id' => $isAdmin ? $vehicle->id : null,
            'driver_id' => $isAdmin ? $request->input('driver_id') : null,
            'date' => $request->string('date'),
            'destination' => $request->string('destination'),
            'start_time' => $request->input('start_time'),
            'end_time' => $request->input('end_time'),
            'last_km' => $request->input('last_km'),
            'status' => $isAdmin ? 'approved' : 'requested',
            'approved_by' => $isAdmin ? $user->id : null,
            'approved_at' => $isAdmin ? now() : null,
        ]);

        $log->load(['vehicle', 'driver', 'user', 'approver']);

        if ($isAdmin) {
            // Mark vehicle as in_use immediately on approval
            if ($vehicle) {
                $vehicle->markInUse();
            }
            $this->carpoolNotifier->onApproved($log);
        } else {
            $this->carpoolNotifier->onRequested($log);
        }

        return response()->json([
            'message' => $isAdmin ? 'Trip dibuat dan disetujui, menunggu driver konfirmasi' : 'Request trip berhasil dikirim, menunggu persetujuan admin',
            'data' => $this->formatLog($log),
        ], 201);
    }

    /**
     * Step 2: Admin approves a requested trip.
     */
    public function approve(Request $request, CarpoolLog $log)
    {
        $user = $request->user();

        if ($user->role !== 'admin') {
            return response()->json(['message' => 'Hanya admin yang bisa approve trip'], 403);
        }

        $request->validate([
            'vehicle_id' => 'required|exists:carpool_vehicles,id',
            'driver_id' => 'required|exists:carpool_drivers,id',
        ]);

        if ($log->status !== 'requested') {
            return response()->json(['message' => 'Trip tidak dalam status requested (status: ' . $log->status . ')'], 422);
        }

        $vehicle = $this->ensureVehicleAvailable($request->integer('vehicle_id'), $log->id);
        $this->ensureDriverAvailable($request->integer('driver_id'), $log->id);

        $log->update([
            'vehicle_id' => $vehicle->id,
            'driver_id' => $request->integer('driver_id'),
            'status' => 'approved',
            'approved_by' => $user->id,
            'approved_at' => now(),
        ]);

        // Mark vehicle as in_use immediately on approval
        $vehicle->markInUse();

        $log->load(['vehicle', 'driver', 'user', 'approver']);
        $this->carpoolNotifier->onApproved($log);

        return response()->json([
            'message' => 'Trip disetujui, menunggu konfirmasi driver',
            'data' => $this->formatLog($log),
        ]);
    }

    /**
     * Step 3: Driver confirms or rejects the trip.
     */
    public function driverConfirm(Request $request, CarpoolLog $log)
    {
        $request->validate([
            'response' => 'required|in:accept,reject',
            'reject_reason' => 'required_if:response,reject|nullable|string|min:10',
        ]);

        if ($request->user()->role !== 'driver') {
            return response()->json(['message' => 'Hanya driver yang bisa konfirmasi trip'], 403);
        }

        if ($log->status !== 'approved') {
            return response()->json(['message' => 'Trip tidak dalam status menunggu konfirmasi (status: ' . $log->status . ')'], 422);
        }

        if ($request->input('response') === 'reject') {
            // Release vehicle back to available
            $vehicle = $log->vehicle;
            if ($vehicle) {
                $vehicle->markAvailable();
            }

            // Reset to requested, admin will assign vehicle and driver again
            $rejectReason = $request->input('reject_reason', '');
            $log->update([
                'status' => 'requested',
                'reject_reason' => $rejectReason,
                'vehicle_id' => null,
                'driver_id' => null,
                'approved_by' => null,
                'approved_at' => null,
            ]);
            $log->load(['vehicle', 'driver', 'user']);
            $this->carpoolNotifier->onDriverRejected($log, $rejectReason);
            return response()->json(['message' => 'Trip ditolak. Dikembalikan ke Admin.']);
        }

        // Accept
        $log->update(['status' => 'confirmed']);
        $log->load(['vehicle', 'driver', 'user']);
        $this->carpoolNotifier->onDriverAccepted($log);

        return response()->json([
            'message' => 'Trip diterima. Menunggu Security mencatat keluar.',
            'data' => $this->formatLog($log),
        ]);
    }

    /**
     * Step 4: Security starts the trip (Mobil Keluar) → vehicle becomes IN_USE.
     */
    public function tripStart(Request $request, CarpoolLog $log)
    {
        // Now Security performs this
        if ($request->user()->role !== 'security' && $request->user()->role !== 'admin') {
            return response()->json(['message' => 'Hanya Security yang mencatat mobil keluar'], 403);
        }

        if ($log->status !== 'confirmed') {
            return response()->json(['message' => 'Trip belum dikonfirmasi driver (status: ' . $log->status . ')'], 422);
        }

        $vehicle = $log->vehicle;
        if (!$vehicle) {
            return response()->json(['message' => 'Kendaraan tidak ditemukan'], 422);
        }

        // Vehicle is already in_use since approval, no need to markInUse again

        $log->update([
            'status' => 'in_use',
            'trip_started_at' => now(),
        ]);

        $log->load(['vehicle', 'driver', 'user']);
        $this->carpoolNotifier->onTripStarted($log);

        return response()->json([
            'message' => 'Mobil keluar. Status IN USE.',
            'data' => $this->formatLog($log),
        ]);
    }

    /**
     * Step 5: Driver finishes trip → vehicle becomes PENDING_KEY.
     */
    public function tripFinish(Request $request, CarpoolLog $log)
    {
        $request->validate([
            'end_time' => 'nullable|string',
            'last_km' => 'nullable|numeric|min:0',
        ]);

        if ($log->status !== 'in_use') {
            return response()->json(['message' => 'Trip belum dimulai (status: ' . $log->status . ')'], 422);
        }

        $vehicle = $log->vehicle;
        if ($vehicle) {
            $vehicle->markPendingKey();

            // Auto-accumulate System KM based on driver trip KM input
            if ($request->filled('last_km')) {
                $lastKm = (float) $request->input('last_km');
                $newSystemKm = (float) $vehicle->current_km + $lastKm;
                $vehicle->update(['current_km' => $newSystemKm]);
            }
        }

        $log->update([
            'status' => 'pending_key',
            'trip_finished_at' => now(),
            'end_time' => $request->input('end_time', now()->format('H:i')),
            'last_km' => $request->input('last_km', $log->last_km),
        ]);

        $log->load(['vehicle', 'driver', 'user']);
        $this->carpoolNotifier->onTripFinished($log);

        return response()->json([
            'message' => 'Trip selesai. Menunggu validasi kunci oleh Security.',
            'data' => $this->formatLog($log),
        ]);
    }

    /**
     * Step 6: Security validates key return → vehicle becomes AVAILABLE.
     */
    public function validateKey(Request $request, CarpoolLog $log)
    {
        $user = $request->user();

        if (!in_array($user->role, ['admin', 'security'])) {
            return response()->json(['message' => 'Hanya security/admin yang bisa validasi kunci'], 403);
        }

        if ($log->status !== 'pending_key') {
            return response()->json(['message' => 'Trip belum dalam status pending key (status: ' . $log->status . ')'], 422);
        }

        $vehicle = $log->vehicle;
        if ($vehicle) {
            $vehicle->markAvailable();
        }

        $log->update([
            'status' => 'completed',
            'key_validated_by' => $user->id,
            'key_returned_at' => now(),
        ]);

        $log->load(['vehicle', 'driver', 'user', 'keyValidator', 'approver']);
        $this->carpoolNotifier->onKeyValidated($log);

        return response()->json([
            'message' => 'Kunci sudah divalidasi. Kendaraan kembali AVAILABLE.',
            'data' => $this->formatLog($log),
        ]);
    }

    /**
     * Admin cancels/rejects a trip request.
     */
    public function cancel(Request $request, CarpoolLog $log)
    {
        $user = $request->user();

        if ($user->role !== 'admin') {
            return response()->json(['message' => 'Hanya admin yang bisa membatalkan trip'], 403);
        }

        if (in_array($log->status, ['completed', 'cancelled'])) {
            return response()->json(['message' => 'Trip sudah selesai atau dibatalkan'], 422);
        }

        // If vehicle was already assigned, release it
        $vehicle = $log->vehicle;
        if ($vehicle && in_array($log->status, ['approved', 'confirmed', 'in_use', 'pending_key'])) {
            $vehicle->markAvailable();
        }

        $log->update([
            'status' => 'cancelled',
        ]);

        return response()->json([
            'message' => 'Trip dibatalkan',
            'data' => $this->formatLog($log->fresh(['vehicle', 'driver', 'user', 'approver', 'keyValidator'])),
        ]);
    }

    private function formatLog(CarpoolLog $log): array
    {
        return [
            'id' => $log->id,
            'vehicle_id' => $log->vehicle_id,
            'driver_id' => $log->driver_id,
            'date' => $log->date,
            'destination' => $log->destination,
            'passenger_names' => $log->passenger_names,
            'start_time' => $log->start_time,
            'end_time' => $log->end_time,
            'last_km' => $log->last_km,
            'status' => $log->status,
            'approved_by' => $log->approved_by,
            'approved_at' => $log->approved_at,
            'trip_started_at' => $log->trip_started_at,
            'trip_finished_at' => $log->trip_finished_at,
            'key_validated_by' => $log->key_validated_by,
            'key_returned_at' => $log->key_returned_at,
            'reject_reason' => $log->reject_reason,
            'vehicle_display' => $log->vehicle ? $log->vehicle->brand . ' (' . $log->vehicle->plate . ')' : '-',
            'vehicle_status' => $log->vehicle ? $log->vehicle->status : null,
            'driver_display' => $log->driver ? $log->driver->name . ' (' . $log->driver->nip . ')' : '-',
            'user_name' => $log->user_name ?: ($log->user ? $log->user->name : '-'),
            'approver_name' => $log->approver ? $log->approver->name : null,
            'validator_name' => $log->keyValidator ? $log->keyValidator->name : null,
        ];
    }

    /**
     * Validate that a vehicle is available and not reserved by another active trip.
     *
     * @throws \Illuminate\Http\Exceptions\HttpResponseException
     */
    private function ensureVehicleAvailable(int $vehicleId, ?int $excludeLogId = null): CarpoolVehicle
    {
        $vehicle = CarpoolVehicle::findOrFail($vehicleId);

        if (!$vehicle->isAvailable()) {
            abort(response()->json([
                'message' => 'Kendaraan sedang digunakan (status: ' . $vehicle->status . ')',
            ], 422));
        }

        $reservedQuery = CarpoolLog::query()
            ->where('vehicle_id', $vehicle->id)
            ->whereIn('status', ['approved', 'confirmed', 'in_use', 'pending_key']);

        if ($excludeLogId) {
            $reservedQuery->where('id', '!=', $excludeLogId);
        }

        if ($reservedQuery->exists()) {
            abort(response()->json([
                'message' => 'Kendaraan sudah dipakai di trip aktif lain',
            ], 422));
        }

        return $vehicle;
    }

    /**
     * Validate that a driver is not assigned to another active trip.
     *
     * @throws \Illuminate\Http\Exceptions\HttpResponseException
     */
    private function ensureDriverAvailable(int $driverId, ?int $excludeLogId = null): void
    {
        $reservedQuery = CarpoolLog::query()
            ->where('driver_id', $driverId)
            ->whereIn('status', ['approved', 'confirmed', 'in_use', 'pending_key']);

        if ($excludeLogId) {
            $reservedQuery->where('id', '!=', $excludeLogId);
        }

        if ($reservedQuery->exists()) {
            abort(response()->json([
                'message' => 'Driver sedang bertugas di trip aktif lain',
            ], 422));
        }
    }
}
