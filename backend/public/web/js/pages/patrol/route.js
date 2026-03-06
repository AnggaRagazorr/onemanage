const {
    PATROL_AREAS,
    PATROL_ROUNDS_PER_SHIFT,
    PATROL_TARGET_PER_SHIFT,
    normalizePatrolArea,
    isTodayDate,
} = App.PatrolCore;

App.Router.register('/patrol', async function () {
    App.renderLayout('Patroli', 'Scan QR code di area patroli', `
        <div class="loading-placeholder" id="patrol-loading">
            <span class="material-icons-round">autorenew</span>
            <p>Memuat data patroli...</p>
        </div>
        <div id="patrol-content" class="hidden"></div>
    `, 'patrol');

    try {
        const [patrolsRes, conditionsRes] = await Promise.all([
            App.Api.get('/patrols').catch(() => ({ data: [] })),
            App.Api.get('/patrol-conditions').catch(() => ({ data: [] })),
        ]);

        const patrols = patrolsRes.data || patrolsRes || [];
        const conditions = conditionsRes.data || conditionsRes || [];
        const todayPatrols = (Array.isArray(patrols) ? patrols : [])
            .filter((p) => isTodayDate(p.captured_at || p.created_at));

        const areaCounts = PATROL_AREAS.reduce((acc, area) => {
            acc[area] = 0;
            return acc;
        }, {});

        todayPatrols
            .slice()
            .sort((a, b) => new Date(a.captured_at || a.created_at) - new Date(b.captured_at || b.created_at))
            .forEach((p) => {
                const normalized = normalizePatrolArea(p.area || p.barcode || '');
                if (PATROL_AREAS.includes(normalized)) {
                    areaCounts[normalized] += 1;
                }
            });

        const completedByArea = PATROL_AREAS.reduce((acc, area) => {
            acc[area] = Math.min(areaCounts[area], PATROL_ROUNDS_PER_SHIFT);
            return acc;
        }, {});

        const completedScans = PATROL_AREAS.reduce((sum, area) => sum + completedByArea[area], 0);
        const remainingScans = Math.max(0, PATROL_TARGET_PER_SHIFT - completedScans);
        const progress = Math.min(100, Math.round((completedScans / PATROL_TARGET_PER_SHIFT) * 100));
        const bonusPoint = completedScans >= PATROL_TARGET_PER_SHIFT ? 3 : 0;
        const totalPoint = completedScans + bonusPoint;

        const loading = document.getElementById('patrol-loading');
        const content = document.getElementById('patrol-content');
        if (!loading || !content) return;
        loading.classList.add('hidden');
        content.classList.remove('hidden');

        content.innerHTML = `
            <div class="card mb-6">
                <div class="card-header">
                    <h3>Target Patroli Shift 12 Jam</h3>
                    <span class="badge badge-blue">4 Ronde x 3 Area</span>
                </div>
                <div class="card-body">
                    <div class="grid-4 mb-4">
                        <div class="stat-card blue">
                            <div class="stat-body">
                                <div class="stat-info">
                                    <div class="stat-value">${PATROL_TARGET_PER_SHIFT}</div>
                                    <div class="stat-label">Target Patroli</div>
                                </div>
                            </div>
                        </div>
                        <div class="stat-card green">
                            <div class="stat-body">
                                <div class="stat-info">
                                    <div class="stat-value">${completedScans}</div>
                                    <div class="stat-label">Tercapai Hari Ini</div>
                                </div>
                            </div>
                        </div>
                        <div class="stat-card yellow">
                            <div class="stat-body">
                                <div class="stat-info">
                                    <div class="stat-value">${remainingScans}</div>
                                    <div class="stat-label">Sisa Target</div>
                                </div>
                            </div>
                        </div>
                        <div class="stat-card info">
                            <div class="stat-body">
                                <div class="stat-info">
                                    <div class="stat-value">${totalPoint}</div>
                                    <div class="stat-label">Poin Shift</div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="flex-between mb-4">
                        <div>
                            <h3 style="font-size:18px;font-weight:700">Progress Patroli</h3>
                            <p style="font-size:13px;color:var(--gray-500);margin-top:2px">
                                Wajib 4 kali patroli untuk tiap area: Area Luar, Area Balkon, Area Smoking
                            </p>
                        </div>
                        <div style="font-size:28px;font-weight:800;color:var(--primary)">${progress}%</div>
                    </div>
                    <div class="progress-bar">
                        <div class="progress-fill" style="width:${progress}%"></div>
                    </div>
                    <p style="font-size:12px;color:var(--gray-500);margin-top:10px">
                        Skema poin: 1 poin tiap patroli valid, bonus 3 poin jika target 12 patroli tercapai.
                    </p>
                    <div class="table-container mt-4">
                        <table>
                            <thead>
                                <tr>
                                    <th>Ronde</th>
                                    ${PATROL_AREAS.map((area) => `<th>${area}</th>`).join('')}
                                </tr>
                            </thead>
                            <tbody>
                                ${Array.from({ length: PATROL_ROUNDS_PER_SHIFT }, (_, idx) => {
            const round = idx + 1;
            return `
                                        <tr>
                                            <td>Ronde ${round}</td>
                                            ${PATROL_AREAS.map((area) => {
                const done = completedByArea[area] >= round;
                const badgeClass = done ? 'badge-green' : 'badge-gray';
                const badgeText = done ? 'Selesai' : 'Belum';
                return `<td><span class="badge ${badgeClass}">${badgeText}</span></td>`;
            }).join('')}
                                        </tr>
                                    `;
        }).join('')}
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>

            <div class="card mb-6">
                <div class="card-header">
                    <h3>Progress Per Area</h3>
                </div>
                <div class="card-body">
                    ${PATROL_AREAS.map((area) => {
            const count = completedByArea[area];
            const areaProgress = Math.round((count / PATROL_ROUNDS_PER_SHIFT) * 100);
            return `
                            <div style="margin-bottom:14px">
                                <div class="flex-between" style="margin-bottom:6px">
                                    <div style="font-weight:600">${area}</div>
                                    <div style="font-size:13px;color:var(--gray-600)">${count}/${PATROL_ROUNDS_PER_SHIFT}</div>
                                </div>
                                <div class="progress-bar" style="height:8px">
                                    <div class="progress-fill" style="width:${areaProgress}%"></div>
                                </div>
                            </div>
                        `;
        }).join('')}
                </div>
            </div>

            <div class="card mb-6">
                <div class="card-header">
                    <h3><span class="material-icons-round" style="vertical-align:middle;margin-right:8px">qr_code_scanner</span>Scan QR</h3>
                    <div style="display:flex;gap:6px;flex-wrap:wrap">
                        <button class="btn btn-outline btn-sm hidden" id="btn-switch-scan-camera" onclick="App.Pages.Patrol.switchScanCamera()" title="Ganti kamera">
                            <span class="material-icons-round">cameraswitch</span> Depan
                        </button>
                        <button class="btn btn-primary btn-sm" id="btn-start-scan" onclick="App.Pages.Patrol.toggleScanner()">
                            <span class="material-icons-round">camera_alt</span> Buka Kamera
                        </button>
                    </div>
                </div>
                <div class="card-body hidden" id="qr-scan-panel">
                    <div id="qr-scanner-area" class="hidden">
                        <div class="qr-scanner-container">
                            <div id="qr-reader"></div>
                        </div>
                        <p style="text-align:center;margin-top:8px;font-size:12px;color:var(--gray-500)">
                            Arahkan kamera ke QR area patroli
                        </p>
                    </div>
                </div>
            </div>

            <div class="card mb-6">
                <div class="card-header">
                    <h3>Laporan Kondisi Area</h3>
                    <button class="btn btn-outline btn-sm" onclick="App.Pages.Patrol.openConditionForm()">
                        <span class="material-icons-round">add</span> Buat Laporan
                    </button>
                </div>
                <div class="card-body">
                    ${Array.isArray(conditions) && conditions.length > 0 ? `
                        <div class="table-container">
                            <table>
                                <thead><tr>
                                    <th>Tanggal</th><th>Waktu</th><th>Situasi</th><th>Cuaca</th>
                                </tr></thead>
                                <tbody>
                                    ${conditions.map(c => `
                                        <tr>
                                            <td>${App.formatDate(c.date)}</td>
                                            <td>${c.time || '-'}</td>
                                            <td>${c.situasi || '-'}</td>
                                            <td>${c.cuaca || '-'}</td>
                                        </tr>
                                    `).join('')}
                                </tbody>
                            </table>
                        </div>
                    ` : `
                        <div class="empty-state">
                            <span class="material-icons-round">description</span>
                            <p>Belum ada laporan kondisi</p>
                        </div>
                    `}
                </div>
            </div>

            <div class="card">
                <div class="card-header"><h3>Riwayat Patroli Hari Ini</h3></div>
                <div class="card-body">
                    ${todayPatrols.length > 0 ? `
                        <div class="table-container">
                            <table>
                                <thead><tr>
                                    <th>Waktu</th><th>Area</th><th>Status QR</th><th>Foto</th>
                                </tr></thead>
                                <tbody>
                                    ${todayPatrols.map((p) => {
            const isVerified = (p.barcode || '').includes('|');
            return `
                                        <tr>
                                            <td>${App.formatDateTime(p.captured_at || p.created_at)}</td>
                                            <td>${p.area || '-'}</td>
                                            <td><span class="badge ${isVerified ? 'badge-green' : 'badge-gray'}">${isVerified ? 'Terverifikasi' : 'Manual'}</span></td>
                                            <td>${p.photo_count || 0} foto</td>
                                        </tr>
                                    `}).join('')}
                                </tbody>
                            </table>
                        </div>
                    ` : `
                        <div class="empty-state">
                            <span class="material-icons-round">shield</span>
                            <p>Belum ada patroli hari ini</p>
                        </div>
                    `}
                </div>
            </div>
        `;
        App.Pages.Patrol.updateScanSwitchButton();
    } catch (err) {
        const loading = document.getElementById('patrol-loading');
        if (loading) loading.innerHTML = '<p>Gagal memuat data patroli</p>';
    }
});

