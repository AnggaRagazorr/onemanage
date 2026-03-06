<?php

namespace App\Services;

use App\Models\CarpoolDriver;
use App\Models\CarpoolLog;
use App\Models\User;

class CarpoolNotificationService
{
    public function __construct(private UserNotificationService $notifier)
    {
    }

    public function onRequested(CarpoolLog $log): void
    {
        $this->notifier->notifyRole('admin', [
            'event_key' => "carpool.log.{$log->id}.requested",
            'type' => 'warning',
            'title' => 'Request Carpool Baru',
            'body' => sprintf('%s meminta trip ke %s.', $this->requesterName($log), $log->destination ?: '-'),
            'action_url' => '/admin/carpool',
            'payload' => $this->payload($log),
        ]);
    }

    public function onApproved(CarpoolLog $log): void
    {
        $this->notifyDriver($log, [
            'event_key' => "carpool.log.{$log->id}.approved.driver",
            'type' => 'info',
            'title' => 'Tugas Trip Baru',
            'body' => sprintf('Trip ke %s menunggu persetujuan driver.', $log->destination ?: '-'),
            'action_url' => '/driver/dashboard',
            'payload' => $this->payload($log),
        ]);

        $this->notifier->notifyRole('security', [
            'event_key' => "carpool.log.{$log->id}.approved.security",
            'type' => 'info',
            'title' => 'Request Menunggu Driver',
            'body' => sprintf(
                'Trip %s (%s) sudah di-approve, menunggu driver accept.',
                $log->destination ?: '-',
                $log->vehicle?->plate ?: '-'
            ),
            'action_url' => '/carpool',
            'payload' => $this->payload($log),
        ]);
    }

    public function onDriverAccepted(CarpoolLog $log): void
    {
        $requesterId = (int) ($log->user_id ?? 0);
        if ($requesterId > 0) {
            $this->notifier->notifyUserIds([$requesterId], [
                'event_key' => "carpool.log.{$log->id}.driver.accepted.user",
                'type' => 'success',
                'title' => 'Request Disetujui',
                'body' => sprintf(
                    'Driver %s menerima trip ke %s. Silakan bersiap.',
                    $log->driver?->name ?: '-',
                    $log->destination ?: '-'
                ),
                'action_url' => $this->pathByRole($log->user?->role),
                'payload' => $this->payload($log),
            ]);
        }

        $this->notifier->notifyRole('security', [
            'event_key' => "carpool.log.{$log->id}.driver.accepted.security",
            'type' => 'warning',
            'title' => 'Driver Siap Berangkat',
            'body' => sprintf(
                'Driver %s siap ambil kunci untuk trip %s.',
                $log->driver?->name ?: '-',
                $log->destination ?: '-'
            ),
            'action_url' => '/carpool',
            'payload' => $this->payload($log),
        ]);
    }

    public function onDriverRejected(CarpoolLog $log, string $rejectReason = ''): void
    {
        $reasonText = $rejectReason ? " Alasan: \"{$rejectReason}\"" : '';

        $this->notifier->notifyRole('admin', [
            'event_key' => "carpool.log.{$log->id}.driver.rejected.admin",
            'type' => 'warning',
            'title' => 'Driver Menolak Tugas',
            'body' => sprintf('Trip ke %s dikembalikan ke antrian approval.%s', $log->destination ?: '-', $reasonText),
            'action_url' => '/admin/carpool',
            'payload' => array_merge($this->payload($log), ['reject_reason' => $rejectReason]),
        ]);

        $requesterId = (int) ($log->user_id ?? 0);
        if ($requesterId > 0) {
            $this->notifier->notifyUserIds([$requesterId], [
                'event_key' => "carpool.log.{$log->id}.driver.rejected.user",
                'type' => 'warning',
                'title' => 'Request Perlu Penjadwalan Ulang',
                'body' => sprintf('Driver menolak trip ke %s. Admin akan menjadwalkan ulang.%s', $log->destination ?: '-', $reasonText),
                'action_url' => $this->pathByRole($log->user?->role),
                'payload' => array_merge($this->payload($log), ['reject_reason' => $rejectReason]),
            ]);
        }
    }

    public function onTripStarted(CarpoolLog $log): void
    {
        $requesterId = (int) ($log->user_id ?? 0);
        if ($requesterId > 0) {
            $this->notifier->notifyUserIds([$requesterId], [
                'event_key' => "carpool.log.{$log->id}.trip.started.user",
                'type' => 'info',
                'title' => 'Trip Dimulai',
                'body' => sprintf('Kendaraan %s sudah keluar untuk tujuan %s.', $log->vehicle?->plate ?: '-', $log->destination ?: '-'),
                'action_url' => $this->pathByRole($log->user?->role),
                'payload' => $this->payload($log),
            ]);
        }

        $this->notifier->notifyUserIds($this->driverUserIds($log), [
            'event_key' => "carpool.log.{$log->id}.trip.started.driver",
            'type' => 'info',
            'title' => 'Trip Dimulai',
            'body' => sprintf('Kendaraan %s sudah keluar untuk tujuan %s.', $log->vehicle?->plate ?: '-', $log->destination ?: '-'),
            'action_url' => '/driver/dashboard',
            'payload' => $this->payload($log),
        ]);
    }

