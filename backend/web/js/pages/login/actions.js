App.Pages = App.Pages || {};
App.Pages.Login = {
    render() {
        const app = document.getElementById('app');
        app.innerHTML = `
            <div class="login-page">
                <div class="login-container">
                    <div class="login-logo-wrapper">
                        <div class="login-logo-box">
                            <div class="login-logo-inner">
                                <img src="assets/image/pgncomgede.png" alt="PGNCom">
                            </div>
                        </div>
                    </div>
                    <div class="login-card">
                        <h2 class="login-title">One Manage</h2>
                        <p class="login-subtitle">Silakan login untuk melanjutkan</p>
                        <form id="login-form">
                            <div class="form-group">
                                <div class="form-input-icon">
                                    <span class="material-icons-round">person</span>
                                    <input type="text" class="form-input" id="login-username" placeholder="Username" required autocomplete="username">
                                </div>
                            </div>
                            <div class="form-group">
                                <div class="form-input-icon">
                                    <span class="material-icons-round">lock</span>
                                    <input type="password" class="form-input has-trailing-icon" id="login-password" placeholder="Password" required autocomplete="current-password">
                                    <button type="button" class="password-toggle" onclick="App.Pages.Login.togglePassword()">
                                        <span class="material-icons-round" id="password-eye">visibility</span>
                                    </button>
                                </div>
                            </div>
                            <button type="submit" class="btn btn-primary login-btn" id="login-btn">
                                LOGIN
                            </button>
                        </form>
                    </div>
                    <div class="login-footer"> © 2026 Computer Engineering Pens.</div>
                </div>
            </div>
        `;
    },

    bindForm() {
        document.getElementById('login-form')?.addEventListener('submit', async (e) => {
            e.preventDefault();
            const btn = document.getElementById('login-btn');
            const username = document.getElementById('login-username')?.value?.trim();
            const password = document.getElementById('login-password')?.value?.trim();

            if (!username || !password || !btn) return;

            btn.disabled = true;
            btn.innerHTML = '<div class="spinner" style="margin:auto"></div>';
            try {
                const result = await App.Auth.login(username, password);
                const role = result.user?.role || 'security';
                const dashMap = {
                    admin: '#/admin/dashboard',
                    security: '#/dashboard',
                    driver: '#/driver/dashboard',
                    staff: '#/staff/dashboard'
                };
                location.hash = dashMap[role] || '#/dashboard';
            } catch (err) {
                const msg = (err?.message || '').trim();
                App.toast(msg || 'Login gagal. Periksa username dan password.', 'error');
            } finally {
                btn.disabled = false;
                btn.innerHTML = 'LOGIN';
            }
        });
    },

    togglePassword() {
        const input = document.getElementById('login-password');
        const eye = document.getElementById('password-eye');
        if (!input || !eye) return;

        if (input.type === 'password') {
            input.type = 'text';
            eye.textContent = 'visibility_off';
        } else {
            input.type = 'password';
            eye.textContent = 'visibility';
        }
    }
};
