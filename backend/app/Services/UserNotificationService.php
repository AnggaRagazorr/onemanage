<?php

namespace App\Services;

use App\Models\User;
use App\Models\UserNotification;

class UserNotificationService
{
    /**
     * @param array<int> $userIds
     * @param array<string,mixed> $payload
     */
    public function notifyUserIds(array $userIds, array $payload): void
    {
        $targets = array_values(array_unique(array_filter(array_map('intval', $userIds))));
        if (count($targets) === 0) {
            return;
        }

        $eventKey = $payload['event_key'] ?? null;
        $data = [
            'type' => (string) ($payload['type'] ?? 'info'),
            'title' => (string) ($payload['title'] ?? 'Notifikasi'),
            'body' => $payload['body'] ?? null,
            'action_url' => $payload['action_url'] ?? null,
            'payload' => $payload['payload'] ?? null,
        ];

        foreach ($targets as $userId) {
            if (is_string($eventKey) && $eventKey !== '') {
                UserNotification::updateOrCreate(
                    ['user_id' => $userId, 'event_key' => $eventKey],
                    $data
                );
                continue;
            }

            UserNotification::create([
                'user_id' => $userId,
                ...$data,
            ]);
        }
    }

    /**
     * @param array<string,mixed> $payload
     */
    public function notifyRole(string $role, array $payload): void
    {
        $ids = User::query()->where('role', $role)->pluck('id')->all();
        $this->notifyUserIds($ids, $payload);
    }
}

