App.Pages = App.Pages || {};
App.Pages.DriverDashboard = {
    state: {
        history_date: '',
    },
    historyLogs: [],

    getTodayDate() {
        return App.getTodayDate();
    },

    async loadData(params = {}) {
        this.state = { ...this.state, ...params };
        if (!this.state.history_date) {
            this.state.history_date = this.getTodayDate();
        }

        const loading = document.getElementById('dd-loading');
        const content = document.getElementById('dd-content');
        if (loading) loading.classList.remove('hidden');
        if (content) content.classList.add('hidden');

        try {
            const logsRes = await App.Api.get('/carpool/logs');
            const logs = logsRes.data || logsRes || [];
            this.render(logs);
        } catch (err) {
            if (loading) loading.innerHTML = `<p>Gagal memuat data: ${err.message}</p>`;
        }
    },

    render(logs) {
        const loading = document.getElementById('dd-loading');
        const content = document.getElementById('dd-content');
        if (loading) loading.classList.add('hidden');
        if (content) content.classList.remove('hidden');
        if (!content) return;

        const pendingResponse = logs.filter((l) => l.status === 'approved');
        const confirmed = logs.filter((l) => l.status === 'confirmed');
        const activeTrips = logs.filter((l) => l.status === 'in_use');
        const pendingKey = logs.filter((l) => l.status === 'pending_key');
        const completed = logs.filter((l) => l.status === 'completed');
        const historyDate = this.state.history_date || this.getTodayDate();
        const filteredCompleted = completed.filter((l) => ((l.date || '').toString().slice(0, 10) === historyDate));
        this.historyLogs = filteredCompleted;

        content.innerHTML = `
            ${pendingResponse.length > 0 ? `
            <div class="card mb-6" style="border-left:4px solid var(--warning)">
                <div class="card-header">
                    <h3><span class="material-icons-round" style="vertical-align:middle;margin-right:8px;color:var(--warning)">notifications_active</span>Tugas Baru</h3>
                    <span class="badge badge-yellow">${pendingResponse.length}</span>
                </div>
                <div class="card-body">
                    ${pendingResponse.map((trip) => `
                        <div style="background:var(--glass-bg);border:1px solid var(--glass-border);border-radius:16px;padding:20px;margin-bottom:12px">
                            <h4 style="font-size:16px;font-weight:700;margin-bottom:4px">${App.escapeHtml(trip.destination || '-')}</h4>
                            <p style="font-size:13px;color:var(--gray-500);margin-bottom:12px">${App.escapeHtml(trip.vehicle_display || '-')} - ${App.formatDate(trip.date)}</p>
                            <div style="display:flex;gap:8px">
                                <button class="btn btn-primary btn-sm" onclick="App.Pages.DriverDashboard.respond(${trip.id}, 'accept')">
                                    <span class="material-icons-round">check</span> Terima
                                </button>
                                <button class="btn btn-danger btn-sm" onclick="App.Pages.DriverDashboard.respond(${trip.id}, 'reject')">
                                    <span class="material-icons-round">close</span> Tolak
                                </button>
                            </div>
                        </div>
                    `).join('')}
                </div>
            </div>
            ` : ''}

            ${confirmed.length > 0 ? `
            <div class="card mb-6">
                <div class="card-header">
                    <h3><span class="material-icons-round" style="vertical-align:middle;margin-right:8px">hourglass_empty</span>Menunggu Security (Check Out)</h3>
                    <span class="badge badge-blue">${confirmed.length}</span>
                </div>
                <div class="card-body">
                    ${confirmed.map((trip) => `
                        <div style="background:var(--glass-bg);border:1px solid var(--glass-border);border-radius:12px;padding:16px;margin-bottom:12px;display:flex;justify-content:space-between;align-items:center">
                            <div>
                                <strong>${App.escapeHtml(trip.destination || '-')}</strong>
                                <p style="font-size:13px;color:var(--gray-500)">${App.escapeHtml(trip.vehicle_display || '-')}</p>
                            </div>
                            <span class="badge badge-gray">Siap Berangkat</span>
                        </div>
                    `).join('')}
                    <p style="font-size:12px;color:var(--gray-500);font-style:italic;margin-top:8px">
                        * Segera menuju pos security untuk lapor keluar dan ambil kendaraan.
                    </p>
                </div>
            </div>
            ` : ''}

            <div class="card mb-6">
                <div class="card-header">
                    <h3><span class="material-icons-round" style="vertical-align:middle;margin-right:8px">directions_car</span>Trip Aktif</h3>
                </div>
                <div class="card-body">
                    ${activeTrips.length > 0 ? activeTrips.map((trip) => `
                        <div class="trip-card in_use" style="background:var(--glass-bg);border:1px solid var(--glass-border);border-radius:16px;padding:20px;margin-bottom:16px">
                            <div style="display:flex;justify-content:space-between;align-items:start;margin-bottom:12px">
                                <div>
                                    <h4 style="font-size:16px;font-weight:700;margin-bottom:4px">${App.escapeHtml(trip.destination || '-')}</h4>
                                    <p style="font-size:13px;color:var(--gray-500)">${App.escapeHtml(trip.vehicle_display || '-')} - ${App.formatDate(trip.date)}</p>
                                </div>
                                <span class="badge badge-blue">Sedang Trip</span>
                            </div>
                            <button class="btn btn-primary btn-sm" style="background:var(--warning)" onclick="App.Pages.DriverDashboard.tripFinish(${trip.id})">
                                <span class="material-icons-round">stop</span> Selesai Trip (Input KM)
                            </button>
                        </div>
                    `).join('') : `
                        <div class="empty-state">
                            <span class="material-icons-round">directions_car</span>
                            <p>Tidak ada trip aktif</p>
                        </div>
                    `}
                </div>
            </div>

            ${pendingKey.length > 0 ? `
            <div class="card mb-6">
                <div class="card-header">
                    <h3><span class="material-icons-round" style="vertical-align:middle;margin-right:8px">vpn_key</span>Menunggu Validasi Kunci</h3>
                    <span class="badge badge-yellow">${pendingKey.length}</span>
                </div>
                <div class="card-body">
                    ${pendingKey.map((trip) => `
                        <div style="background:var(--glass-bg);border:1px solid var(--glass-border);border-radius:12px;padding:16px;margin-bottom:12px;display:flex;justify-content:space-between;align-items:center">
                            <div>
                                <strong>${App.escapeHtml(trip.destination || '-')}</strong>
                                <p style="font-size:13px;color:var(--gray-500)">${App.escapeHtml(trip.vehicle_display || '-')}</p>
                            </div>
                            <span class="badge badge-yellow">Menunggu Security</span>
                        </div>
                    `).join('')}
                </div>
            </div>
            ` : ''}

            <div class="card">
                <div class="card-header" style="display:flex;justify-content:space-between;align-items:end;gap:12px;flex-wrap:wrap">
                    <h3>Riwayat Trip Selesai</h3>
                    <form id="driver-history-filter-form" style="display:flex;gap:8px;align-items:end;flex-wrap:wrap">
                        <div class="form-group" style="margin-bottom:0;min-width:170px">
                            <label class="form-label">Filter Tanggal</label>
                            <input type="date" class="form-input" id="driver-history-filter-date" value="${historyDate}">
                        </div>
                        <button type="submit" class="btn btn-outline btn-sm" style="height:38px">
                            <span class="material-icons-round">filter_list</span> Terapkan
                        </button>
                        <button type="button" class="btn btn-outline btn-sm" style="height:38px" onclick="App.Pages.DriverDashboard.resetHistoryDateFilter()">
                            <span class="material-icons-round">today</span> Hari Ini
                        </button>
                    </form>
                </div>
                <div class="card-body">
                    ${filteredCompleted.length > 0 ? `
                        <p style="font-size:12px;color:var(--gray-500);margin-bottom:10px">Klik baris riwayat untuk melihat detail trip.</p>
                        <div class="table-container">
                            <table>
                                <thead><tr><th>Tanggal</th><th>Tujuan</th><th>Kendaraan</th><th>Status</th></tr></thead>
                                <tbody>
                                    ${filteredCompleted.map((l, idx) => `
                                        <tr style="cursor:pointer" onclick="App.Pages.DriverDashboard.showCompletedDetail(${idx})">
                                            <td>${App.formatDate(l.date)}</td>
                                            <td>${App.escapeHtml(l.destination || '-')}</td>
                                            <td>${App.escapeHtml(l.vehicle_display || '-')}</td>
                                            <td><span class="badge badge-green">Selesai</span></td>
                                        </tr>
                                    `).join('')}
                                </tbody>
                            </table>
                        </div>
                    ` : `<div class="empty-state"><span class="material-icons-round">history</span><p>Belum ada riwayat pada tanggal ${App.formatDate(historyDate)}</p></div>`}
                </div>
            </div>
        `;

        document.getElementById('driver-history-filter-form')?.addEventListener('submit', (e) => {
            e.preventDefault();
            const history_date = document.getElementById('driver-history-filter-date')?.value || this.getTodayDate();
            this.loadData({ history_date });
        });
    },

    resetHistoryDateFilter() {
        this.loadData({ history_date: this.getTodayDate() });
    },

    showCompletedDetail(index) {
        const log = this.historyLogs[index];
        if (!log) {
            App.toast('Detail trip tidak ditemukan', 'warning');
            return;
        }

        const details = [
            ['Tanggal', App.formatDate(log.date), false],
            ['Status', '<span class="badge badge-green">Selesai</span>', true],
            ['Tujuan', log.destination || '-', false],
            ['Kendaraan', log.vehicle_display || '-', false],
            ['Pemohon', log.user_name || '-', false],
            ['Penumpang', log.passenger_names || '-', false],
            ['Jam Berangkat', log.start_time || '-', false],
            ['Jam Pulang', log.end_time || '-', false],
            ['Trip Mulai', App.formatDateTime(log.trip_started_at), false],
            ['Trip Selesai', App.formatDateTime(log.trip_finished_at), false],
            ['Kunci Kembali', App.formatDateTime(log.key_returned_at), false],
            ['KM Terakhir', log.last_km || '-', false],
        ];

        App.openModal(`
            <div class="modal-header">
                <h3>Detail Trip Selesai</h3>
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

    async respond(logId, action) {
        if (action === 'accept') {
            if (!confirm('Terima tugas ini?')) return;
            try {
                await App.Api.post(`/carpool/logs/${logId}/respond`, { response: 'accept' });
                App.toast('Tugas diterima!', 'success');
                App.Router.navigate('/driver/dashboard');
            } catch (e) {
                App.toast('Gagal: ' + e.message, 'error');
            }
            return;
        }

        // Reject: show modal with reason textarea
        App.openModal(`
            <div class="modal-header">
                <h3>Tolak Tugas</h3>
                <button class="modal-close" onclick="App.closeModal()"><span class="material-icons-round">close</span></button>
            </div>
            <div class="modal-body">
                <div class="form-group">
                    <label class="form-label">Alasan Penolakan (Wajib)</label>
                    <textarea class="form-textarea" id="reject-reason" rows="4" placeholder="Jelaskan alasan menolak tugas ini (minimal 10 karakter)..." required></textarea>
                    <p style="font-size:12px;color:var(--gray-500);margin-top:4px">Alasan akan dikirim ke admin untuk penjadwalan ulang.</p>
                </div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-ghost" onclick="App.closeModal()">Batal</button>
                <button class="btn btn-danger" onclick="App.Pages.DriverDashboard.doReject(${logId})">
                    <span class="material-icons-round">close</span> Kirim Penolakan
                </button>
            </div>
        `);
    },

    async doReject(logId) {
        const reason = (document.getElementById('reject-reason')?.value || '').trim();
        if (reason.length < 10) {
            App.toast('Alasan penolakan minimal 10 karakter', 'warning');
            return;
        }
        try {
            await App.Api.post(`/carpool/logs/${logId}/respond`, {
                response: 'reject',
                reject_reason: reason,
            });
            App.closeModal();
            App.toast('Tugas ditolak. Admin akan menjadwalkan ulang.', 'success');
            App.Router.navigate('/driver/dashboard');
        } catch (e) {
            App.toast('Gagal: ' + e.message, 'error');
        }
    },

    tripFinish(logId) {
        App.openModal(`
            <div class="modal-header">
                <h3>Selesaikan Trip</h3>
                <button class="modal-close" onclick="App.closeModal()"><span class="material-icons-round">close</span></button>
            </div>
            <div class="modal-body">
                <div class="form-group">
                    <label class="form-label">KM Akhir Trip (Wajib)</label>
                    <input type="number" class="form-input" id="finish-km" placeholder="Contoh: 12.5" min="0" step="0.1">
                    <p style="font-size:12px;color:var(--gray-500);margin-top:4px">Input jumlah KM perjalanan trip ini. System KM akan bertambah otomatis.</p>
                </div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-ghost" onclick="App.closeModal()">Batal</button>
                <button class="btn btn-primary" onclick="App.Pages.DriverDashboard.doFinish(${logId})">Selesaikan</button>
            </div>
        `);
    },

    async doFinish(logId) {
        const last_km = document.getElementById('finish-km')?.value?.trim();
        if (!last_km) {
            App.toast('KM Terakhir wajib diisi!', 'warning');
            return;
        }

        try {
            await App.Api.post(`/carpool/logs/${logId}/trip-finish`, { last_km });
            App.closeModal();
            App.toast('Trip selesai! Menunggu validasi kunci oleh Security', 'success');
            App.Router.navigate('/driver/dashboard');
        } catch (e) {
            App.toast('Gagal: ' + e.message, 'error');
        }
    }
};
