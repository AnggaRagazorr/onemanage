/**
 * Auth Module
 */
App.Auth = {
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
        return data;
    },

    async logout() {
        try { await App.Api.post('/auth/logout'); } catch (e) { }
        this.clearSession();
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
    },

    forceLogout() {
        this.clearSession();
        location.hash = '#/login';
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
