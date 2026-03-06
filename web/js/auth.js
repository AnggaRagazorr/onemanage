/**
 * Auth Module
 */
App.Auth = {
    _sessionValidatedAt: 0,
    _sessionValidationPromise: null,
    _sessionValidationTtlMs: 15000,

    async login(username, password) {
        const data = await App.Api.post('/auth/login', {
            username,
            password,
            device_name: 'web',
        });
        const user = data.user || {};
        localStorage.setItem('user_id', user.id != null ? String(user.id) : '');
        localStorage.setItem('user_role', user.role || '');
        localStorage.setItem('user_name', user.name || 'User');
        localStorage.setItem('user_email', user.email || '');
        this._sessionValidatedAt = Date.now();
        return data;
    },

    async logout() {
        try { await App.Api.post('/auth/logout'); } catch (e) { }
        this.clearSession();
        if (location.hash !== '#/login') {
            location.hash = '#/login';
        }
    },

    clearSession() {
        if (App.Pages?.StaffDashboard?.stopPolling) {
            App.Pages.StaffDashboard.stopPolling();
        }
        if (App.Push?.stop) {
            App.Push.stop();
        }
        localStorage.removeItem('user_id');
        localStorage.removeItem('user_role');
        localStorage.removeItem('user_name');
        localStorage.removeItem('user_email');
        this._sessionValidatedAt = 0;
        this._sessionValidationPromise = null;
    },

    forceLogout() {
        this.clearSession();
        if (location.hash !== '#/login') {
            location.hash = '#/login';
        }
    },

    async validateSession(options = {}) {
        if (!this.isLoggedIn()) return false;
        const { force = false } = options;
        const now = Date.now();
        if (!force && this._sessionValidatedAt > 0 && (now - this._sessionValidatedAt) < this._sessionValidationTtlMs) {
            return true;
        }

        if (this._sessionValidationPromise) {
            return this._sessionValidationPromise;
        }

        this._sessionValidationPromise = (async () => {
            try {
                await App.Api.get('/auth/me', {}, { timeoutMs: 8000 });
                this._sessionValidatedAt = Date.now();
                return true;
            } catch (e) {
                return false;
            } finally {
                this._sessionValidationPromise = null;
            }
        })();

        return this._sessionValidationPromise;
    },

    isLoggedIn() {
        return !!localStorage.getItem('user_role');
    },

    getRole() { return localStorage.getItem('user_role') || ''; },
    getId() { return localStorage.getItem('user_id') || ''; },
    getName() { return localStorage.getItem('user_name') || 'User'; },
    getEmail() { return localStorage.getItem('user_email') || ''; },
    isAdmin() { return this.getRole() === 'admin'; },
};
