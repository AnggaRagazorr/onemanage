<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\UserNotification;
use Illuminate\Http\Request;

class UserNotificationController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();
        $afterId = max(0, (int) $request->query('after_id', 0));
        $limit = max(1, min(100, (int) $request->query('limit', 20)));

        $query = UserNotification::query()
            ->where('user_id', $user->id);

        if ($afterId > 0) {
            $query->where('id', '>', $afterId)->orderBy('id');
        } else {
            $query->orderByDesc('id');
        }

        $rows = $query->limit($limit)->get();
        if ($afterId <= 0) {
            $rows = $rows->reverse()->values();
        }

        return response()->json([
            'data' => $rows->map(fn(UserNotification $n) => $this->transform($n))->values(),
            'meta' => [
                'last_id' => (int) ($rows->last()?->id ?? $afterId),
            ],
        ]);
    }

    public function markRead(Request $request, UserNotification $notification)
    {
        if ((int) $notification->user_id !== (int) $request->user()->id) {
            return response()->json(['message' => 'Notifikasi tidak ditemukan'], 404);
        }

        if (!$notification->read_at) {
            $notification->forceFill(['read_at' => now()])->save();
        }

        return response()->json([
            'message' => 'Notifikasi dibaca',
            'data' => $this->transform($notification),
        ]);
    }

    /**
     * @return array<string,mixed>
     */
    private function transform(UserNotification $n): array
    {
        return [
            'id' => (int) $n->id,
            'type' => (string) $n->type,
            'title' => (string) $n->title,
            'body' => $n->body,
            'action_url' => $n->action_url,
            'payload' => $n->payload ?: [],
            'is_read' => (bool) $n->read_at,
            'read_at' => $n->read_at,
            'created_at' => $n->created_at,
        ];
    }
}
