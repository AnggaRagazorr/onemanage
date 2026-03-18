/**
 * Security Dashboard Page
 */
App.Router.register('/dashboard', async function () {
    App.renderLayout('Dashboard', 'Selamat datang, ' + App.Auth.getName(), `
        <div class="loading-placeholder" id="dash-loading">
            <span class="material-icons-round">autorenew</span>
            <p>Memuat data...</p>
        </div>
        <div id="dash-content" class="hidden"></div>
    `, 'dashboard');

    try {
        const [dashData, shiftData] = await Promise.all([
            App.Api.get('/dashboard').catch(() => ({})),
            App.Api.get('/shifts/current').catch(() => ({})),
        ]);

        const stats = dashData || {};
        const shiftRes = shiftData || {};
        const isActive = shiftRes.is_active || false;
        const shift = shiftRes.shift || {};

        const loading = document.getElementById('dash-loading');
        const content = document.getElementById('dash-content');
        if (!loading || !content) return;
        loading.classList.add('hidden');
        content.classList.remove('hidden');

        content.innerHTML = `
            <div class="shift-card mb-6">
                <h3><span class="material-icons-round" style="vertical-align:middle;margin-right:8px">schedule</span>Manajemen Shift</h3>
                <div class="shift-status" id="shift-status">
                    <span class="shift-status-dot ${isActive ? '' : 'inactive'}"></span>
                    <div>
                        ${isActive
                ? `<strong>Shift ${shift.shift_type === 'pagi' ? 'Pagi' : 'Malam'}</strong><br><small>Clock In: ${App.formatTime(shift.clock_in)}</small>`
                : '<strong>Belum Clock In</strong><br><small>Pilih shift untuk memulai</small>'
            }
                    </div>
                </div>
                <div class="shift-btns" id="shift-btns">
                    ${isActive
                ? `<button class="shift-btn shift-btn-out" onclick="App.Pages.Dashboard.clockOut()">
                             <span class="material-icons-round" style="vertical-align:middle;margin-right:4px">logout</span> Clock Out
                           </button>`
                : `<button class="shift-btn shift-btn-morning" onclick="App.Pages.Dashboard.clockIn('pagi')">
                             <span class="material-icons-round" style="vertical-align:middle;margin-right:4px">wb_sunny</span> Shift Pagi
                           </button>
                           <button class="shift-btn shift-btn-night" onclick="App.Pages.Dashboard.clockIn('malam')">
                             <span class="material-icons-round" style="vertical-align:middle;margin-right:4px">nights_stay</span> Shift Malam
                           </button>`
            }
                </div>
            </div>

            <div class="grid-3 mb-6">
                <div class="stat-card blue">
                    <div class="stat-icon"><span class="material-icons-round">shield</span></div>
                    <div class="stat-info">
                        <div class="stat-value">${stats.patrol_today ?? 0} / ${stats.patrol_target ?? 3}</div>
                        <div class="stat-label">Patroli Hari Ini</div>
                    </div>
                </div>
                <div class="stat-card green">
                    <div class="stat-icon"><span class="material-icons-round">receipt_long</span></div>
                    <div class="stat-info">
                        <div class="stat-value">${stats.rekap_today ?? 0}</div>
                        <div class="stat-label">Rekap Hari Ini</div>
                    </div>
                </div>
                <div class="stat-card yellow">
                    <div class="stat-icon"><span class="material-icons-round">directions_car</span></div>
                    <div class="stat-info">
                        <div class="stat-value">${stats.carpool_available ?? 0} / ${stats.carpool_total ?? 0}</div>
                        <div class="stat-label">Carpool Tersedia</div>
                    </div>
                </div>
            </div>

            <div class="card">
                <div class="card-header"><h3>Aksi Cepat</h3></div>
                <div class="card-body" style="display:flex; gap:12px; flex-wrap:wrap;">
                    <button class="btn btn-primary" onclick="App.Router.navigate('/patrol')">
                        <span class="material-icons-round">qr_code_scanner</span> Mulai Patroli
                    </button>
                    <button class="btn btn-outline" onclick="App.Router.navigate('/rekap')">
                        <span class="material-icons-round">edit_note</span> Buat Rekap
                    </button>
                    <button class="btn btn-outline" onclick="App.Router.navigate('/carpool')">
                        <span class="material-icons-round">directions_car</span> Carpool
                    </button>
                </div>
            </div>
        `;
    } catch (err) {
        const loading = document.getElementById('dash-loading');
        if (loading) loading.innerHTML = '<p>Gagal memuat data</p>';
    }
});
