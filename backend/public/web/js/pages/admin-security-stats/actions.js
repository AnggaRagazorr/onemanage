App.Pages = App.Pages || {};
App.Pages.AdminSecurityStats = {
    shiftState: { filter_date: '', search: '' },

    getTodayDate() {
        return new Date().toISOString().split('T')[0];
    },

    async loadData() {
        const loading = document.getElementById('as-loading');
        const content = document.getElementById('as-content');
        if (loading) loading.classList.remove('hidden');
        if (content) content.classList.add('hidden');

        try {
            if (!this.shiftState.filter_date) {
                this.shiftState.filter_date = this.getTodayDate();
            }
            const shiftQuery = new URLSearchParams({
                start_date: this.shiftState.filter_date,
                end_date: this.shiftState.filter_date,
                ...(this.shiftState.search ? { search: this.shiftState.search } : {}),
            }).toString();

            const [statsRes, activeRes, shiftRes] = await Promise.all([
                App.Api.get('/admin/security-stats').catch(() => []),
                App.Api.get('/admin/shifts/active').catch(() => ({ data: [], total_active: 0 })),
                App.Api.get(`/admin/shifts/history?${shiftQuery}`).catch(() => ({ data: [] })),
            ]);

            const stats = statsRes.data || statsRes || [];
            const activeShifts = Array.isArray(activeRes.data) ? activeRes.data : [];
            const totalActive = activeRes.total_active ?? activeShifts.length;
            const shifts = Array.isArray(shiftRes) ? shiftRes : (shiftRes.data || []);

            this.render(stats, { activeShifts, totalActive, shifts });
        } catch (err) {
            if (loading) loading.innerHTML = '<p>Gagal memuat data statistik</p>';
        }
    },

    render(stats, shiftData) {
        const loading = document.getElementById('as-loading');
        const content = document.getElementById('as-content');
        if (loading) loading.classList.add('hidden');
        if (content) content.classList.remove('hidden');
        if (!content) return;

        const esc = App.escapeHtml || ((v) => String(v ?? ''));
        const { activeShifts, totalActive, shifts } = shiftData;

        if (!Array.isArray(stats) || stats.length === 0) {
            content.innerHTML = '<div class="empty-state"><span class="material-icons-round">bar_chart</span><p>Belum ada data statistik</p></div>';
            return;
        }

        const rows = stats
            .map((s) => ({
                id: s.id,
                name: s.name || '-',
                isWorking: !!s.is_working,
                patrolToday: s.patrol_count_today ?? 0,
                patrolMonth: s.patrol_count_month ?? 0,
                score: s.score_percentage ?? 0,
                lastActivity: s.last_activity || null,
            }))
            .sort((a, b) => b.score - a.score);

        const totalSecurity = rows.length;
        const activeNow = rows.filter((r) => r.isWorking).length;
        const totalPatrolToday = rows.reduce((sum, r) => sum + r.patrolToday, 0);
        const avgScore = Math.round(rows.reduce((sum, r) => sum + r.score, 0) / totalSecurity);
        const topPerformer = rows.filter((r) => r.score >= 80).length;

        const fmtDateTime = (dt) => {
            if (!dt) return '-';
            const d = new Date(dt);
            return d.toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' }) +
                ' ' + d.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' });
        };

        const fmtDuration = (minutes) => {
            if (minutes === null || minutes === undefined) return '-';
            const safeMinutes = Math.abs(Number(minutes) || 0);
            const h = Math.floor(safeMinutes / 60);
            const m = safeMinutes % 60;
            return h > 0 ? `${h}j ${m}m` : `${m}m`;
        };

        content.innerHTML = `
            <div class="grid-4 mb-6">
                <div class="stat-card blue">
                    <div class="stat-icon"><span class="material-icons-round">group</span></div>
                    <div class="stat-info">
                        <div class="stat-value">${totalSecurity}</div>
                        <div class="stat-label">Total Security</div>
                    </div>
                </div>
                <div class="stat-card green">
                    <div class="stat-icon"><span class="material-icons-round">badge</span></div>
                    <div class="stat-info">
                        <div class="stat-value">${activeNow}</div>
                        <div class="stat-label">Sedang Bertugas</div>
                    </div>
                </div>
                <div class="stat-card yellow">
                    <div class="stat-icon"><span class="material-icons-round">shield</span></div>
                    <div class="stat-info">
                        <div class="stat-value">${totalPatrolToday}</div>
                        <div class="stat-label">Total Patroli Hari Ini</div>
                    </div>
                </div>
                <div class="stat-card ${avgScore >= 80 ? 'green' : avgScore >= 50 ? 'yellow' : 'red'}">
                    <div class="stat-icon"><span class="material-icons-round">emoji_events</span></div>
                    <div class="stat-info">
                        <div class="stat-value">${avgScore}%</div>
                        <div class="stat-label">Rata-rata Skor Bulanan</div>
                    </div>
                </div>
            </div>

            <!-- Currently Active Shifts -->
            ${totalActive > 0 ? `
            <div class="card mb-6" style="border-left:4px solid var(--success)">
                <div class="card-header">
                    <h3>
                        <span class="material-icons-round" style="vertical-align:middle;margin-right:8px;color:var(--success)">shield</span>
                        Sedang Bertugas Sekarang
                    </h3>
                    <span class="badge badge-green">${totalActive} Aktif</span>
                </div>
                <div class="card-body">
                    <div style="display:flex;gap:12px;flex-wrap:wrap">
                        ${activeShifts.map((s) => `
                            <div style="background:var(--glass-bg);border:1px solid var(--glass-border);border-radius:12px;padding:12px 16px;display:flex;align-items:center;gap:10px;min-width:200px">
                                <span style="width:8px;height:8px;border-radius:50%;background:#22C55E;display:inline-block;animation:pulse-dot 1.5s ease-in-out infinite"></span>
                                <div>
                                    <div style="font-weight:700;font-size:14px">${esc(s.name)}</div>
                                    <div style="font-size:12px;color:var(--gray-500)">
                                        ${s.shift_type === 'pagi' ? '☀️ Pagi' : '🌙 Malam'} · ${esc(s.clock_in || '-')}
                                    </div>
                                </div>
                            </div>
                        `).join('')}
                    </div>
                </div>
            </div>
            ` : ''}

            <div class="card mb-6">
                <div class="card-header">
                    <h3>Ringkasan Performa</h3>
                    <span class="badge ${topPerformer > 0 ? 'badge-green' : 'badge-gray'}">${topPerformer} top performer</span>
                </div>
                <div class="card-body">
                    <p style="font-size:13px;color:var(--gray-600)">
                        Skor dihitung dari konsistensi patroli bulanan dengan bonus pencapaian target harian (4 ronde x 3 area).
                    </p>
                </div>
            </div>

            <div class="card mb-6">
                <div class="card-header"><h3>Ranking Security</h3></div>
                <div class="card-body">
                    <div class="table-container">
                        <table>
                            <thead>
                                <tr>
                                    <th>Rank</th>
                                    <th>Nama</th>
                                    <th>Status</th>
                                    <th>Patroli Hari Ini</th>
                                    <th>Patroli Bulan Ini</th>
                                    <th>Skor Bulanan</th>
                                    <th>Aktivitas Terakhir</th>
                                    <th>Aksi</th>
                                </tr>
                            </thead>
                            <tbody>
                                ${rows.map((r, idx) => {
            const badge = r.isWorking
                ? '<span class="badge badge-green">On Duty</span>'
                : '<span class="badge badge-gray">Off Duty</span>';
            const scoreColor = r.score >= 80
                ? 'var(--accent)'
                : (r.score >= 50 ? 'var(--warning)' : 'var(--danger)');

            return `
                                        <tr>
                                            <td><strong>#${idx + 1}</strong></td>
                                            <td>${r.name}</td>
                                            <td>${badge}</td>
                                            <td>${r.patrolToday}</td>
                                            <td>${r.patrolMonth}</td>
                                            <td><span style="font-weight:700;color:${scoreColor}">${r.score}%</span></td>
                                            <td>${r.lastActivity ? App.formatDateTime(r.lastActivity) : '-'}</td>
                                            <td>
                                                <button class="btn btn-sm btn-outline" onclick="App.Pages.AdminSecurityStats.showDetail(${r.id})">
                                                    <span class="material-icons-round">visibility</span> Detail
                                                </button>
                                            </td>
                                        </tr>
                                    `;
        }).join('')}
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>

            <!-- Shift History -->
            <div class="card">
                <div class="card-header">
                    <h3>
                        <span class="material-icons-round" style="vertical-align:middle;margin-right:8px">history</span>
                        Riwayat Shift
                    </h3>
                    <span class="badge badge-blue">${shifts.length} record</span>
                </div>
                <div class="card-body">
                    <form id="ash-filter-form" style="display:flex;gap:12px;align-items:flex-end;flex-wrap:wrap;margin-bottom:16px">
                        <div class="form-group" style="margin-bottom:0;flex:1;min-width:150px">
                            <label class="form-label">Tanggal</label>
                            <input type="date" class="form-input" id="ash-date" value="${esc(this.shiftState.filter_date || '')}">
                        </div>
                        <div class="form-group" style="margin-bottom:0;flex:1;min-width:200px">
                            <label class="form-label">Cari (Nama/Username)</label>
                            <input type="text" class="form-input" id="ash-search" placeholder="Cari..." value="${esc(this.shiftState.search || '')}">
                        </div>
                        <button type="submit" class="btn btn-primary" style="height:42px">
                            <span class="material-icons-round">filter_list</span> Filter
                        </button>
                    </form>

                    ${shifts.length > 0 ? `
                        <div class="table-container">
                            <table>
                                <thead>
                                    <tr>
                                        <th>Nama</th>
                                        <th>Shift</th>
                                        <th>Clock In</th>
                                        <th>Clock Out</th>
                                        <th>Durasi</th>
                                        <th>Status</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    ${shifts.map((s) => {
            const shiftBadge = s.shift_type === 'pagi'
                ? '<span class="badge badge-yellow" style="font-size:11px">☀️ Pagi</span>'
                : '<span class="badge badge-blue" style="font-size:11px">🌙 Malam</span>';
            const statusBadge = s.is_active
                ? '<span class="badge badge-green" style="font-size:11px"><span style="width:6px;height:6px;border-radius:50%;background:#22C55E;display:inline-block;animation:pulse-dot 1.5s ease-in-out infinite;margin-right:4px"></span>Aktif</span>'
                : '<span class="badge badge-gray" style="font-size:11px">Selesai</span>';
            return `
                                    <tr>
                                        <td>
                                            <strong>${esc(s.name)}</strong>
                                            <br><span style="font-size:11px;color:#888">@${esc(s.username)}</span>
                                        </td>
                                        <td>${shiftBadge}</td>
                                        <td>${esc(s.clock_in || '-')}</td>
                                        <td>${esc(s.clock_out || '-')}</td>
                                        <td>${esc(fmtDuration(s.duration))}</td>
                                        <td>${statusBadge}</td>
                                    </tr>`;
        }).join('')}
                                </tbody>
                            </table>
                        </div>
                    ` : `
                        <div class="empty-state">
                            <span class="material-icons-round">event_busy</span>
                            <p>Tidak ada data shift untuk tanggal ini</p>
                        </div>
                    `}
                </div>
            </div>
        `;

        // Shift filter form
        document.getElementById('ash-filter-form')?.addEventListener('submit', (e) => {
            e.preventDefault();
            this.shiftState.filter_date = document.getElementById('ash-date').value || this.getTodayDate();
            this.shiftState.search = document.getElementById('ash-search').value.trim();
            this.loadData();
        });
    },

    async showDetail(userId) {
        try {
            const res = await App.Api.get('/admin/security-stats/' + userId);
            const data = res.data || res || {};
            const score = data.score_percentage ?? 0;
            const color = score >= 80 ? 'var(--accent)' : score >= 50 ? 'var(--warning)' : 'var(--danger)';
            const areaEntries = Object.entries(data.patrol_by_area_today || {});
            const breakdown = data.score_breakdown || {};

            App.openModal(`
                <div class="modal-header">
                    <h3>Detail Security</h3>
                    <button class="modal-close" onclick="App.closeModal()"><span class="material-icons-round">close</span></button>
                </div>
                <div class="modal-body">
                    <div style="text-align:center;margin-bottom:20px">
                        <div class="score-circle" style="background:${color}20;color:${color};width:80px;height:80px;font-size:24px;margin:0 auto 12px">
                            ${score}%
                        </div>
                        <h3 style="font-size:18px">${data.name || '-'}</h3>
                        <span class="badge ${data.is_working ? 'badge-green' : 'badge-gray'}">${data.is_working ? 'On Duty' : 'Off Duty'}</span>
                    </div>

                    <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px">
                        <div style="background:var(--gray-50);padding:14px;border-radius:var(--radius)">
                            <div style="font-size:12px;color:var(--gray-500);font-weight:600">Total Patroli</div>
                            <div style="font-size:22px;font-weight:800;color:var(--primary)">${data.patrol_count_month ?? 0}</div>
                        </div>
                        <div style="background:var(--gray-50);padding:14px;border-radius:var(--radius)">
                            <div style="font-size:12px;color:var(--gray-500);font-weight:600">Patroli Minggu Ini</div>
                            <div style="font-size:22px;font-weight:800;color:var(--accent)">${data.patrol_count_week ?? 0}</div>
                        </div>
                        <div style="background:var(--gray-50);padding:14px;border-radius:var(--radius)">
                            <div style="font-size:12px;color:var(--gray-500);font-weight:600">Patroli Hari Ini</div>
                            <div style="font-size:22px;font-weight:800;color:var(--warning)">${data.patrol_count_today ?? 0}</div>
                        </div>
                        <div style="background:var(--gray-50);padding:14px;border-radius:var(--radius)">
                            <div style="font-size:12px;color:var(--gray-500);font-weight:600">Hari Aktif Bulan Ini</div>
                            <div style="font-size:22px;font-weight:800;color:var(--info)">${data.shifts_worked_month ?? 0}</div>
                        </div>
                    </div>

                    <div style="margin-top:14px;background:var(--gray-50);padding:12px;border-radius:var(--radius)">
                        <div style="font-size:12px;color:var(--gray-500);font-weight:600">Aktivitas Terakhir</div>
                        <div style="font-size:14px;font-weight:600">${data.last_activity ? App.formatDateTime(data.last_activity) : '-'}</div>
                    </div>

                    <div style="margin-top:14px">
                        <div style="font-size:13px;font-weight:700;margin-bottom:8px">Patroli per Area Hari Ini</div>
                        ${areaEntries.length > 0 ? `
                            <div style="display:flex;gap:8px;flex-wrap:wrap">
                                ${areaEntries.map(([area, count]) => `
                                    <span class="badge badge-blue">${area}: ${count}</span>
                                `).join('')}
                            </div>
                        ` : '<p style="font-size:13px;color:var(--gray-500)">Belum ada patroli hari ini.</p>'}
                    </div>

                    <div style="margin-top:14px">
                        <div style="font-size:13px;font-weight:700;margin-bottom:8px">Breakdown Skor Bulanan</div>
                        <div style="display:flex;gap:8px;flex-wrap:wrap">
                            <span class="badge badge-blue">Patrol Points: ${breakdown.patrol_points ?? 0}</span>
                            <span class="badge badge-green">Bonus Points: ${breakdown.bonus_points ?? 0}</span>
                            <span class="badge badge-yellow">Shift Bonus: ${breakdown.shifts_with_bonus ?? 0}</span>
                            <span class="badge badge-gray">Days Worked: ${breakdown.days_worked ?? 0}</span>
                        </div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button class="btn btn-ghost" onclick="App.closeModal()">Tutup</button>
                </div>
            `);
        } catch (e) {
            App.toast('Gagal memuat detail: ' + e.message, 'error');
        }
    },
};

