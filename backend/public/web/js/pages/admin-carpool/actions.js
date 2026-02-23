/**
 * Admin Carpool Actions Module
 */
const { getTodayDate: adminCarpoolGetTodayDate, esc: adminCarpoolEsc, toId: adminCarpoolToId, safeBadgeClass: adminCarpoolSafeBadgeClass } = App.AdminCarpoolCore;

App.Pages = App.Pages || {};
App.Pages.AdminCarpool = {
    state: {
        filter_date: '',
        search: '',
    },
    currentLogs: [],

    getTodayDate() {
        return adminCarpoolGetTodayDate();
    },

    async loadData(params = {}) {
        this.state = { ...this.state, ...params };
        if (!this.state.filter_date) {
            this.state.filter_date = this.getTodayDate();
        }

        const loading = document.getElementById('ac-loading');
        const content = document.getElementById('ac-content');
        if (loading) loading.classList.remove('hidden');
        if (content) content.classList.add('hidden');

        try {
            const queryParams = {};
            if (this.state.filter_date) {
                queryParams.start_date = this.state.filter_date;
                queryParams.end_date = this.state.filter_date;
            }
            if (this.state.search) {
                queryParams.search = this.state.search;
            }

            const query = new URLSearchParams(queryParams).toString();
            // Vehicles and Drivers are ignoring filters for now (reference data)
            // Logs respect filters
            const [vehiclesRes, driversRes, logsRes] = await Promise.all([
                App.Api.get('/carpool/vehicles').catch(() => []),
                App.Api.get('/carpool/drivers').catch(() => []),
                App.Api.get(`/carpool/logs?${query}`).catch(() => ({ data: [] })),
            ]);

            const vehicles = Array.isArray(vehiclesRes) ? vehiclesRes : (vehiclesRes.data || []);
            const drivers = Array.isArray(driversRes) ? driversRes : (driversRes.data || []);
            const rawLogs = Array.isArray(logsRes) ? logsRes : (logsRes.data || []);
            let logs = rawLogs;

            if (this.state.filter_date) {
                logs = logs.filter((l) => ((l.date || '').toString().slice(0, 10) === this.state.filter_date));
            }
            if (this.state.search) {
                const q = this.state.search.toLowerCase();
                logs = logs.filter((l) => {
                    const haystack = [
                        l.user_name,
                        l.vehicle_display,
                        l.destination,
                        l.driver_display,
                        l.passenger_names,
                    ].join(' ').toLowerCase();
                    return haystack.includes(q);
                });
            }

            this.render(vehicles, drivers, logs, this.state);
        } catch (err) {
            if (loading) loading.innerHTML = '<p>Gagal memuat data</p>';
        }
    },

    render(vehicles, drivers, logs, params) {
        const loading = document.getElementById('ac-loading');
        const content = document.getElementById('ac-content');
        if (loading) loading.classList.add('hidden');
        if (content) content.classList.remove('hidden');
        this.currentLogs = logs;

        const availableV = vehicles.filter(v => v.status === 'available');
        const inUseV = vehicles.filter(v => v.status === 'in_use');
        const pendingKeyV = vehicles.filter(v => v.status === 'pending_key');
        const pendingApproval = logs.filter(l => l.status === 'requested');

        // Filter drivers: use is_busy flag from backend (globally checks active trips)
        const availableDrivers = drivers.filter(d => !d.is_busy);

        content.innerHTML = `
            <!-- Overview Stats -->
            <div class="grid-4 mb-6">
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
                    <div class="stat-info"><div class="stat-value">${pendingKeyV.length}</div><div class="stat-label">Pending Key</div></div>
                </div>
                <div class="stat-card info">
                    <div class="stat-icon"><span class="material-icons-round">person</span></div>
                    <div class="stat-info"><div class="stat-value">${drivers.length}</div><div class="stat-label">Driver</div></div>
                </div>
            </div>

            <!-- Filters -->
            <div class="card mb-6">
                <div class="card-body">
                    <form id="ac-filter-form" style="display:flex;gap:12px;align-items:flex-end;flex-wrap:wrap">
                        <div class="form-group" style="margin-bottom:0;flex:1;min-width:150px">
                            <label class="form-label">Tanggal</label>
                            <input type="date" class="form-input" id="f-date" value="${adminCarpoolEsc(params.filter_date || '')}">
                        </div>
                        <div class="form-group" style="margin-bottom:0;flex:1;min-width:200px">
                            <label class="form-label">Cari (User/Nopol)</label>
                            <input type="text" class="form-input" id="f-search" placeholder="Cari..." value="${adminCarpoolEsc(params.search || '')}">
                        </div>
                        <button type="submit" class="btn btn-primary" style="height:42px">
                            <span class="material-icons-round">filter_list</span> Filter
                        </button>
                        <button type="button" class="btn btn-outline" style="height:42px" onclick="App.Pages.AdminCarpool.exportData()">
                            <span class="material-icons-round">picture_as_pdf</span> Export PDF
                        </button>
                    </form>
                </div>
            </div>

            <!-- Pending Approval -->
            ${pendingApproval.length > 0 ? `
            <div class="card mb-6" style="border-left:4px solid var(--warning)">
                <div class="card-header">
                    <h3><span class="material-icons-round" style="vertical-align:middle;margin-right:8px;color:var(--warning)">pending_actions</span>Menunggu Approval</h3>
                    <span class="badge badge-yellow">${pendingApproval.length} request</span>
                </div>
                <div class="card-body">
                    ${pendingApproval.map((trip) => {
            const tripId = adminCarpoolToId(trip.id);
            return `
                        <div style="background:var(--glass-bg);border:1px solid var(--glass-border);border-radius:16px;padding:20px;margin-bottom:12px">
                            <div style="display:flex;justify-content:space-between;align-items:start;flex-wrap:wrap;gap:12px">
                                <div>
                                    <h4 style="font-size:15px;font-weight:700">${adminCarpoolEsc(trip.destination || '-')}</h4>
                                    <p style="font-size:13px;color:var(--gray-500)">
                                        ${adminCarpoolEsc(App.formatDate(trip.date))} - Oleh: ${adminCarpoolEsc(trip.user_name || '-')}
                                    </p>
                                    <p style="font-size:13px;color:var(--gray-500);margin-top:6px">
                                        Penumpang: ${adminCarpoolEsc(trip.passenger_names || '-')} - Jam: ${adminCarpoolEsc(trip.start_time || '-')}
                                    </p>
                                </div>
                                <div style="display:flex;gap:8px;flex-wrap:wrap">
                                    <select class="form-select form-select-sm" id="pa-vehicle-${tripId}" style="min-width:190px">
                                        <option value="">Pilih kendaraan...</option>
                                        ${availableV.map(v => `<option value="${adminCarpoolToId(v.id)}">${adminCarpoolEsc(v.plate)} - ${adminCarpoolEsc(v.brand)}</option>`).join('')}
                                    </select>
                                    <select class="form-select form-select-sm" id="pa-driver-${tripId}" style="min-width:170px">
                                        <option value="">Pilih driver...</option>
                                        ${availableDrivers.map(d => `<option value="${adminCarpoolToId(d.id)}">${adminCarpoolEsc(d.name)} (${adminCarpoolEsc(d.nip)})</option>`).join('')}
                                    </select>
                                    <button class="btn btn-primary btn-sm" onclick="App.Pages.AdminCarpool.approve(${tripId})" ${availableV.length === 0 ? 'disabled' : ''}>
                                        <span class="material-icons-round">check</span> Approve
                                    </button>
                                </div>
                            </div>
                        </div>
                    `;
        }).join('')}
                </div>
            </div>
            ` : ''}

            <!-- Create Trip (Admin auto-approved) -->
            <div class="card mb-6">
                <div class="card-header">
                    <h3><span class="material-icons-round" style="vertical-align:middle;margin-right:8px">add_circle</span>Buat Trip Baru (Auto-Approve)</h3>
                </div>
                <div class="card-body">
                    <form id="admin-trip-form">
                        <div class="form-row">
                            <div class="form-group">
                                <label class="form-label">Kendaraan</label>
                                <select class="form-select" id="at-vehicle" required>
                                    <option value="">Pilih kendaraan...</option>
                                    ${availableV.map(v => `<option value="${adminCarpoolToId(v.id)}">${adminCarpoolEsc(v.plate)} - ${adminCarpoolEsc(v.brand)}</option>`).join('')}
                                </select>
                            </div>
                            <div class="form-group">
                                <label class="form-label">Driver</label>
                                <select class="form-select" id="at-driver" required>
                                    <option value="">Pilih driver...</option>
                                    ${availableDrivers.map(d => `<option value="${adminCarpoolToId(d.id)}">${adminCarpoolEsc(d.name)} (${adminCarpoolEsc(d.nip)})</option>`).join('')}
                                </select>
                            </div>
                        </div>
                        <div class="form-row">
                            <div class="form-group">
                                <label class="form-label">Tanggal</label>
                                <input type="date" class="form-input" id="at-date" value="${new Date().toISOString().split('T')[0]}" required>
                            </div>
                            <div class="form-group">
                                <label class="form-label">Tujuan</label>
                                <input type="text" class="form-input" id="at-dest" placeholder="Tujuan" required>
                            </div>
                        </div>
                        <button type="submit" class="btn btn-primary" ${availableV.length === 0 ? 'disabled' : ''}>
                            <span class="material-icons-round">send</span> Buat Trip
                        </button>
                    </form>
                </div>
            </div>

            <!-- Kendaraan & Driver Management (Collapsed by default or Separate tabs? Keep simple for now) -->
            <div class="grid-2 mb-6">
                <!-- Kendaraan Section -->
                <div class="card">
                    <div class="card-header">
                        <h3><span class="material-icons-round" style="vertical-align:middle;margin-right:8px">directions_car</span>Kendaraan</h3>
                        <button class="btn btn-primary btn-sm" onclick="App.Pages.AdminCarpool.addVehicleModal()"><span class="material-icons-round">add</span></button>
                    </div>
                    <div class="card-body">
                         <div class="table-container" style="max-height:300px;overflow-y:auto">
                            <table>
                                <thead><tr><th>Plat</th><th>Status</th><th>Aksi</th></tr></thead>
                                <tbody>
                                    ${vehicles.map(v => `
                                        <tr>
                                            <td><strong>${adminCarpoolEsc(v.plate)}</strong><br><span style="font-size:11px;color:#888">${adminCarpoolEsc(v.brand)}</span></td>
                                            <td>${App.Pages.AdminCarpool.vehicleStatusBadge(v.status)}</td>
                                            <td><button class="btn btn-danger btn-sm" onclick="App.Pages.AdminCarpool.deleteVehicle(${adminCarpoolToId(v.id)})" ${v.status !== 'available' ? 'disabled' : ''}><span class="material-icons-round">delete</span></button></td>
                                        </tr>
                                    `).join('')}
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>

                <!-- Driver Section -->
                <div class="card">
                    <div class="card-header">
                        <h3><span class="material-icons-round" style="vertical-align:middle;margin-right:8px">person</span>Driver</h3>
                        <button class="btn btn-primary btn-sm" onclick="App.Pages.AdminCarpool.addDriverModal()"><span class="material-icons-round">add</span></button>
                    </div>
                    <div class="card-body">
                         <div class="table-container" style="max-height:300px;overflow-y:auto">
                            <table>
                                <thead><tr><th>Nama</th><th>NIP</th><th>Status</th><th>Aksi</th></tr></thead>
                                <tbody>
                                    ${drivers.map(d => {
            const isBusy = d.is_busy;
            return `
                                        <tr>
                                            <td><strong>${adminCarpoolEsc(d.name)}</strong></td>
                                            <td>${adminCarpoolEsc(d.nip)}</td>
                                            <td>${isBusy ? '<span class="badge badge-blue" style="font-size:10px">Bertugas</span>' : '<span class="badge badge-green" style="font-size:10px">Tersedia</span>'}</td>
                                            <td><button class="btn btn-danger btn-sm" onclick="App.Pages.AdminCarpool.deleteDriver(${adminCarpoolToId(d.id)})" ${isBusy ? 'disabled' : ''}><span class="material-icons-round">delete</span></button></td>
                                        </tr>
                                    `;
        }).join('')}
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>

            <!-- All Logs -->
            <div class="card">
                <div class="card-header"><h3>Log Trip</h3></div>
                <div class="card-body">
                    ${logs.length > 0 ? `
                        <p style="font-size:12px;color:var(--gray-500);margin-bottom:10px">Klik baris log untuk melihat detail lengkap.</p>
                        <div class="table-container">
                            <table>
                                <thead><tr><th>Tanggal</th><th>User</th><th>Kendaraan</th><th>Tujuan</th><th>Keluar</th><th>Masuk</th><th>Status</th></tr></thead>
                                <tbody>
                                    ${logs.map((l, idx) => {
            const fmtTime = (t) => t ? new Date(t).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }) : '-';
            return `
                                        <tr style="cursor:pointer" onclick="App.Pages.AdminCarpool.showLogDetail(${idx})">
                                            <td>${adminCarpoolEsc(App.formatDate(l.date))}</td>
                                            <td>${adminCarpoolEsc(l.user_name || '-')}</td>
                                            <td>${adminCarpoolEsc(l.vehicle_display || '-')}</td>
                                            <td>${adminCarpoolEsc(l.destination || '-')}</td>
                                            <td>${adminCarpoolEsc(fmtTime(l.trip_started_at))}</td>
                                            <td>${adminCarpoolEsc(fmtTime(l.key_returned_at))}</td>
                                            <td>${App.Pages.AdminCarpool.tripStatusBadge(l.status)}</td>
                                        </tr>`;
        }).join('')}
                                </tbody>
                            </table>
                        </div>
                    ` : '<div class="empty-state"><span class="material-icons-round">history</span><p>Belum ada log</p></div>'}
                </div>
            </div>
        `;

        document.getElementById('ac-filter-form').addEventListener('submit', (e) => {
            e.preventDefault();
            const filter_date = document.getElementById('f-date').value;
            const search = document.getElementById('f-search').value.trim();
            this.loadData({
                filter_date: filter_date || this.getTodayDate(),
                search
            });
        });

        // Handle Trip Creation Logic (re-attach listener)
        document.getElementById('admin-trip-form')?.addEventListener('submit', async (e) => {
            e.preventDefault();
            const data = {
                vehicle_id: document.getElementById('at-vehicle').value,
                driver_id: document.getElementById('at-driver').value,
                date: document.getElementById('at-date').value,
                destination: document.getElementById('at-dest').value.trim(),
            };
            if (!data.vehicle_id || !data.driver_id || !data.destination) { App.toast('Kendaraan, Driver, dan tujuan wajib diisi', 'warning'); return; }
            try {
                await App.Api.post('/carpool/logs', data);
                App.toast('Trip berhasil dibuat (auto-approved)!', 'success');
                this.loadData(); // Reload data
            } catch (err) { App.toast('Gagal: ' + err.message, 'error'); }
        });
    },

    exportData() {
        const date = document.getElementById('f-date')?.value || this.state.filter_date || this.getTodayDate();
        const search = document.getElementById('f-search')?.value?.trim();
        const query = {};
        if (date) {
            query.start_date = date;
            query.end_date = date;
        }
        if (search) query.search = search;

        App.Api.downloadFile('/export/carpool', query, 'laporan-carpool.pdf')
            .catch((e) => App.toast('Gagal export PDF: ' + e.message, 'error'));
    },

    vehicleStatusBadge(s) {
        const map = {
            available: ['badge-green', 'Available'],
            in_use: ['badge-blue', 'In Use'],
            pending_key: ['badge-yellow', 'Pending Key']
        };
        const [cls, lbl] = map[s] || ['badge-gray', s];
        const safeCls = adminCarpoolSafeBadgeClass(cls);
        return `<span class="badge ${safeCls}">${adminCarpoolEsc(lbl)}</span>`;
    },
    tripStatusMeta(s) {
        const map = {
            requested: ['badge-gray', 'Requested'],
            approved: ['badge-yellow', 'Approved'],
            confirmed: ['badge-blue', 'Confirmed'],
            in_use: ['badge-blue', 'In Use'],
            pending_key: ['badge-yellow', 'Pending Key'],
            completed: ['badge-green', 'Completed']
        };
        const [cls, lbl] = map[s] || ['badge-gray', s || '-'];
        return { cls, lbl };
    },
    tripStatusBadge(s) {
        const { cls, lbl } = this.tripStatusMeta(s);
        const safeCls = adminCarpoolSafeBadgeClass(cls);
        return `<span class="badge ${safeCls}">${adminCarpoolEsc(lbl)}</span>`;
    },

    showLogDetail(index) {
        const log = this.currentLogs[index];
        if (!log) {
            App.toast('Detail log tidak ditemukan', 'warning');
            return;
        }

        const { cls, lbl } = this.tripStatusMeta(log.status);
        const safeCls = adminCarpoolSafeBadgeClass(cls);
        const plannedTimes = [log.start_time, log.end_time]
            .map(v => (v ?? '').toString().trim())
            .filter(v => v && v !== '-' && v !== '--');
        const plannedTime = plannedTimes.length ? plannedTimes.join(' - ') : '-';
        const details = [
            ['Tanggal Trip', App.formatDate(log.date), false],
            ['Status', `<span class="badge ${safeCls}">${adminCarpoolEsc(lbl)}</span>`, true],
            ['Pemohon', log.user_name || '-', false],
            ['Penumpang', log.passenger_names || '-', false],
            ['Driver', log.driver_display || '-', false],
            ['Kendaraan', log.vehicle_display || '-', false],
            ['Tujuan', log.destination || '-', false],
            ['Jam Rencana', plannedTime, false],
            ['Trip Mulai', App.formatDateTime(log.trip_started_at), false],
            ['Trip Selesai', App.formatDateTime(log.trip_finished_at), false],
            ['Kunci Kembali', App.formatDateTime(log.key_returned_at), false],
            ['KM Terakhir', log.last_km || '-', false],
            ['Approved At', App.formatDateTime(log.approved_at), false],
            ['Approved By', log.approver_name || '-', false],
            ['Validator Kunci', log.validator_name || '-', false]
        ];

        App.openModal(`
            <div class="modal-header">
                <h3>Detail Log Trip</h3>
                <button class="modal-close" onclick="App.closeModal()"><span class="material-icons-round">close</span></button>
            </div>
            <div class="modal-body">
                <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:10px">
                    ${details.map(([label, value, isHtml]) => `
                        <div style="background:var(--gray-50);border:1px solid var(--gray-100);border-radius:10px;padding:10px 12px">
                            <div style="font-size:11px;color:var(--gray-500);font-weight:600;text-transform:uppercase">${adminCarpoolEsc(label)}</div>
                            <div style="margin-top:4px;font-size:14px;font-weight:600">${isHtml ? value : adminCarpoolEsc(value)}</div>
                        </div>
                    `).join('')}
                </div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-ghost" onclick="App.closeModal()">Tutup</button>
            </div>
        `);
    },

    async approve(logId) {
        if (!confirm('Approve trip ini?')) return;
        const vehicle_id = document.getElementById(`pa-vehicle-${logId}`)?.value;
        const driver_id = document.getElementById(`pa-driver-${logId}`)?.value;
        if (!vehicle_id || !driver_id) {
            App.toast('Pilih kendaraan dan driver terlebih dahulu', 'warning');
            return;
        }
        try {
            await App.Api.post(`/carpool/logs/${logId}/approve`, { vehicle_id, driver_id });
            App.toast('Trip berhasil di-approve!', 'success');
            this.loadData();
        } catch (e) { App.toast('Gagal: ' + e.message, 'error'); }
    },

    addVehicleModal() {
        App.openModal(`
            <div class="modal-header"><h3>Tambah Kendaraan</h3><button class="modal-close" onclick="App.closeModal()"><span class="material-icons-round">close</span></button></div>
            <div class="modal-body">
                <div class="form-group"><label class="form-label">Plat Nomor</label><input type="text" class="form-input" id="v-plate" placeholder="L 1234 WC" required></div>
                <div class="form-group"><label class="form-label">Merk</label><input type="text" class="form-input" id="v-brand" placeholder="XPANDER" required></div>
                <div class="form-group"><label class="form-label">KM Awal</label><input type="number" class="form-input" id="v-km" placeholder="0" value="0"></div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-ghost" onclick="App.closeModal()">Batal</button>
                <button class="btn btn-primary" onclick="App.Pages.AdminCarpool.submitVehicle()">Simpan</button>
            </div>
        `);
    },
    async submitVehicle() {
        const plate = document.getElementById('v-plate')?.value?.trim();
        const brand = document.getElementById('v-brand')?.value?.trim();
        const current_km = document.getElementById('v-km')?.value || 0;
        if (!plate || !brand) { App.toast('Plat dan Merk wajib diisi', 'warning'); return; }
        try {
            await App.Api.post('/carpool/vehicles', { plate, brand, current_km });
            App.closeModal(); App.toast('Kendaraan berhasil ditambahkan!', 'success'); this.loadData();
        } catch (e) { App.toast('Gagal: ' + e.message, 'error'); }
    },

    addDriverModal() {
        App.openModal(`
            <div class="modal-header"><h3>Tambah Driver</h3><button class="modal-close" onclick="App.closeModal()"><span class="material-icons-round">close</span></button></div>
            <div class="modal-body">
                <div class="form-group"><label class="form-label">Nama</label><input type="text" class="form-input" id="d-name" placeholder="Nama driver" required></div>
                <div class="form-group"><label class="form-label">NIP</label><input type="text" class="form-input" id="d-nip" placeholder="NIP driver" required></div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-ghost" onclick="App.closeModal()">Batal</button>
                <button class="btn btn-primary" onclick="App.Pages.AdminCarpool.submitDriver()">Simpan</button>
            </div>
        `);
    },
    async submitDriver() {
        const name = document.getElementById('d-name')?.value?.trim();
        const nip = document.getElementById('d-nip')?.value?.trim();
        if (!name || !nip) { App.toast('Nama dan NIP wajib diisi', 'warning'); return; }
        try {
            await App.Api.post('/carpool/drivers', { name, nip });
            App.closeModal(); App.toast('Driver berhasil ditambahkan!', 'success'); this.loadData();
        } catch (e) { App.toast('Gagal: ' + e.message, 'error'); }
    },

    async deleteVehicle(id) {
        if (!confirm('Hapus kendaraan ini?')) return;
        try { await App.Api.delete('/carpool/vehicles/' + id); App.toast('Kendaraan dihapus', 'success'); this.loadData(); }
        catch (e) { App.toast('Gagal: ' + e.message, 'error'); }
    },
    async deleteDriver(id) {
        if (!confirm('Hapus driver ini?')) return;
        try { await App.Api.delete('/carpool/drivers/' + id); App.toast('Driver dihapus', 'success'); this.loadData(); }
        catch (e) { App.toast('Gagal: ' + e.message, 'error'); }
    },
};




