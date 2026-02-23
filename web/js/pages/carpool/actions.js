/**
 * Carpool Actions Module
 */
const { parseList: carpoolParseList, statusMeta: carpoolStatusMeta } = App.CarpoolCore;

App.Pages = App.Pages || {};
App.Pages.CarpoolSecurity = {
    recentLogs: [],
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
            const logsQuery = {};
            if (this.state.filter_date) {
                logsQuery.start_date = this.state.filter_date;
                logsQuery.end_date = this.state.filter_date;
            }

            const [vehiclesRes, logsRes] = await Promise.all([
                App.Api.get('/carpool/vehicles').catch(() => []),
                App.Api.get('/carpool/logs', logsQuery).catch(() => ({ data: [] })),
            ]);

            const vehicles = carpoolParseList(vehiclesRes);
            const allLogs = carpoolParseList(logsRes);
            const selectedDate = this.state.filter_date;
            const logs = selectedDate
                ? allLogs.filter((l) => ((l.date || '').toString().slice(0, 10) === selectedDate))
                : allLogs;
            const recentLogs = logs.slice(0, 10);
            App.Pages.CarpoolSecurity.recentLogs = recentLogs;

            const loading = document.getElementById('carpool-loading');
            if (loading) loading.classList.add('hidden');
            const content = document.getElementById('carpool-content');
            if (!content) return;
            content.classList.remove('hidden');

            // New Workflow Filter
            const readyToDepart = logs.filter(l => l.status === 'confirmed');
            const pendingKey = logs.filter(l => l.status === 'pending_key');

            const availableV = vehicles.filter(v => v.status === 'available');
            const inUseV = vehicles.filter(v => v.status === 'in_use');

            content.innerHTML = `
                <!-- 1. Ready to Depart (Security Check Out) -->
                ${readyToDepart.length > 0 ? `
                <div class="card mb-6" style="border-left:4px solid var(--primary)">
                    <div class="card-header">
                        <h3><span class="material-icons-round" style="vertical-align:middle;margin-right:8px;color:var(--primary)">login</span>Siap Keluar (Check Out)</h3>
                        <span class="badge badge-blue">${readyToDepart.length} kendaraan</span>
                    </div>
                    <div class="card-body">
                        ${readyToDepart.map(trip => `
                            <div style="background:var(--glass-bg);border:1px solid var(--glass-border);border-radius:16px;padding:20px;margin-bottom:12px">
                                <div style="display:flex;justify-content:space-between;align-items:start;flex-wrap:wrap;gap:12px">
                                    <div>
                                        <span class="badge badge-gray mb-2">Driver: ${trip.driver_display || '-'}</span>
                                        <h4 style="font-size:16px;font-weight:700">${trip.vehicle_display}</h4>
                                        <p style="font-size:13px;color:var(--gray-500)">
                                            Tujuan: ${trip.destination} &bull; ${App.formatDate(trip.date)}
                                        </p>
                                    </div>
                                    <button class="btn btn-primary btn-sm" onclick="App.Pages.CarpoolSecurity.checkOut(${trip.id})">
                                        <span class="material-icons-round">arrow_forward</span> Catat Keluar
                                    </button>
                                </div>
                            </div>
                        `).join('')}
                    </div>
                </div>
                ` : ''}

                <!-- 2. Pending Key Validation (Security Check In) -->
                ${pendingKey.length > 0 ? `
                <div class="card mb-6" style="border-left:4px solid var(--warning)">
                    <div class="card-header">
                        <h3><span class="material-icons-round" style="vertical-align:middle;margin-right:8px;color:var(--warning)">vpn_key</span>Validasi Kunci (Check In)</h3>
                        <span class="badge badge-yellow">${pendingKey.length} menunggu</span>
                    </div>
                    <div class="card-body">
                        ${pendingKey.map(trip => `
                            <div style="background:var(--glass-bg);border:1px solid var(--glass-border);border-radius:16px;padding:20px;margin-bottom:12px">
                                <div style="display:flex;justify-content:space-between;align-items:start;flex-wrap:wrap;gap:12px">
                                    <div>
                                        <span class="badge badge-gray mb-2">Driver: ${trip.driver_display || '-'}</span>
                                        <h4 style="font-size:15px;font-weight:700">${trip.vehicle_display}</h4>
                                        <p style="font-size:13px;color:var(--gray-500)">
                                            Tujuan: ${trip.destination} &bull; Last KM: ${trip.last_km || '-'}
                                        </p>
                                    </div>
                                    <button class="btn btn-warning btn-sm" onclick="App.Pages.CarpoolSecurity.validateKey(${trip.id})">
                                        <span class="material-icons-round">vpn_key</span> Terima Kunci
                                    </button>
                                </div>
                            </div>
                        `).join('')}
                    </div>
                </div>
                ` : ''}

                ${readyToDepart.length === 0 && pendingKey.length === 0 ? `
                <div class="card mb-6">
                    <div class="card-body" style="text-align:center;padding:40px">
                        <span class="material-icons-round" style="font-size:48px;color:var(--success);margin-bottom:12px">check_circle</span>
                        <h3 style="font-size:18px;font-weight:700;margin-bottom:8px">Tidak Ada Antrian</h3>
                        <p style="color:var(--gray-500)">Tidak ada kendaraan yang perlu dicatat keluar atau masuk.</p>
                    </div>
                </div>
                ` : ''}

                <!-- Stats -->
                <div class="grid-3 mb-6">
                    <div class="stat-card green">
                        <div class="stat-icon"><span class="material-icons-round">check_circle</span></div>
                        <div class="stat-info"><div class="stat-value">${availableV.length}</div><div class="stat-label">Available</div></div>
                    </div>
                    <div class="stat-card blue">
                        <div class="stat-icon"><span class="material-icons-round">directions_car</span></div>
                        <div class="stat-info"><div class="stat-value">${inUseV.length}</div><div class="stat-label">In Use</div></div>
                    </div>
                    <div class="stat-card yellow">
                        <div class="stat-icon"><span class="material-icons-round">vpn_key</span></div>
                        <div class="stat-info"><div class="stat-value">${pendingKey.length}</div><div class="stat-label">Pending Key</div></div>
                    </div>
                </div>

                <div class="card mb-6">
                    <div class="card-body">
                        <form id="carpool-log-filter-form" style="display:flex;gap:12px;align-items:flex-end;flex-wrap:wrap">
                            <div class="form-group" style="margin-bottom:0;min-width:180px">
                                <label class="form-label">Filter Tanggal Log</label>
                                <input type="date" class="form-input" id="carpool-log-filter-date" value="${this.state.filter_date || ''}">
                            </div>
                            <button type="submit" class="btn btn-primary" style="height:42px">
                                <span class="material-icons-round">filter_list</span> Terapkan
                            </button>
                            <button type="button" class="btn btn-outline" style="height:42px" onclick="App.Pages.CarpoolSecurity.resetDateFilter()">
                                <span class="material-icons-round">today</span> Hari Ini
                            </button>
                        </form>
                    </div>
                </div>

                <!-- Recent Logs -->
                <div class="card">
                    <div class="card-header"><h3>Log Tanggal ${App.formatDate(this.state.filter_date)}</h3></div>
                    <div class="card-body">
                        ${logs.length > 0 ? `
                            <p style="font-size:12px;color:var(--gray-500);margin-bottom:10px">Klik baris log untuk melihat detail lengkap.</p>
                            <div class="table-container">
                                <table>
                                    <thead><tr><th>Tanggal</th><th>Kendaraan</th><th>Status</th></tr></thead>
                                    <tbody>
                                        ${recentLogs.map((l, idx) => {
                const badge = App.Pages.CarpoolSecurity.statusBadge(l.status);
                return `<tr style="cursor:pointer" onclick="App.Pages.CarpoolSecurity.showLogDetail(${idx})"><td>${App.formatDate(l.date)}</td><td>${l.vehicle_display}</td><td>${badge}</td></tr>`;
            }).join('')}
                                    </tbody>
                                </table>
                            </div>
                        ` : '<div class="empty-state"><span class="material-icons-round">history</span><p>Belum ada log</p></div>'}
                    </div>
                </div>
            `;

            document.getElementById('carpool-log-filter-form')?.addEventListener('submit', (e) => {
                e.preventDefault();
                const filter_date = document.getElementById('carpool-log-filter-date')?.value || this.getTodayDate();
                this.load({ filter_date });
            });
        } catch (err) {
            const loading = document.getElementById('carpool-loading');
            if (loading) loading.innerHTML = '<p>Gagal memuat data</p>';
        }
    },

    statusMeta(status) {
        return carpoolStatusMeta(status);
    },

    statusBadge(status) {
        const { cls, lbl } = this.statusMeta(status);
        return `<span class="badge ${cls}">${lbl}</span>`;
    },

    showLogDetail(index) {
        const log = this.recentLogs[index];
        if (!log) {
            App.toast('Detail log tidak ditemukan', 'warning');
            return;
        }

        const status = this.statusMeta(log.status);
        const departureTimeRaw = (log.start_time ?? '').toString().trim();
        const departureTime = departureTimeRaw && departureTimeRaw !== '-' && departureTimeRaw !== '--'
            ? departureTimeRaw
            : '-';
        const detailRows = [
            ['Tanggal Trip', App.formatDate(log.date)],
            ['Kendaraan', log.vehicle_display || '-'],
            ['Status', `<span class="badge ${status.cls}">${status.lbl}</span>`],
            ['Pemohon', log.user_name || '-'],
            ['Penumpang', log.passenger_names || '-'],
            ['Driver', log.driver_display || '-'],
            ['Tujuan', log.destination || '-'],
            ['Jam Berangkat', departureTime],
            ['Trip Mulai', App.formatDateTime(log.trip_started_at)],
            ['Trip Selesai', App.formatDateTime(log.trip_finished_at)],
            ['Kunci Kembali', App.formatDateTime(log.key_returned_at)],
            ['KM Terakhir', log.last_km || '-'],
            ['Approved By', log.approver_name || '-'],
            ['Validator Kunci', log.validator_name || '-']
        ];

        App.openModal(`
            <div class="modal-header">
                <h3>Detail Log Carpool</h3>
                <button class="modal-close" onclick="App.closeModal()"><span class="material-icons-round">close</span></button>
            </div>
            <div class="modal-body">
                <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:10px">
                    ${detailRows.map(([label, value]) => `
                        <div style="background:var(--gray-50);border:1px solid var(--gray-100);border-radius:10px;padding:10px 12px">
                            <div style="font-size:11px;color:var(--gray-500);font-weight:600;text-transform:uppercase">${label}</div>
                            <div style="margin-top:4px;font-size:14px;font-weight:600">${value}</div>
                        </div>
                    `).join('')}
                </div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-ghost" onclick="App.closeModal()">Tutup</button>
            </div>
        `);
    },

    resetDateFilter() {
        this.load({ filter_date: this.getTodayDate() });
    },

    async checkOut(logId) {
        if (!confirm('Catat kendaraan KELUAR dan mulai trip?')) return;
        try {
            await App.Api.post(`/carpool/logs/${logId}/trip-start`); // Now Security calls this
            App.toast('Kendaraan tercatat KELUAR (In Use)', 'success');
            this.load();
        } catch (e) {
            App.toast('Gagal: ' + e.message, 'error');
        }
    },

    async validateKey(logId) {
        if (!confirm('Konfirmasi kunci sudah diterima dan kendaraan KEMBALI?')) return;
        try {
            await App.Api.post(`/carpool/logs/${logId}/validate-key`);
            App.toast('Kunci divalidasi, kendaraan AVAILABLE', 'success');
            this.load();
        } catch (e) {
            App.toast('Gagal: ' + e.message, 'error');
        }
    },
};

