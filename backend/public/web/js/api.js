/**
 * API Client — Mirrors mobile ApiClient + ApiConfig
 */
const App = window.App || {};
window.App = App;

// Resolve API base:
// - Local/LAN host -> force backend port 8000
// - Public host (e.g. ngrok) -> same-origin /api
const apiHost = window.location.hostname || '127.0.0.1';
const defaultTimeoutMs = 60000;

const isPrivateOrLocalHost = (hostname) => {
    const host = String(hostname || '').trim().toLowerCase();
    if (!host) return false;
    if (host === 'localhost' || host === '127.0.0.1' || host === '::1') return true;

    const parts = host.split('.').map((p) => Number(p));
    if (parts.length !== 4 || parts.some((n) => Number.isNaN(n))) return false;
    if (parts[0] === 10) return true;
    if (parts[0] === 127) return true;
    if (parts[0] === 192 && parts[1] === 168) return true;
    if (parts[0] === 172 && parts[1] >= 16 && parts[1] <= 31) return true;
    return false;
};

const sameOriginApiBase = `${window.location.origin}/api`;
const localApiBase = `${window.location.protocol}//${apiHost}:8000/api`;
const defaultApiBase = isPrivateOrLocalHost(apiHost) ? localApiBase : sameOriginApiBase;

// Optional override for tunnel setups (e.g. ngrok):
// ?api_base=https%3A%2F%2Fxxxx.ngrok-free.app%2Fapi
const params = new URLSearchParams(window.location.search);
const apiBaseFromQuery = params.get('api_base');
const allowApiBaseOverride = isPrivateOrLocalHost(window.location.hostname);
if (apiBaseFromQuery && allowApiBaseOverride) {
    localStorage.setItem('api_base_override', apiBaseFromQuery.trim());
}

if (!allowApiBaseOverride) {
    localStorage.removeItem('api_base_override');
}

const apiBaseOverride = allowApiBaseOverride ? localStorage.getItem('api_base_override') : null;
App.API_BASE = apiBaseOverride || defaultApiBase;
App.API_TIMEOUT_MS = defaultTimeoutMs;

