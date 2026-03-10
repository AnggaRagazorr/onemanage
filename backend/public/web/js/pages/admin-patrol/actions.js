App.Pages = App.Pages || {};
App.Pages.AdminPatrol = {
    sessionRows: [],
    activeSession: null,

    normalizeDateKey(value) {
        if (!value) return '';
        if (typeof value === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(value.trim())) {
            return value.trim();
        }
        const d = this.parseDate(value);
        if (!d) return '';
        const y = d.getFullYear();
        const m = String(d.getMonth() + 1).padStart(2, '0');
        const day = String(d.getDate()).padStart(2, '0');
        return `${y}-${m}-${day}`;
    },

    parseDate(value) {
        if (!value) return null;
        const d = new Date(value);
        return Number.isNaN(d.getTime()) ? null : d;
    },

    parseTimeToMinutes(value) {
        if (!value) return null;
        const match = String(value).trim().match(/^(\d{1,2}):(\d{2})/);
        if (!match) return null;
        const hour = Number(match[1]);
        const minute = Number(match[2]);
        if (Number.isNaN(hour) || Number.isNaN(minute)) return null;
        return (hour * 60) + minute;
    },

    sameUser(condition, sessionUserId, sessionUserName) {
        const condUserId = condition?.user?.id ?? condition?.user_id ?? null;
        if (sessionUserId != null && condUserId != null) {
            return String(sessionUserId) === String(condUserId);
        }
        const condName = (condition?.user?.name || condition?.user_name || '').toString().trim().toLowerCase();
        const sessionName = (sessionUserName || '').toString().trim().toLowerCase();
        return !!condName && !!sessionName && condName === sessionName;
    },

    getSessionConditions(conditions, session) {
        const byUserAndDate = (conditions || []).filter((c) => {
            const conditionDateKey = this.normalizeDateKey(c.date);
            return conditionDateKey === session.dateKey
                && this.sameUser(c, session.userId, session.securityName);
        });

        if (byUserAndDate.length === 0) {
            return [];
        }

        const startAt = session.records[0]?._ts || null;
        const endAt = session.records[session.records.length - 1]?._ts || null;
        if (!startAt || !endAt) {
            return byUserAndDate;
        }

        const startMinute = (startAt.getHours() * 60) + startAt.getMinutes();
        const endMinute = (endAt.getHours() * 60) + endAt.getMinutes();
        const minWindow = Math.max(0, startMinute - 30);
        const maxWindow = Math.min((24 * 60) - 1, endMinute + 30);

        const inWindow = byUserAndDate.filter((c) => {
            const cMinute = this.parseTimeToMinutes(c.time);
            return cMinute != null && cMinute >= minWindow && cMinute <= maxWindow;
        });

        return inWindow.length > 0 ? inWindow : byUserAndDate;
    },

    buildSessionRows(patrols, conditions) {
        const grouped = new Map();

        (patrols || []).forEach((p, idx) => {
            const rawDateTime = p.captured_at || p.created_at || p.date || '';
            const ts = this.parseDate(rawDateTime);
            const dateKey = this.normalizeDateKey(rawDateTime) || this.normalizeDateKey(p.date);
            const userId = p.user?.id ?? p.user_id ?? null;
            const securityName = p.user?.name || p.user_name || '-';
            const key = `${userId != null ? userId : securityName}|${dateKey || 'unknown'}`;

            if (!grouped.has(key)) {
                grouped.set(key, {
                    userId,
                    securityName,
                    dateKey,
                    items: [],
                });
            }

            grouped.get(key).items.push({
                ...p,
                _ts: ts,
                _order: idx,
            });
        });

        const rows = [];
        grouped.forEach((group) => {
            const ordered = group.items.slice().sort((a, b) => {
                const aTs = a._ts ? a._ts.getTime() : null;
                const bTs = b._ts ? b._ts.getTime() : null;
                if (aTs != null && bTs != null) return aTs - bTs;
                if (aTs != null) return -1;
                if (bTs != null) return 1;
                return a._order - b._order;
            });

            const sessionsRaw = [];
            let currentSessionRecords = [];

            for (const record of ordered) {
                if (currentSessionRecords.length === 0) {
                    currentSessionRecords.push(record);
                } else {
                    const firstRecordTs = currentSessionRecords[0]._ts ? currentSessionRecords[0]._ts.getTime() : 0;
                    const recordTs = record._ts ? record._ts.getTime() : 0;
                    const timeGapMins = (recordTs - firstRecordTs) / (1000 * 60);

                    const areaAlreadyScanned = currentSessionRecords.some(r => r.area === record.area);

                    if (timeGapMins > 60 || areaAlreadyScanned) {
                        // Start a new session
                        sessionsRaw.push([...currentSessionRecords]);
                        currentSessionRecords = [record];
                    } else {
                        currentSessionRecords.push(record);
                    }
                }
            }
            if (currentSessionRecords.length > 0) {
                sessionsRaw.push(currentSessionRecords);
            }

            sessionsRaw.forEach((records, i) => {
                const startAt = records[0]._ts || null;
                const endAt = records[records.length - 1]._ts || null;
                const sessionAt = endAt || startAt;
                const session = {
                    sessionNo: i + 1,
                    sessionLabel: `Sesi ${i + 1}`,
                    securityName: group.securityName,
                    userId: group.userId,
                    dateKey: group.dateKey,
                    records,
                    sessionAt,
                    areas: [...new Set(records.map((r) => r.area || '-'))],
                    conditions: [],
                };
                session.conditions = this.getSessionConditions(conditions, session);
                rows.push(session);
            });
        });

        rows.sort((a, b) => {
            const aTs = a.sessionAt ? a.sessionAt.getTime() : 0;
            const bTs = b.sessionAt ? b.sessionAt.getTime() : 0;
            return bTs - aTs;
        });

        return rows;
    },

    async loadData(params = {}) {
        const loading = document.getElementById('ap-loading');
        const content = document.getElementById('ap-content');

        if (loading) loading.classList.remove('hidden');
        if (content) content.classList.add('hidden');

        try {
            const query = new URLSearchParams(params).toString();
            const [patrolsRes, conditionsRes] = await Promise.all([
                App.Api.get(`/patrols?${query}`).catch(() => ({ data: [] })),
                App.Api.get(`/patrol-conditions?${query}`).catch(() => ({ data: [] })),
            ]);

            const patrols = patrolsRes.data || patrolsRes || [];
            const conditions = conditionsRes.data || conditionsRes || [];

            this.render(patrols, conditions, params);
        } catch (err) {
            if (loading) loading.innerHTML = '<p>Gagal memuat data</p>';
        }
    },

    render(patrols, conditions, params) {
        const loading = document.getElementById('ap-loading');
        const content = document.getElementById('ap-content');

        if (loading) loading.classList.add('hidden');
        if (content) content.classList.remove('hidden');
        if (!content) return;
        const esc = App.escapeHtml || ((v) => String(v ?? ''));
        const sessions = this.buildSessionRows(patrols, conditions);
        this.sessionRows = sessions;
        this.activeSession = null;

        content.innerHTML = `
            <div class="card mb-6">
                <div class="card-body">
                    <form id="ap-filter-form" style="display:flex;gap:12px;align-items:flex-end;flex-wrap:wrap">
                        <div class="form-group" style="margin-bottom:0;flex:1;min-width:150px">
                            <label class="form-label">Tanggal</label>
                            <input type="date" class="form-input" id="f-date" value="${params.filter_date || params.start_date || ''}">
                        </div>
                        <div class="form-group" style="margin-bottom:0;flex:1;min-width:200px">
                            <label class="form-label">Cari (Security/Area/Barcode)</label>
                            <input type="text" class="form-input" id="f-search" placeholder="Cari..." value="${params.search || ''}">
                        </div>
                        <button type="submit" class="btn btn-primary" style="height:42px">
                            <span class="material-icons-round">filter_list</span> Filter
                        </button>
                        <button type="button" class="btn btn-outline" style="height:42px" onclick="App.Pages.AdminPatrol.resetToToday()">
                            <span class="material-icons-round">today</span> Hari Ini
                        </button>
                        <button type="button" class="btn btn-outline" style="height:42px" onclick="App.Pages.AdminPatrol.exportData()">
                            <span class="material-icons-round">picture_as_pdf</span> Export PDF
                        </button>
                    </form>
                </div>
            </div>

            <div class="grid-3 mb-6">
                <div class="stat-card blue">
                    <div class="stat-icon"><span class="material-icons-round">shield</span></div>
                    <div class="stat-info"><div class="stat-value">${patrols.length}</div><div class="stat-label">Total Patroli</div></div>
                </div>
                <div class="stat-card info">
                    <div class="stat-icon"><span class="material-icons-round">history</span></div>
                    <div class="stat-info"><div class="stat-value">${sessions.length}</div><div class="stat-label">Total Sesi</div></div>
                </div>
                <div class="stat-card yellow">
                    <div class="stat-icon"><span class="material-icons-round">report</span></div>
                    <div class="stat-info"><div class="stat-value">${conditions.length}</div><div class="stat-label">Laporan Kondisi</div></div>
                </div>
            </div>

            <div class="card mb-6">
                <div class="card-header"><h3>Log Patroli Per Sesi</h3></div>
                <div class="card-body">
                    ${sessions.length > 0 ? `
                        <p style="font-size:12px;color:var(--gray-500);margin-bottom:10px">Klik baris untuk lihat detail area patroli dan laporan kondisi sesi.</p>
                        <div class="table-container">
                            <table>
                                <thead><tr><th>Waktu</th><th>Security</th><th>Patroli Sesi</th><th>Aksi</th></tr></thead>
                                <tbody>
                                    ${sessions.map((s, idx) => `
                                        <tr style="cursor:pointer" onclick="App.Pages.AdminPatrol.showSessionDetail(${idx})">
                                            <td>${s.sessionAt ? App.formatDateTime(s.sessionAt) : '-'}</td>
                                            <td>${esc(s.securityName)}</td>
                                            <td>${esc(s.sessionLabel)}</td>
                                            <td>
                                                <button class="btn btn-sm btn-outline" onclick="event.stopPropagation(); App.Pages.AdminPatrol.showSessionDetail(${idx})">
                                                    <span class="material-icons-round">visibility</span> Detail
                                                </button>
                                            </td>
                                        </tr>
                                    `).join('')}
                                </tbody>
                            </table>
                        </div>
                    ` : '<div class="empty-state"><span class="material-icons-round">shield</span><p>Belum ada data</p></div>'}
                </div>
            </div>
        `;

        document.getElementById('ap-filter-form')?.addEventListener('submit', (e) => {
            e.preventDefault();
            const filter_date = document.getElementById('f-date')?.value || '';
            const search = document.getElementById('f-search')?.value?.trim() || '';
            this.loadData({
                filter_date,
                start_date: filter_date || '',
                end_date: filter_date || '',
                search
            });
        });
    },

    showSessionDetail(index) {
        const session = this.sessionRows[index];
        if (!session) {
            App.toast('Detail sesi tidak ditemukan', 'warning');
            return;
        }

        this.activeSession = session;
        const esc = App.escapeHtml || ((v) => String(v ?? ''));
        const sessionDate = session.sessionAt ? App.formatDateTime(session.sessionAt) : '-';

        const areaHtml = session.records.map((r, idx) => {
            const photoCount = Number(r.photo_count || 0);
            return `
                <div style="border:1px solid var(--gray-200);border-radius:10px;padding:10px;background:#fff">
                    <div style="display:flex;justify-content:space-between;gap:10px;align-items:flex-start;flex-wrap:wrap">
                        <div>
                            <div style="font-weight:700">${esc(r.area || '-')}</div>
                            <div style="font-size:12px;color:var(--gray-500)">Status QR: <span style="font-weight:600;color:${r.barcode ? 'var(--success)' : 'var(--gray-600)'}">${r.barcode ? '✅ Terverifikasi' : 'Manual'}</span></div>
                            <div style="font-size:12px;color:var(--gray-500)">Waktu: ${esc(App.formatDateTime(r.captured_at || r.created_at))}</div>
                        </div>
                        <button class="btn btn-sm btn-outline" onclick="App.Pages.AdminPatrol.viewSessionAreaPhotos(${idx})" ${photoCount <= 0 ? 'disabled' : ''}>
                            <span class="material-icons-round">photo_library</span> ${photoCount} foto
                        </button>
                    </div>
                </div>
            `;
        }).join('');

        const conditionHtml = session.conditions.length > 0 ? `
            <div class="table-container">
                <table>
                    <thead>
                        <tr>
                            <th>Tanggal</th>
                            <th>Waktu</th>
                            <th>Situasi</th>
                            <th>AGHT</th>
                            <th>Cuaca</th>
                            <th>PDAM</th>
                            <th>WFO</th>
                            <th>Tambahan</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${session.conditions.map((c) => `
                            <tr>
                                <td>${esc(c.date ? App.formatDate(c.date) : (session.dateKey ? App.formatDate(session.dateKey) : '-'))}</td>
                                <td>${esc(c.time || '-')}</td>
                                <td>${esc(c.situasi || '-')}</td>
                                <td>${esc(c.aght || '-')}</td>
                                <td>${esc(c.cuaca || '-')}</td>
                                <td>${esc((c.pdam ?? '').toString().trim() || '-')}</td>
                                <td>${esc(c.wfo ?? '-')}</td>
                                <td>${esc(c.tambahan ?? '-')}</td>
                            </tr>
                        `).join('')}
                    </tbody>
                </table>
            </div>
        ` : '<div class="empty-state" style="padding:20px"><span class="material-icons-round">report</span><p>Belum ada laporan kondisi untuk sesi ini</p></div>';

        App.openModal(`
            <div class="modal-header">
                <h3>Detail Patroli ${esc(session.sessionLabel)}</h3>
                <button class="modal-close" onclick="App.closeModal()"><span class="material-icons-round">close</span></button>
            </div>
            <div class="modal-body" style="max-height:70vh;overflow-y:auto">
                <div style="background:var(--gray-50);border:1px solid var(--gray-200);border-radius:10px;padding:10px;margin-bottom:12px">
                    <div style="font-size:12px;color:var(--gray-500);font-weight:600">SECURITY</div>
                    <div style="font-size:16px;font-weight:700">${esc(session.securityName)}</div>
                    <div style="font-size:12px;color:var(--gray-500);margin-top:3px">Waktu sesi: ${esc(sessionDate)}</div>
                </div>

                <h4 style="margin-bottom:8px">Area yang dipatroli</h4>
                <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:10px;margin-bottom:14px">
                    ${areaHtml}
                </div>

                <h4 style="margin-bottom:8px">Laporan kondisi</h4>
                ${conditionHtml}
            </div>
            <div class="modal-footer">
                <button class="btn btn-ghost" onclick="App.closeModal()">Tutup</button>
            </div>
        `);
    },

    viewSessionAreaPhotos(recordIndex) {
        const record = this.activeSession?.records?.[recordIndex];
        if (!record) {
            App.toast('Data foto sesi tidak ditemukan', 'warning');
            return;
        }
        this.viewPhotos(record.photo_urls || [], record.area || '-');
    },

    resetToToday() {
        const today = new Date().toISOString().slice(0, 10);
        this.loadData({ start_date: today, end_date: today, filter_date: today });
    },

    exportData() {
        const date = document.getElementById('f-date')?.value;
        const search = document.getElementById('f-search')?.value?.trim();
        const query = {};
        if (date) {
            query.start_date = date;
            query.end_date = date;
        }
        if (search) query.search = search;

        App.Api.downloadFile('/export/patrols', query, 'laporan-patroli.pdf')
            .catch((e) => App.toast('Gagal export PDF: ' + e.message, 'error'));
    },

    viewPhotos(urls, area) {
        if (!urls || urls.length === 0) {
            App.toast('Tidak ada foto', 'info');
            return;
        }

        const imagesHtml = urls.map((url) => `
            <img src="${url}" style="max-width:100%;border-radius:8px;margin-bottom:8px;border:1px solid #ddd">
        `).join('');

        App.openModal(`
            <div class="modal-header">
                <h3>Foto Patroli: ${area}</h3>
                <button class="modal-close" onclick="App.closeModal()"><span class="material-icons-round">close</span></button>
            </div>
            <div class="modal-body" style="max-height:70vh;overflow-y:auto;text-align:center">
                ${imagesHtml}
            </div>
            <div class="modal-footer">
                <button class="btn btn-primary" onclick="App.closeModal()">Tutup</button>
            </div>
        `);
    },
};

