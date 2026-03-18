/**
 * SPA Router — Hash-based Navigation (4 Roles: admin, security, driver, staff)
 */
App.Router = {
    routes: {},
    _loadedScripts: new Set(),
    _loadingScripts: {},
    routeBundles: {
        '/login': [
            'js/pages/login/actions.js',
            'js/pages/login/route.js',
        ],
        '/dashboard': [
            'js/pages/dashboard/actions.js',
            'js/pages/dashboard/route.js',
        ],
        '/patrol': [
            'js/pages/patrol/shared.js',
            'js/pages/patrol/actions.js',
            'js/pages/patrol/route.js',
        ],
        '/rekap': [
            'js/pages/rekap/actions.js',
            'js/pages/rekap/route.js',
        ],
        '/carpool': [
            'js/pages/carpool/shared.js',
            'js/pages/carpool/actions.js',
            'js/pages/carpool/route.js',
        ],
        '/dokumen': [
            'js/pages/dokumen/actions.js',
            'js/pages/dokumen/route.js',
        ],
        '/admin/dashboard': [
            'js/pages/admin-dashboard/actions.js',
            'js/pages/admin-dashboard/route.js',
        ],
        '/admin/patrol': [
            'js/pages/admin-patrol/actions.js',
            'js/pages/admin-patrol/route.js',
        ],
        '/admin/carpool': [
            'js/pages/admin-carpool/shared.js',
            'js/pages/admin-carpool/actions.js',
            'js/pages/admin-carpool/route.js',
        ],
        '/admin/rekap': [
            'js/pages/admin-rekap/actions.js',
            'js/pages/admin-rekap/route.js',
        ],
        '/admin/dokumen': [
            'js/pages/admin-dokumen/actions.js',
            'js/pages/admin-dokumen/route.js',
        ],
        '/admin/users': [
            'js/pages/admin-users/actions.js',
            'js/pages/admin-users/route.js',
        ],
        '/admin/security-stats': [
            'js/pages/admin-security-stats/actions.js',
            'js/pages/admin-security-stats/route.js',
        ],
        '/driver/dashboard': [
            'js/pages/driver-dashboard/actions.js',
            'js/pages/driver-dashboard/route.js',
        ],
        '/staff/dashboard': [
            'js/pages/staff-dashboard/shared.js',
            'js/pages/staff-dashboard/actions.js',
            'js/pages/staff-dashboard/route.js',
        ],
        '/audit-km': [
            'js/pages/audit-km/shared.js',
            'js/pages/audit-km/actions.js',
            'js/pages/audit-km/route.js',
        ],
    },

    register(hash, renderFn, roles) {
        this.routes[hash] = { renderFn, roles: roles || null };
    },

    init() {
        window.addEventListener('hashchange', () => this._resolve());
        this._resolve();
    },

    _loadScript(path) {
        if (this._loadedScripts.has(path)) {
            return Promise.resolve();
        }
        if (this._loadingScripts[path]) {
            return this._loadingScripts[path];
        }

        this._loadingScripts[path] = new Promise((resolve, reject) => {
            const script = document.createElement('script');
            script.src = path;
            script.async = true;
            script.onload = () => {
                this._loadedScripts.add(path);
                delete this._loadingScripts[path];
                resolve();
            };
            script.onerror = () => {
                delete this._loadingScripts[path];
                reject(new Error(`Gagal memuat script: ${path}`));
            };
            document.body.appendChild(script);
        });

        return this._loadingScripts[path];
    },

    async _ensureRouteLoaded(path) {
        if (this.routes[path]) {
            return true;
        }

        const bundle = this.routeBundles[path];
        if (!bundle || !Array.isArray(bundle)) {
            return false;
        }

        for (const scriptPath of bundle) {
            await this._loadScript(scriptPath);
        }

        return !!this.routes[path];
    },

    _getDefaultDashboard(role) {
        const map = {
            admin: '/admin/dashboard',
            security: '/dashboard',
            driver: '/driver/dashboard',
            staff: '/staff/dashboard',
        };
        return map[role] || '/login';
    },

    async _resolve() {
        const hash = location.hash || '';
        const path = hash.replace('#', '') || '/login';

        // Auth guard
        if (path !== '/login' && !App.Auth.isLoggedIn()) {
            if (App.Push?.stop) App.Push.stop();
            location.hash = '#/login';
            return;
        }

        if (path !== '/login' && App.Auth.isLoggedIn()) {
            const sessionOk = await App.Auth.validateSession();
            if (!sessionOk) {
                if (App.Push?.stop) App.Push.stop();
                location.hash = '#/login';
                return;
            }
        }

        // Already logged in — skip login page
        if (path === '/login' && App.Auth.isLoggedIn()) {
            const sessionOk = await App.Auth.validateSession();
            if (!sessionOk) {
                if (App.Push?.stop) App.Push.stop();
                return;
            }
            const role = App.Auth.getRole();
            if (App.Push?.ensureStarted) App.Push.ensureStarted();
            location.hash = '#' + this._getDefaultDashboard(role);
            return;
        }

        if (path === '/login') {
            if (App.Push?.stop) App.Push.stop();
        } else if (App.Push?.ensureStarted) {
            App.Push.ensureStarted();
        }

        let route = this.routes[path];
        if (!route) {
            try {
                await this._ensureRouteLoaded(path);
            } catch (err) {
                const app = document.getElementById('app');
                if (app) {
                    app.innerHTML = `<div style="padding:24px"><h3>Gagal memuat halaman</h3><p>${App.escapeHtml(err.message)}</p></div>`;
                }
                return;
            }
            route = this.routes[path];
        }

        // Role guard — if route has specific roles, check
        if (route && route.roles) {
            const userRole = App.Auth.getRole();
            if (!route.roles.includes(userRole)) {
                location.hash = '#' + this._getDefaultDashboard(userRole);
                return;
            }
        }

        // Admin pages guard (extra safety)
        if (path.startsWith('/admin') && !App.Auth.isAdmin()) {
            const role = App.Auth.getRole();
            location.hash = '#' + this._getDefaultDashboard(role);
            return;
        }

        if (route) {
            route.renderFn();
        } else {
            // 404 — go to appropriate dashboard
            if (App.Auth.isLoggedIn()) {
                const role = App.Auth.getRole();
                location.hash = '#' + this._getDefaultDashboard(role);
            } else {
                location.hash = '#/login';
            }
        }
    },

    navigate(path) {
        const normalizedPath = String(path || '').replace(/^#/, '');
        const targetHash = '#' + normalizedPath;

        // If navigating to current route, hashchange will not fire.
        // Force resolve so latest data is rendered without manual refresh.
        if (location.hash === targetHash) {
            this._resolve();
            return;
        }

        location.hash = targetHash;
    },
};

/**
 * Layout Renderer — with nav menus for 4 roles
 */
App.renderLayout = function (pageTitle, subtitle, bodyHtml, navPage) {
    const role = App.Auth.getRole();
    const name = App.Auth.getName();
    const esc = App.escapeHtml || ((v) => String(v ?? ''));

    const securityNav = [
        { icon: 'dashboard', label: 'Dashboard', path: '/dashboard', key: 'dashboard' },
        { icon: 'qr_code_scanner', label: 'Patroli', path: '/patrol', key: 'patrol' },
        { icon: 'edit_note', label: 'Rekap Harian', path: '/rekap', key: 'rekap' },
        { icon: 'vpn_key', label: 'Carpool', path: '/carpool', key: 'carpool' },
        { icon: 'speed', label: 'Audit KM', path: '/audit-km', key: 'audit-km' },
        { icon: 'folder_shared', label: 'Dokumen Masuk', path: '/dokumen', key: 'dokumen' },
    ];

    const adminNav = [
        { icon: 'dashboard', label: 'Dashboard', path: '/admin/dashboard', key: 'admin-dashboard' },
        { icon: 'shield', label: 'Data Patroli', path: '/admin/patrol', key: 'admin-patrol' },
        { icon: 'directions_car', label: 'Carpool', path: '/admin/carpool', key: 'admin-carpool' },
        { icon: 'speed', label: 'Audit KM', path: '/audit-km', key: 'audit-km' },
        { icon: 'receipt_long', label: 'Rekap Harian', path: '/admin/rekap', key: 'admin-rekap' },
        { icon: 'folder_shared', label: 'Dokumen Masuk', path: '/admin/dokumen', key: 'admin-dokumen' },
        { icon: 'group', label: 'Manajemen User', path: '/admin/users', key: 'admin-users' },
        { icon: 'bar_chart', label: 'Statistik Security', path: '/admin/security-stats', key: 'admin-stats' },
    ];

    const driverNav = [
        { icon: 'dashboard', label: 'Dashboard', path: '/driver/dashboard', key: 'driver-dashboard' },
    ];

    const staffNav = [
        { icon: 'dashboard', label: 'Dashboard', path: '/staff/dashboard', key: 'staff-dashboard' },
    ];

    const navMap = { admin: adminNav, security: securityNav, driver: driverNav, staff: staffNav };
    const navItems = navMap[role] || securityNav;

    const roleLabels = { admin: 'Administrator', security: 'Security', driver: 'Driver', staff: 'Staff' };
    const safeName = esc(name);
    const safeRole = esc(roleLabels[role] || role);
    const safePageTitle = esc(pageTitle);
    const safeSubtitle = esc(subtitle);

    document.getElementById('app').innerHTML = `
        <div class="sidebar-overlay" id="sidebar-overlay" onclick="App.toggleSidebar()"></div>
        <div class="app-layout">
            <aside class="sidebar" id="sidebar">
                <div class="sidebar-header">
                    <div class="sidebar-brand">
                        <div class="sidebar-logo">
                            <img src="assets/image/logo_pgncom.png" alt="PGNCom">
                        </div>
                        <div class="sidebar-brand-text">
                            <div class="sidebar-brand-title">One Manage</div>
                            <div class="sidebar-brand-sub">Operations Panel</div>
                        </div>
                    </div>
                    <div class="sidebar-user">
                        <div class="sidebar-avatar">
                            <span class="material-icons-round">person</span>
                        </div>
                        <div class="sidebar-user-info">
                            <div class="sidebar-user-name">${safeName}</div>
                            <div class="sidebar-user-role">${safeRole}</div>
                        </div>
                    </div>
                </div>
                <nav class="sidebar-nav">
                    <div class="nav-section-title">Navigasi</div>
                    ${navItems.map(item => `
                        <button class="nav-item ${navPage === item.key ? 'active' : ''}" onclick="App.Router.navigate('${item.path}'); App.closeSidebar();">
                            <span class="material-icons-round">${item.icon}</span>
                            ${item.label}
                        </button>
                    `).join('')}
                </nav>
                <div class="sidebar-footer">
                    <button class="btn-logout" onclick="App.Auth.logout();">
                        <span class="material-icons-round">logout</span>
                        Keluar
                    </button>
                </div>
            </aside>
            <main class="main-content">
                <header class="page-header">
                    <div>
                        <button class="hamburger-btn" onclick="App.toggleSidebar()">
                            <span class="material-icons-round">menu</span>
                        </button>
                        <h1>${safePageTitle}</h1>
                        <div class="page-header-sub">${safeSubtitle}</div>
                    </div>
                </header>
                <section class="page-body fade-in">
                    ${bodyHtml}
                </section>
            </main>
        </div>
    `;
};

App.toggleSidebar = function () {
    document.getElementById('sidebar')?.classList.toggle('open');
    document.getElementById('sidebar-overlay')?.classList.toggle('show');
};

App.closeSidebar = function () {
    document.getElementById('sidebar')?.classList.remove('open');
    document.getElementById('sidebar-overlay')?.classList.remove('show');
};
