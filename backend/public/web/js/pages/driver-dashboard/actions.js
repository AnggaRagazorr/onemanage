App.Pages = App.Pages || {};
App.Pages.DriverDashboard = {
    async loadData() {
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
                            <h4 style="font-size:16px;font-weight:700;margin-bottom:4px">${trip.destination}</h4>
                            <p style="font-size:13px;color:var(--gray-500);margin-bottom:12px">${trip.vehicle_display} - ${App.formatDate(trip.date)}</p>
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
                                <strong>${trip.destination}</strong>
                                <p style="font-size:13px;color:var(--gray-500)">${trip.vehicle_display}</p>
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
                                    <h4 style="font-size:16px;font-weight:700;margin-bottom:4px">${trip.destination}</h4>
                                    <p style="font-size:13px;color:var(--gray-500)">${trip.vehicle_display} - ${App.formatDate(trip.date)}</p>
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
                                <strong>${trip.destination}</strong>
                                <p style="font-size:13px;color:var(--gray-500)">${trip.vehicle_display}</p>
                            </div>
                            <span class="badge badge-yellow">Menunggu Security</span>
                        </div>
                    `).join('')}
                </div>
            </div>
            ` : ''}

            <div class="card">
                <div class="card-header"><h3>Riwayat Trip Selesai</h3></div>
                <div class="card-body">
                    ${completed.length > 0 ? `
                        <div class="table-container">
                            <table>
                                <thead><tr><th>Tanggal</th><th>Tujuan</th><th>Kendaraan</th><th>Status</th></tr></thead>
                                <tbody>
                                    ${completed.map((l) => `
                                        <tr>
                                            <td>${App.formatDate(l.date)}</td>
                                            <td>${l.destination || '-'}</td>
                                            <td>${l.vehicle_display}</td>
                                            <td><span class="badge badge-green">Selesai</span></td>
                                        </tr>
                                    `).join('')}
                                </tbody>
                            </table>
                        </div>
                    ` : '<div class="empty-state"><span class="material-icons-round">history</span><p>Belum ada riwayat</p></div>'}
                </div>
            </div>
        `;
    },

    async respond(logId, action) {
        if (!confirm(action === 'accept' ? 'Terima tugas ini?' : 'Tolak tugas ini?')) return;
        try {
            await App.Api.post(`/carpool/logs/${logId}/respond`, { response: action });
            App.toast(action === 'accept' ? 'Tugas diterima!' : 'Tugas ditolak', 'success');
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