    public function onTripFinished(CarpoolLog $log): void
    {
        $this->notifier->notifyRole('security', [
            'event_key' => "carpool.log.{$log->id}.trip.finished.security",
            'type' => 'warning',
            'title' => 'Trip Selesai - Tunggu Kunci',
            'body' => sprintf('Trip %s selesai. Menunggu pengembalian kunci.', $log->destination ?: '-'),
            'action_url' => '/carpool',
            'payload' => $this->payload($log),
        ]);

        $this->notifier->notifyRole('admin', [
            'event_key' => "carpool.log.{$log->id}.trip.finished.admin",
            'type' => 'info',
            'title' => 'Trip Selesai',
            'body' => sprintf('Trip %s selesai dan menunggu validasi kunci security.', $log->destination ?: '-'),
            'action_url' => '/admin/carpool',
            'payload' => $this->payload($log),
        ]);
    }

    public function onKeyValidated(CarpoolLog $log): void
    {
        $requesterId = (int) ($log->user_id ?? 0);
        if ($requesterId > 0) {
            $this->notifier->notifyUserIds([$requesterId], [
                'event_key' => "carpool.log.{$log->id}.key.validated.user",
                'type' => 'success',
                'title' => 'Trip Ditutup Security',
                'body' => sprintf(
                    'Trip %s selesai penuh. Kunci kendaraan sudah diterima security.',
                    $log->destination ?: '-'
                ),
                'action_url' => $this->pathByRole($log->user?->role),
                'payload' => $this->payload($log),
            ]);
        }

        $this->notifier->notifyUserIds($this->driverUserIds($log), [
            'event_key' => "carpool.log.{$log->id}.key.validated.driver",
            'type' => 'success',
            'title' => 'Trip Ditutup Security',
            'body' => sprintf(
                'Trip %s selesai penuh. Kunci kendaraan sudah diterima security.',
                $log->destination ?: '-'
            ),
            'action_url' => '/driver/dashboard',
            'payload' => $this->payload($log),
        ]);

        $adminIds = User::query()->where('role', 'admin')->pluck('id')->all();
        $this->notifier->notifyUserIds($adminIds, [
            'event_key' => "carpool.log.{$log->id}.key.validated.admin",
            'type' => 'success',
            'title' => 'Trip Ditutup Security',
            'body' => sprintf(
                'Trip %s selesai penuh. Kunci kendaraan sudah diterima security.',
                $log->destination ?: '-'
            ),
            'action_url' => '/admin/carpool',
            'payload' => $this->payload($log),
        ]);
    }

    /**
     * @param array<string,mixed> $payload
     */
    private function notifyDriver(CarpoolLog $log, array $payload): void
    {
        $ids = $this->driverUserIds($log);
        if (count($ids) === 0) {
            return;
        }
        $this->notifier->notifyUserIds($ids, $payload);
    }

    /**
     * @return array<int>
     */
    private function driverUserIds(CarpoolLog $log): array
    {
        if (!$log->driver_id) {
            return [];
        }

        $driver = CarpoolDriver::query()->find($log->driver_id);
        if (!$driver) {
            return [];
        }

        if ($driver->user_id) {
            return [(int) $driver->user_id];
        }

        $query = User::query()->where('role', 'driver');
        $query->where(function ($q) use ($driver) {
            $q->whereRaw('LOWER(name) = ?', [strtolower((string) $driver->name)])
                ->orWhere('username', (string) $driver->nip);
        });

        return $query->pluck('id')->map(fn($v) => (int) $v)->all();
    }

    private function requesterName(CarpoolLog $log): string
    {
        return (string) ($log->user_name ?: $log->user?->name ?: 'User');
    }

    /**
     * @return array<string,mixed>
     */
    private function payload(CarpoolLog $log): array
    {
        return [
            'log_id' => (int) $log->id,
            'status' => (string) $log->status,
            'destination' => (string) ($log->destination ?: ''),
            'vehicle' => (string) ($log->vehicle?->plate ?: ''),
            'driver' => (string) ($log->driver?->name ?: ''),
            'date' => (string) ($log->date ?: ''),
            'start_time' => (string) ($log->start_time ?: ''),
        ];
    }

    private function pathByRole(?string $role): string
    {
        return match ($role) {
            'admin' => '/admin/carpool',
            'security' => '/carpool',
            'driver' => '/driver/dashboard',
            'staff' => '/staff/dashboard',
            default => '/dashboard',
        };
    }
}
