App.Pages = App.Pages || {};
App.Pages.AdminDashboard = {
    async loadData() {
        const loading = document.getElementById('adash-loading');
        const content = document.getElementById('adash-content');
        if (loading) loading.classList.remove('hidden');
        if (content) content.classList.add('hidden');

        try {
            const [pendingApprovalRes, inUseTripsRes, pendingKeyTripsRes, kmAlertsRes, activeShiftsRes] = await Promise.all([
                App.Api.get('/carpool/logs?status=requested').catch(() => ({ data: [] })),
                App.Api.get('/carpool/logs?status=in_use').catch(() => ({ data: [] })),
                App.Api.get('/carpool/logs?status=pending_key').catch(() => ({ data: [] })),
                App.Api.get('/km-audits/alerts').catch(() => ({ data: [] })),
                App.Api.get('/admin/shifts/active').catch(() => ({ data: [], total_active: 0 })),
            ]);

            this.render({
                pendingApprovalRes,
                inUseTripsRes,
                pendingKeyTripsRes,
                kmAlertsRes,
                activeShiftsRes
            });
        } catch (err) {
            if (loading) loading.innerHTML = '<p>Gagal memuat data dashboard</p>';
        }
    },

    render(data) {
        const mapRows = (res) => Array.isArray(res) ? res : (res.data || []);
        const esc = App.escapeHtml || ((v) => String(v ?? ''));
        const pendingApproval = mapRows(data.pendingApprovalRes);
        const inUseTrips = mapRows(data.inUseTripsRes);
        const pendingKeyTrips = mapRows(data.pendingKeyTripsRes);
        const kmAlerts = mapRows(data.kmAlertsRes);

        const pendingCount = Array.isArray(pendingApproval) ? pendingApproval.length : 0;
        const inUseCount = Array.isArray(inUseTrips) ? inUseTrips.length : 0;
        const pendingKeyCount = Array.isArray(pendingKeyTrips) ? pendingKeyTrips.length : 0;

        const todayIso = new Date().toISOString().slice(0, 10);
        const kmAlertToday = kmAlerts.filter((a) => ((a.date || '').toString().slice(0, 10) === todayIso)).length;

        const loading = document.getElementById('adash-loading');
        const content = document.getElementById('adash-content');
        if (loading) loading.classList.add('hidden');
        if (content) content.classList.remove('hidden');
        if (!content) return;

        const activeShifts = mapRows(data.activeShiftsRes);
        const totalActive = data.activeShiftsRes?.total_active ?? activeShifts.length;

        content.innerHTML = `
            <div class="card mb-6" style="border-left:4px solid var(--success)">
                <div class="card-header">
                    <h3>
                        <span class="material-icons-round" style="vertical-align:middle;margin-right:8px;color:var(--success)">shield</span>
                        Security Sedang Bertugas
                    </h3>
                    <span class="badge ${totalActive > 0 ? 'badge-green' : 'badge-red'}">
                        ${totalActive} Aktif
                    </span>
                </div>
                <div class="card-body">
                    ${totalActive > 0 ? `
                        <div class="grid-3">
                            ${activeShifts.map((s) => `
                                <div class="area-card" style="cursor:default;position:relative">
                                    <div class="area-icon" style="background:${s.shift_type === 'pagi' ? 'var(--warning-light)' : '#312E81'};color:${s.shift_type === 'pagi' ? 'var(--warning)' : '#A5B4FC'}">
                                        <span class="material-icons-round">${s.shift_type === 'pagi' ? 'wb_sunny' : 'nights_stay'}</span>
                                    </div>
                                    <div class="area-info">
                                        <div class="area-title" style="display:flex;align-items:center;gap:6px">
                                            <span style="width:8px;height:8px;border-radius:50%;background:#22C55E;display:inline-block;animation:pulse-dot 1.5s ease-in-out infinite"></span>
                                            ${App.escapeHtml ? App.escapeHtml(s.name) : s.name}
                                        </div>
                                        <div class="area-sub">
                                            <span class="badge ${s.shift_type === 'pagi' ? 'badge-yellow' : 'badge-blue'}" style="font-size:11px;padding:2px 8px">
                                                ${s.shift_type === 'pagi' ? 'Pagi' : 'Malam'}
                                            </span>
                                            &nbsp;·&nbsp; Clock In: ${App.formatTime ? App.formatTime(s.clock_in) : new Date(s.clock_in).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' })}
                                        </div>
                                    </div>
                                </div>
                            `).join('')}
                        </div>
                    ` : `
                        <div class="empty-state" style="padding:22px 12px">
                            <span class="material-icons-round" style="font-size:40px;color:var(--gray-400)">person_off</span>
                            <p>Tidak ada security yang sedang bertugas saat ini</p>
                        </div>
                    `}
                </div>
            </div>

            <div class="grid-4 mb-6">
                <div class="stat-card yellow">
                    <div class="stat-icon"><span class="material-icons-round">pending_actions</span></div>
                    <div class="stat-info">
                        <div class="stat-value">${pendingCount}</div>
                        <div class="stat-label">Approval Menunggu</div>
                    </div>
                </div>
                <div class="stat-card blue">
                    <div class="stat-icon"><span class="material-icons-round">directions_car</span></div>
                    <div class="stat-info">
                        <div class="stat-value">${inUseCount}</div>
                        <div class="stat-label">Trip Sedang Berjalan</div>
                    </div>
                </div>
                <div class="stat-card yellow">
                    <div class="stat-icon"><span class="material-icons-round">vpn_key</span></div>
                    <div class="stat-info">
                        <div class="stat-value">${pendingKeyCount}</div>
                        <div class="stat-label">Menunggu Validasi Kunci</div>
                    </div>
                </div>
                <div class="stat-card red">
                    <div class="stat-icon"><span class="material-icons-round">warning</span></div>
                    <div class="stat-info">
                        <div class="stat-value">${kmAlertToday}</div>
                        <div class="stat-label">Alert Audit KM Hari Ini</div>
                    </div>
                </div>
            </div>

            <div class="card mb-6" style="border-left:4px solid var(--warning)">
                <div class="card-header">
                    <h3>
                        <span class="material-icons-round" style="vertical-align:middle;margin-right:8px;color:var(--warning)">pending_actions</span>
                        Approval Carpool
                    </h3>
                    <span class="badge ${pendingCount > 0 ? 'badge-yellow' : 'badge-green'}">
                        ${pendingCount} Menunggu
                    </span>
                </div>
                <div class="card-body">
                    ${pendingCount > 0 ? `
                        <div class="table-container">
                            <table>
                                <thead>
                                    <tr>
                                        <th>Tanggal</th>
                                        <th>Pemohon</th>
                                        <th>Tujuan</th>
                                        <th>Jam</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    ${pendingApproval.slice(0, 5).map((trip) => `
                                        <tr>
                                            <td>${App.formatDate(trip.date)}</td>
                                            <td>${esc(trip.user_name || '-')}</td>
                                            <td>${esc(trip.destination || '-')}</td>
                                            <td>${esc(trip.start_time || '-')}</td>
                                        </tr>
                                    `).join('')}
                                </tbody>
                            </table>
                        </div>
                        <div style="margin-top:12px;display:flex;justify-content:flex-end">
                            <button class="btn btn-primary btn-sm" onclick="App.Router.navigate('/admin/carpool')">
                                <span class="material-icons-round">fact_check</span> Buka Approval
                            </button>
                        </div>
                    ` : `
                        <div class="empty-state" style="padding:22px 12px">
                            <span class="material-icons-round" style="font-size:40px">task_alt</span>
                            <p>Tidak ada request carpool yang menunggu approval</p>
                        </div>
                    `}
                </div>
            </div>

            <div class="card">
                <div class="card-header"><h3>Aksi Cepat Admin</h3></div>
                <div class="card-body" style="display:flex; gap:12px; flex-wrap:wrap;">
                    <button class="btn btn-primary" onclick="App.Router.navigate('/admin/patrol')">
                        <span class="material-icons-round">shield</span> Data Patroli
                    </button>
                    <button class="btn btn-outline" onclick="App.Router.navigate('/admin/carpool')">
                        <span class="material-icons-round">directions_car</span> Carpool
                    </button>
                    <button class="btn btn-outline" onclick="App.Router.navigate('/admin/users')">
                        <span class="material-icons-round">group</span> Manajemen User
                    </button>
                </div>
            </div>
        `;
    }
};
