<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class ForceCors
{
    private function isLocalOrPrivateHost(?string $host): bool
    {
        $hostname = strtolower(trim((string) $host));
        if ($hostname === '') {
            return false;
        }

        if (in_array($hostname, ['localhost', '127.0.0.1', '::1'], true)) {
            return true;
        }

        if (!filter_var($hostname, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4)) {
            return false;
        }

        $parts = array_map('intval', explode('.', $hostname));
        if (count($parts) !== 4) {
            return false;
        }

        if ($parts[0] === 10 || $parts[0] === 127) {
            return true;
        }

        if ($parts[0] === 192 && $parts[1] === 168) {
            return true;
        }

        if ($parts[0] === 172 && $parts[1] >= 16 && $parts[1] <= 31) {
            return true;
        }

        return false;
    }

    private function resolveAllowedOrigin(Request $request): ?string
    {
        $origin = $request->headers->get('Origin');
        if (!$origin) {
            return null;
        }

        $origins = array_filter(array_map('trim', explode(',', (string) env(
            'CORS_ALLOWED_ORIGINS',
            'http://localhost:3000,http://127.0.0.1:3000,http://localhost:5500,http://127.0.0.1:5500,http://localhost:8000,http://127.0.0.1:8000'
        ))));

        if (in_array('*', $origins, true)) {
            return $origin;
        }

        if (in_array($origin, $origins, true)) {
            return $origin;
        }

        $originHost = parse_url($origin, PHP_URL_HOST);
        if (!app()->environment('production') && $this->isLocalOrPrivateHost($originHost)) {
            return $origin;
        }

        return null;
    }

    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $allowedOrigin = $this->resolveAllowedOrigin($request);

        // Handle Preflight OPTIONS request immediately
        if ($request->isMethod('OPTIONS')) {
            $response = response('', 200);
        } else {
            $response = $next($request);
        }

        // Add CORS headers to every response
        if ($allowedOrigin) {
            $response->headers->set('Access-Control-Allow-Origin', $allowedOrigin);
            $response->headers->set('Vary', 'Origin');
        }
        $response->headers->set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
        $response->headers->set('Access-Control-Allow-Headers', 'X-Requested-With, Content-Type, X-Token-Auth, Authorization, Accept');
        $response->headers->set('Access-Control-Allow-Credentials', 'true');

        return $response;
    }
}
