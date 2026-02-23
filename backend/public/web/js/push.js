/**
 * Targeted web notifications (polling-based).
 */
App.Push = {
    started: false,
    pollTimer: null,
    pollIntervalMs: 15000,
    swRegistration: null,
    lastId: 0,
    userKey: '',
    hasPrimed: false,
    iosHintShown: false,

    ensureStarted() {
        if (!App.Auth?.isLoggedIn?.()) {
            this.stop();
            return;
        }

        const nextUserKey = this.buildUserKey();
        if (this.started && this.userKey === nextUserKey) {
            return;
        }

        this.stop();
        this.userKey = nextUserKey;
        this.lastId = this.readLastId();
        this.hasPrimed = false;
        this.iosHintShown = false;
        this.started = true;

        this.registerServiceWorker();
        this.requestPermissionIfNeeded();
        this.pollOnce();
        this.pollTimer = setInterval(() => this.pollOnce(), this.pollIntervalMs);
    },

    stop() {
        this.started = false;
        if (this.pollTimer) {
            clearInterval(this.pollTimer);
            this.pollTimer = null;
        }
        this.swRegistration = null;
        this.lastId = 0;
        this.userKey = '';
        this.hasPrimed = false;
        this.iosHintShown = false;
    },

    buildUserKey() {
        const id = String(App.Auth?.getId?.() || '').trim();
        if (id) return `u_${id}`;
        const role = String(App.Auth?.getRole?.() || '').trim();
        const name = String(App.Auth?.getName?.() || '').trim();
        return `fallback_${role}_${name}`;
    },

    getStorageKey() {
        return `om_push_last_id_${this.userKey || 'unknown'}`;
    },

    readLastId() {
        const raw = localStorage.getItem(this.getStorageKey());
        const parsed = Number(raw || 0);
        return Number.isFinite(parsed) && parsed > 0 ? parsed : 0;
    },

    saveLastId(value) {
        const numeric = Number(value || 0);
        if (!Number.isFinite(numeric) || numeric < 0) return;
        localStorage.setItem(this.getStorageKey(), String(Math.floor(numeric)));
    },

    isIosDevice() {
        return /iPhone|iPad|iPod/i.test(navigator.userAgent || '');
    },

    isStandaloneMode() {
        const standaloneByNavigator = window.navigator && window.navigator.standalone === true;
        const standaloneByMedia = window.matchMedia && window.matchMedia('(display-mode: standalone)').matches;
        return !!(standaloneByNavigator || standaloneByMedia);
    },

    showIosInstallHintOnce() {
        if (this.iosHintShown) return;
        this.iosHintShown = true;
        const key = `om_ios_push_hint_${this.userKey || 'unknown'}`;
        if (sessionStorage.getItem(key)) return;
        sessionStorage.setItem(key, '1');
        App.toast('iPhone Safari: notifikasi hanya muncul jika web di-Add to Home Screen lalu dibuka dari ikon app.', 'warning');
    },

    requestPermissionIfNeeded() {
        if (!('Notification' in window)) return;
        if (this.isIosDevice() && !this.isStandaloneMode()) {
            this.showIosInstallHintOnce();
            return;
        }
        if (Notification.permission !== 'default') return;

        const promptKey = `om_push_prompted_${this.userKey || 'unknown'}`;
        if (sessionStorage.getItem(promptKey)) return;
        sessionStorage.setItem(promptKey, '1');

        const request = () => Notification.requestPermission().catch(() => { });
        if (this.isIosDevice()) {
            // Safari iOS is stricter: permission should be requested from a user gesture.
            let asked = false;
            const askOnce = () => {
                if (asked) return;
                asked = true;
                request();
            };
            window.addEventListener('click', askOnce, { once: true, passive: true });
            window.addEventListener('touchend', askOnce, { once: true, passive: true });
            return;
        }

        request();
    },

    async registerServiceWorker() {
        if (!('serviceWorker' in navigator)) return;

        try {
            const basePath = this.getBasePath();
            const swUrl = `${basePath}sw.js`;
            this.swRegistration = await navigator.serviceWorker.register(swUrl, { scope: basePath });
        } catch (e) {
            this.swRegistration = null;
        }
    },

    getBasePath() {
        const href = document.querySelector('base')?.getAttribute('href') || '/';
        return href.endsWith('/') ? href : `${href}/`;
    },

    toRouteUrl(path) {
        const rawPath = String(path || '').trim();
        const routePath = rawPath.startsWith('/') ? rawPath : `/${rawPath}`;
        return `${window.location.origin}${this.getBasePath()}#${routePath}`;
    },

    async pollOnce() {
        if (!this.started || !App.Auth?.isLoggedIn?.()) return;

        try {
            if (!this.hasPrimed && this.lastId <= 0) {
                this.hasPrimed = true;
                const seed = await App.Api.get('/notifications', { limit: 10 });
                const seedRows = Array.isArray(seed?.data) ? seed.data : [];
                if (seedRows.length > 0) {
                    for (const row of seedRows) {
                        if (!row?.is_read) {
                            this.showNotification(row);
                        }
                    }
                    const latestId = Number(seedRows[seedRows.length - 1]?.id || 0);
                    if (latestId > 0) this.lastId = latestId;
                    this.saveLastId(this.lastId);
                }
                return;
            }

            const res = await App.Api.get('/notifications', {
                after_id: this.lastId,
                limit: 30,
            });
            const rows = Array.isArray(res?.data) ? res.data : [];
            if (rows.length === 0) return;

            rows.sort((a, b) => Number(a.id || 0) - Number(b.id || 0));
            for (const row of rows) {
                this.showNotification(row);
                const id = Number(row?.id || 0);
                if (id > this.lastId) this.lastId = id;
            }
            this.saveLastId(this.lastId);
        } catch (e) {
            // Keep silent; polling retries automatically.
        }
    },

    async showNotification(item) {
        const title = String(item?.title || 'Notifikasi');
        const body = String(item?.body || '');
        const routePath = String(item?.action_url || '');
        const routeUrl = this.toRouteUrl(routePath || '/');
        const id = Number(item?.id || 0);

        if ('Notification' in window && Notification.permission === 'granted') {
            if (this.swRegistration?.showNotification) {
                this.swRegistration.showNotification(title, {
                    body,
                    icon: `${this.getBasePath()}assets/image/logo_pgncom.png`,
                    badge: `${this.getBasePath()}assets/image/logo_pgncom.png`,
                    data: { url: routeUrl, id, routePath },
                    tag: `om-notif-${id || Date.now()}`,
                });
                this.markRead(id);
                return;
            }

            const n = new Notification(title, { body });
            n.onclick = () => {
                window.focus();
                if (routePath) App.Router.navigate(routePath);
            };
            this.markRead(id);
            return;
        }

        App.toast(`${title}${body ? ` - ${body}` : ''}`, 'info');
        this.markRead(id);
    },

    async markRead(id) {
        const numericId = Number(id || 0);
        if (!Number.isFinite(numericId) || numericId <= 0) return;
        try {
            await App.Api.post(`/notifications/${numericId}/read`);
        } catch (e) {
            // Ignore; read state is not critical for flow.
        }
    },
};