App.Api = {

    createAbortController() {
        return new AbortController();
    },

    _headers(extra = {}) {
        return { 'Accept': 'application/json', 'Content-Type': 'application/json', ...extra };
    },

    _buildUrl(path, query = {}) {
        const qs = new URLSearchParams(query).toString();
        return `${App.API_BASE}${path}${qs ? '?' + qs : ''}`;
    },

    _createSignal(timeoutMs = App.API_TIMEOUT_MS, externalSignal = null) {
        const controller = new AbortController();
        const state = { timedOut: false };
        const effectiveTimeout = Number(timeoutMs) > 0 ? Number(timeoutMs) : App.API_TIMEOUT_MS;

        const timeoutId = setTimeout(() => {
            state.timedOut = true;
            controller.abort();
        }, effectiveTimeout);

        const onAbort = () => controller.abort();
        if (externalSignal) {
            if (externalSignal.aborted) {
                clearTimeout(timeoutId);
                controller.abort();
            } else {
                externalSignal.addEventListener('abort', onAbort, { once: true });
            }
        }

        const cleanup = () => {
            clearTimeout(timeoutId);
            if (externalSignal) {
                externalSignal.removeEventListener('abort', onAbort);
            }
        };

        return { signal: controller.signal, state, cleanup };
    },

    async _fetch(url, fetchOptions = {}, options = {}) {
        const { timeoutMs = App.API_TIMEOUT_MS, signal = null } = options;
        const { signal: finalSignal, state, cleanup } = this._createSignal(timeoutMs, signal);

        try {
            return await fetch(url, {
                credentials: 'include',
                ...fetchOptions,
                signal: finalSignal,
            });
        } catch (err) {
            if (err && err.name === 'AbortError') {
                throw new Error(state.timedOut ? 'Request timeout' : 'Request dibatalkan');
            }
            throw err;
        } finally {
            cleanup();
        }
    },

    async _handleJsonResponse(res) {
        if (res.status === 401) { App.Auth.forceLogout(); throw new Error('Unauthorized'); }
        if (!res.ok) {
            const text = await res.text();
            let msg = text;
            try { const j = JSON.parse(text); msg = j.message || text; } catch (e) { }
            throw new Error(msg);
        }
        if (res.status === 204) return null;
        const text = await res.text();
        if (!text) return null;
        try {
            return JSON.parse(text);
        } catch (e) {
            return text;
        }
    },

    async get(path, query = {}, options = {}) {
        const url = this._buildUrl(path, query);
        const res = await this._fetch(url, { headers: this._headers() }, options);
        return this._handleJsonResponse(res);
    },

    async post(path, data = {}, options = {}) {
        const url = this._buildUrl(path);
        const res = await this._fetch(url, {
            method: 'POST',
            headers: this._headers(),
            body: JSON.stringify(data),
        }, options);
        return this._handleJsonResponse(res);
    },

    async put(path, data = {}, options = {}) {
        const url = this._buildUrl(path);
        const res = await this._fetch(url, {
            method: 'PUT',
            headers: this._headers(),
            body: JSON.stringify(data),
        }, options);
        return this._handleJsonResponse(res);
    },

    async delete(path, options = {}) {
        const url = this._buildUrl(path);
        const res = await this._fetch(url, {
            method: 'DELETE',
            headers: this._headers(),
        }, options);
        return this._handleJsonResponse(res);
    },

    async postMultipart(path, formData, options = {}) {
        const url = this._buildUrl(path);
        const res = await this._fetch(url, {
            method: 'POST',
            headers: { 'Accept': 'application/json' },
            body: formData,
        }, options);
        return this._handleJsonResponse(res);
    },

    async postFormData(path, formData, options = {}) {
        return this.postMultipart(path, formData, options);
    },

    async downloadFile(path, query = {}, fallbackFilename = 'download.pdf', options = {}) {
        const url = this._buildUrl(path, query);
        const res = await this._fetch(url, {
            method: 'GET',
            headers: { 'Accept': 'application/pdf' },
        }, options);
        if (res.status === 401) { App.Auth.forceLogout(); throw new Error('Unauthorized'); }
        if (!res.ok) {
            const text = await res.text();
            throw new Error(text || 'Gagal mengunduh file');
        }

        const blob = await res.blob();
        const disposition = res.headers.get('content-disposition') || '';
        const utf8Match = disposition.match(/filename\*=UTF-8''([^;]+)/i);
        const basicMatch = disposition.match(/filename="?([^";]+)"?/i);
        const filename = utf8Match
            ? decodeURIComponent(utf8Match[1])
            : (basicMatch ? basicMatch[1] : fallbackFilename);

        const objUrl = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = objUrl;
        a.download = filename || fallbackFilename;
        document.body.appendChild(a);
        a.click();
        a.remove();
        URL.revokeObjectURL(objUrl);
    },
};

App.escapeHtml = function (value) {
    const str = value == null ? '' : String(value);
    return str
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');
};

/* ── Toast helper ── */
App.toast = function (message, type = 'info') {
    const container = document.getElementById('toast-container');
    const el = document.createElement('div');
    el.className = `toast ${type}`;
    el.innerHTML = `<span class="material-icons-round">${type === 'success' ? 'check_circle' :
        type === 'error' ? 'error' :
            type === 'warning' ? 'warning' : 'info'
        }</span><span>${App.escapeHtml(message)}</span>`;
    container.appendChild(el);
    setTimeout(() => { el.classList.add('toast-exit'); setTimeout(() => el.remove(), 300); }, 3500);
};

/* ── Modal helpers ── */
App.openModal = function (html) {
    document.getElementById('modal-content').innerHTML = html;
    document.getElementById('modal-overlay').classList.remove('hidden');
};

App.closeModal = function () {
    if (typeof App.beforeCloseModal === 'function') {
        try { App.beforeCloseModal(); } catch (e) { }
    }
    App.beforeCloseModal = null;
    document.getElementById('modal-overlay').classList.add('hidden');
    document.getElementById('modal-content').innerHTML = '';
};

document.addEventListener('click', (e) => {
    if (e.target.id === 'modal-overlay') App.closeModal();
});

/* ── Date format helpers ── */
App.getTodayDate = function () {
    const now = new Date();
    const tzOffset = now.getTimezoneOffset() * 60000;
    return new Date(now.getTime() - tzOffset).toISOString().split('T')[0];
};

App.formatDate = function (d) {
    if (!d) return '-';
    const dt = new Date(d);
    return dt.toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' });
};

App.formatDateTime = function (d) {
    if (!d) return '-';
    const dt = new Date(d);
    return dt.toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' }) + ' ' +
        dt.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' });
};

App.formatTime = function (d) {
    if (!d) return '-';
    const dt = new Date(d);
    return dt.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' });
};
