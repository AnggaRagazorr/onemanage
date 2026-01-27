<?php

namespace App\Services;

use Google\Auth\Credentials\ServiceAccountCredentials;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FCMService
{
    /**
     * Send a notification to a specific topic using FCM HTTP v1 API.
     *
     * @param string $topic
     * @param string $title
     * @param string $body
     * @param array $data
     * @return void
     */
    public static function sendToTopic($topic, $title, $body, $data = [])
    {
        $credentialsPath = storage_path('app/firebase_credentials.json');

        if (!file_exists($credentialsPath)) {
            Log::error('FCM Service Account file not found at: ' . $credentialsPath);
            return;
        }

        // Determine Project ID from the JSON file content or hardcode it if known
        // Better to read it from the file to avoid mismatches
        $jsonContent = json_decode(file_get_contents($credentialsPath), true);
        $projectId = $jsonContent['project_id'] ?? 'sekuriti';

        try {
            // 1. Get OAuth 2.0 Token
            $scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
            $sa = new ServiceAccountCredentials($scopes, $credentialsPath);
            $token = $sa->fetchAuthToken();

            if (empty($token['access_token'])) {
                Log::error('FCM: Failed to fetch access token.');
                return;
            }

            $accessToken = $token['access_token'];

            // 2. Prepare URL and Payload
            $url = "https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send";

            // Ensure all data values are strings (Requirement of FCM v1 'data' field)
            $stringData = array_map(function ($value) {
                return (string) $value;
            }, $data);

            $payload = [
                'message' => [
                    'topic' => $topic,
                    'notification' => [
                        'title' => $title,
                        'body' => $body,
                    ],
                    'data' => $stringData,
                ],
            ];

            // 3. Send Request
            $response = Http::withToken($accessToken)
                ->withHeaders(['Content-Type' => 'application/json'])
                ->post($url, $payload);

            if ($response->failed()) {
                Log::error('FCM v1 Send Failed: ' . $response->body());
            } else {
                Log::info('FCM v1 Send Success: ' . $response->body());
            }

        } catch (\Exception $e) {
            Log::error('FCM v1 Exception: ' . $e->getMessage());
        }
    }
}
