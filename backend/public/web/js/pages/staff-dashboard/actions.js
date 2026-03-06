/**
 * Staff Dashboard Actions Module
 */
const { statusLabelMap: staffDashboardStatusLabelMap, statusBadgeClassMap: staffDashboardStatusBadgeClassMap, notifStorageKey: staffDashboardNotifStorageKey, parseList: staffDashboardParseList } = App.StaffDashboardCore;

App.Pages = App.Pages || {};
App.Pages.StaffDashboard = {
    pollTimer: null,
    notifStorageKey: staffDashboardNotifStorageKey,
    filteredRequestLogs: [],
    state: {
        filter_date: '',
    },

    getTodayDate() {
        return App.getTodayDate();
    },

    async load(params = {}) {
        this.state = { ...this.state, ...params };
        if (!this.state.filter_date) {
            this.state.filter_date = this.getTodayDate();
        }

        try {
            const [vehiclesRes, logsRes] = await Promise.all([
                App.Api.get('/carpool/vehicles').catch(() => []),
                App.Api.get('/carpool/logs').catch(() => ({ data: [] })),
            ]);

            const vehicles = staffDashboardParseList(vehiclesRes);
            const logs = staffDashboardParseList(logsRes);
            const filteredLogs = logs.filter((l) => ((l.date || '').toString().slice(0, 10) === this.state.filter_date));
            this.filteredRequestLogs = filteredLogs;

            const availableVehicles = vehicles.filter(v => v.status === 'available');
            // Untuk requester: selama driver belum confirm, tetap dianggap menunggu.
            const pendingRequests = logs.filter(l => ['requested', 'approved'].includes(l.status));
            const activeTrips = logs.filter(l => ['confirmed', 'in_use', 'pending_key'].includes(l.status));

            const loading = document.getElementById('sd-loading');
            if (loading) loading.classList.add('hidden');
            const content = document.getElementById('sd-content');
            if (!content) return;
            content.classList.remove('hidden');

            content.innerHTML = `
                <!-- Request Trip Form -->
                <div class="card mb-6">
                    <div class="card-header">
                        <h3><span class="material-icons-round" style="vertical-align:middle;margin-right:8px">add_circle</span>Request Trip Baru</h3>
                    </div>
                    <div class="card-body">
                        <form id="staff-trip-form">
                            <div class="form-row">
                                <div class="form-group">
                                    <label class="form-label">Tanggal</label>
                                    <input type="date" class="form-input" id="st-date" value="${new Date().toISOString().split('T')[0]}" required>
                                </div>
                                <div class="form-group">
                                    <label class="form-label">Tujuan</label>
                                    <input type="text" class="form-input" id="st-destination" placeholder="Tujuan perjalanan" required>
                                </div>
                            </div>
                            <div class="form-row">
                                <div class="form-group">
                                    <label class="form-label">Jam Berangkat</label>
                                    <input type="time" class="form-input" id="st-start-time" required>
                                </div>
                                <div class="form-group">
                                    <label class="form-label">Jam Pulang</label>
                                    <input type="time" class="form-input" id="st-end-time" required>
                                </div>
                            </div>
                            <div class="form-row">
                                <div class="form-group">
                                    <label class="form-label">Penumpang</label>
                                    <textarea class="form-textarea" id="st-passengers" rows="3" placeholder="" required></textarea>
                                    <p style="font-size:12px;color:var(--gray-500);margin-top:4px">Isi nama penumpang, pisahkan dengan koma.</p>
                                </div>
                            </div>
                            <button type="submit" class="btn btn-primary">
                                <span class="material-icons-round">send</span> Kirim Request
                            </button>
                        </form>
                    </div>
                </div>

                <!-- Stats -->
                <div class="grid-3 mb-6">
                    <div class="stat-card yellow">
                        <div class="stat-icon"><span class="material-icons-round">hourglass_top</span></div>
                        <div class="stat-info">
                            <div class="stat-value">${pendingRequests.length}</div>
                            <div class="stat-label">Menunggu Approval</div>
                        </div>
                    </div>
                    <div class="stat-card blue">
                        <div class="stat-icon"><span class="material-icons-round">directions_car</span></div>
                        <div class="stat-info">
                            <div class="stat-value">${activeTrips.length}</div>
                            <div class="stat-label">Trip Aktif</div>
                        </div>
                    </div>
                    <div class="stat-card green">
                        <div class="stat-icon"><span class="material-icons-round">directions_car</span></div>
                        <div class="stat-info">
                            <div class="stat-value">${availableVehicles.length} / ${vehicles.length}</div>
                            <div class="stat-label">Kendaraan Tersedia</div>
                        </div>
                    </div>
                </div>

                <!-- My Requests -->
                <div class="card">
                    <div class="card-header" style="display:flex;justify-content:space-between;align-items:end;gap:12px;flex-wrap:wrap">
                        <h3>Request Saya</h3>
                        <form id="staff-request-filter-form" style="display:flex;gap:8px;align-items:end;flex-wrap:wrap">
                            <div class="form-group" style="margin-bottom:0;min-width:170px">
                                <label class="form-label">Filter Tanggal</label>
                                <input type="date" class="form-input" id="staff-request-filter-date" value="${this.state.filter_date}">
                            </div>
                            <button type="submit" class="btn btn-outline btn-sm" style="height:38px">
                                <span class="material-icons-round">filter_list</span> Terapkan
                            </button>
                            <button type="button" class="btn btn-outline btn-sm" style="height:38px" onclick="App.Pages.StaffDashboard.resetRequestDateFilter()">
                                <span class="material-icons-round">today</span> Hari Ini
                            </button>
                        </form>
                    </div>
                    <div class="card-body">
                        ${filteredLogs.length > 0 ? `
                            <div class="table-container">
                                <table>
                                    <thead><tr>
                                        <th>Tanggal</th><th>Tujuan</th><th>Penumpang</th><th>Jam Berangkat</th><th>Jam Pulang</th><th>Kendaraan</th><th>Driver</th><th>Status</th>
                                    </tr></thead>
                                    <tbody>
                                        ${filteredLogs.map((l, idx) => `
                                            <tr style="cursor:pointer" onclick="App.Pages.StaffDashboard.showRequestDetail(${idx})">
                                                <td>${App.formatDate(l.date)}</td>
                                                <td>${l.destination || '-'}</td>
                                                <td>${l.passenger_names || '-'}</td>
                                                <td>${l.start_time || '-'}</td>
                                                <td>${l.end_time || '-'}</td>
                                                <td>${l.vehicle_display || '-'}</td>
                                                <td>${l.driver_display || '-'}</td>
                                                <td>${App.Pages.StaffDashboard.statusBadge(l.status)}</td>
                                            </tr>
                                        `).join('')}
                                    </tbody>
                                </table>
                            </div>
                        ` : `
                            <div class="empty-state">
                                <span class="material-icons-round">receipt_long</span>
                                <p>Belum ada request trip pada tanggal ${App.formatDate(this.state.filter_date)}</p>
                            </div>
                        `}
                    </div>
                </div>
            `;

            document.getElementById('staff-trip-form')?.addEventListener('submit', async (e) => {
                e.preventDefault();
                const date = document.getElementById('st-date').value;
                const destination = document.getElementById('st-destination').value.trim();
                const start_time = document.getElementById('st-start-time').value;
                const end_time = document.getElementById('st-end-time').value;
                const passenger_names = document.getElementById('st-passengers').value.trim();

                if (!date || !destination || !start_time || !end_time || !passenger_names) {
                    App.toast('Tanggal, Tujuan, Jam Berangkat, Jam Pulang, dan Penumpang wajib diisi', 'warning');
                    return;
                }

                try {
                    await App.Api.post('/carpool/logs', { date, destination, start_time, end_time, passenger_names });
                    App.toast('Request trip berhasil dikirim. Admin akan pilih kendaraan dan driver.', 'success');
                    App.Router.navigate('/staff/dashboard');
                } catch (err) {
                    App.toast('Gagal: ' + err.message, 'error');
                }
            });

            document.getElementById('staff-request-filter-form')?.addEventListener('submit', (e) => {
                e.preventDefault();
                const filter_date = document.getElementById('staff-request-filter-date')?.value || this.getTodayDate();
                this.load({ filter_date });
            });

            // Notifikasi approval hanya untuk user requester (staff ini saja).
            App.Pages.StaffDashboard.checkApprovalNotifications(logs);
            App.Pages.StaffDashboard.startPolling();
        } catch (err) {
            const loading = document.getElementById('sd-loading');
            if (loading) loading.innerHTML = `<p>Gagal memuat data: ${err.message}</p>`;
        }
    },

    statusLabel(s) {
        return staffDashboardStatusLabelMap[s] || s;
    },

    statusBadge(s) {
        return `<span class="badge ${staffDashboardStatusBadgeClassMap[s] || 'badge-gray'}">${this.statusLabel(s)}</span>`;
    },

    resetRequestDateFilter() {
        this.load({ filter_date: this.getTodayDate() });
    },

    showRequestDetail(index) {
        const log = this.filteredRequestLogs[index];
        if (!log) {
            App.toast('Detail request tidak ditemukan', 'warning');
            return;
        }

        const details = [
            ['Tanggal', App.formatDate(log.date), false],
            ['Tujuan', log.destination || '-', false],
            ['Penumpang', log.passenger_names || '-', false],
            ['Jam Berangkat', log.start_time || '-', false],
            ['Jam Pulang', log.end_time || '-', false],
            ['Kendaraan', log.vehicle_display || '-', false],
            ['Driver', log.driver_display || '-', false],
            ['Status', this.statusBadge(log.status), true],
            ['Trip Mulai', App.formatDateTime(log.trip_started_at), false],
            ['Trip Selesai', App.formatDateTime(log.trip_finished_at), false],
            ['Approved At', App.formatDateTime(log.approved_at), false],
        ];

        App.openModal(`
            <div class="modal-header">
                <h3>Detail Request Saya</h3>
                <button class="modal-close" onclick="App.closeModal()"><span class="material-icons-round">close</span></button>
            </div>
            <div class="modal-body">
                <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:10px">
                    ${details.map(([label, value, isHtml]) => `
                        <div style="background:var(--gray-50);border:1px solid var(--gray-100);border-radius:10px;padding:10px 12px">
                            <div style="font-size:11px;color:var(--gray-500);font-weight:600;text-transform:uppercase">${App.escapeHtml(label)}</div>
                            <div style="margin-top:4px;font-size:14px;font-weight:600">${isHtml ? value : App.escapeHtml(value)}</div>
                        </div>
                    `).join('')}
                </div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-ghost" onclick="App.closeModal()">Tutup</button>
            </div>
        `);
    },

    getNotifiedMap() {
        try {
            const raw = localStorage.getItem(this.notifStorageKey);
            const parsed = raw ? JSON.parse(raw) : {};
            return parsed && typeof parsed === 'object' ? parsed : {};
        } catch (e) {
            return {};
        }
    },

    saveNotifiedMap(map) {
        localStorage.setItem(this.notifStorageKey, JSON.stringify(map || {}));
    },

    checkApprovalNotifications(logs) {
        if (!Array.isArray(logs)) return;

        const notified = this.getNotifiedMap();
        const newlyApproved = logs.filter((log) => {
            const hasApproval = !!log.approved_at;
            const hasDriver = !!(log.driver_display && log.driver_display !== '-');
            const hasVehicle = !!(log.vehicle_display && log.vehicle_display !== '-');
            if (!hasApproval || !hasDriver || !hasVehicle) return false;
            const stamp = (log.approved_at || '').toString();
            return notified[String(log.id)] !== stamp;
        });

        newlyApproved.forEach((log) => {
            const destination = log.destination || '-';
            const driver = log.driver_display || '-';
            const vehicle = log.vehicle_display || '-';
            App.toast(`Request "${destination}" disetujui. Driver: ${driver}, Kendaraan: ${vehicle}.`, 'success');
            notified[String(log.id)] = (log.approved_at || '').toString();
        });

        if (newlyApproved.length > 0) {
            this.saveNotifiedMap(notified);
        }
    },

    startPolling() {
        this.stopPolling();
        this.pollTimer = setInterval(async () => {
            // Hanya polling saat user memang di halaman staff dashboard.
            if (location.hash !== '#/staff/dashboard') return;
            try {
                const logsRes = await App.Api.get('/carpool/logs');
                const logs = staffDashboardParseList(logsRes);
                this.checkApprovalNotifications(logs);
            } catch (e) {
                // Silent fail: jangan spam toast saat koneksi turun.
            }
        }, 15000);
    },

    stopPolling() {
        if (this.pollTimer) {
            clearInterval(this.pollTimer);
            this.pollTimer = null;
        }
    },
};

