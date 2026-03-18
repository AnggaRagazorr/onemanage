/**
 * Audit KM Actions Module
 */
const { getTodayDate: auditKmGetTodayDate } = App.AuditKMCore;

App.Pages = App.Pages || {};
App.Pages.AuditKM = {
    state: {
        selectedDate: null,
    },

    getTodayDate() {
        return auditKmGetTodayDate();
    },

    getSelectedDate(isAdmin) {
        if (!isAdmin) return this.getTodayDate();
        if (!this.state.selectedDate) this.state.selectedDate = this.getTodayDate();
        return this.state.selectedDate;
    },

    parseAuditList(response) {
        if (Array.isArray(response)) return response;
        if (response && Array.isArray(response.data)) return response.data;
        return [];
    },

    buildLatestAuditByVehicle(audits) {
        const map = new Map();
        audits.forEach((audit) => {
            const key = audit.vehicle_id;
            const prev = map.get(key);
            if (!prev) {
                map.set(key, audit);
                return;
            }

            const prevTime = new Date(prev.updated_at || prev.created_at || 0).getTime();
            const nextTime = new Date(audit.updated_at || audit.created_at || 0).getTime();
            if (nextTime >= prevTime) map.set(key, audit);
        });
        return map;
    },

    statusBadgeFromAudit(audit) {
        if (!audit) return '<span class="badge badge-gray">Belum Update</span>';
        const diff = Math.abs(parseFloat(audit.difference || 0));
        const isAlert = !!audit.is_alert || diff > 50;
        return isAlert
            ? '<span class="badge badge-red">Alert</span>'
            : '<span class="badge badge-green">OK</span>';
    },

    renderHistoryRows(audits) {
        if (!audits.length) {
            return '<tr><td colspan="8" style="text-align:center;color:var(--gray-500)">Belum ada audit pada tanggal ini</td></tr>';
        }

        return audits.map((a) => {
            const diff = parseFloat(a.difference || 0);
            const isAlert = !!a.is_alert || Math.abs(diff) > 50;
            const diffColor = isAlert
                ? 'color:var(--danger);font-weight:700'
                : (diff > 0 ? 'color:var(--success)' : '');
            const rowStyle = isAlert ? 'background:#fef2f2' : '';

            return `
                <tr style="${rowStyle}">
                    <td>${App.formatDate(a.date || a.created_at)}</td>
                    <td>${a.vehicle ? a.vehicle.plate : '-'}</td>
                    <td>${a.user ? a.user.name : '-'}</td>
                    <td>${a.recorded_km}</td>
                    <td>${a.actual_km}</td>
                    <td style="${diffColor}">${diff > 0 ? '+' : ''}${diff}</td>
                    <td>${this.statusBadgeFromAudit(a)}</td>
                    <td>${App.formatDateTime(a.updated_at || a.created_at)}</td>
                </tr>
            `;
        }).join('');
    },

    async load({ isAdmin }) {
        const loading = document.getElementById('akm-loading');
        const content = document.getElementById('akm-content');
        const selectedDate = this.getSelectedDate(isAdmin);

        if (loading) loading.classList.remove('hidden');
        if (content) content.classList.add('hidden');

        try {
            const [vehiclesRes, auditsRes] = await Promise.all([
                App.Api.get('/carpool/vehicles').catch(() => []),
                App.Api.get('/km-audits', { date: selectedDate, per_page: 500 }).catch(() => ({ data: [] })),
            ]);

            const vehicles = Array.isArray(vehiclesRes) ? vehiclesRes : (vehiclesRes.data || []);
            const audits = this.parseAuditList(auditsRes);
            const auditsByVehicle = this.buildLatestAuditByVehicle(audits);

            const totalVehicles = vehicles.length;
            const updatedCount = auditsByVehicle.size;
            const pendingCount = Math.max(0, totalVehicles - updatedCount);
            const hasAlert = audits.some(a => !!a.is_alert || Math.abs(parseFloat(a.difference || 0)) > 50);

            if (loading) loading.classList.add('hidden');
            if (content) content.classList.remove('hidden');

            const filterHtml = isAdmin ? `
                <div class="card mb-6">
                    <div class="card-body">
                        <form id="akm-filter-form" style="display:flex;gap:12px;align-items:flex-end;flex-wrap:wrap">
                            <div class="form-group" style="margin-bottom:0;min-width:220px">
                                <label class="form-label">Tanggal Audit</label>
                                <input type="date" class="form-input" id="akm-filter-date" value="${selectedDate}">
                            </div>
                            <button type="submit" class="btn btn-primary" style="height:42px">
                                <span class="material-icons-round">filter_list</span> Tampilkan
                            </button>
                            <button type="button" class="btn btn-outline" style="height:42px" onclick="App.Pages.AuditKM.exportData()">
                                <span class="material-icons-round">picture_as_pdf</span> Export PDF
                            </button>
                        </form>
                    </div>
                </div>
            ` : '';

            const adminTableHtml = `
                <div class="card mb-6">
                    <div class="card-header">
                        <h3><span class="material-icons-round" style="vertical-align:middle;margin-right:8px">speed</span>Monitoring KM (${App.formatDate(selectedDate)})</h3>
                        <span class="badge ${pendingCount > 0 ? 'badge-yellow' : 'badge-green'}">${updatedCount}/${totalVehicles} kendaraan update</span>
                    </div>
                    <div class="card-body">
                        ${vehicles.length > 0 ? `
                            <div class="table-container">
                                <table>
                                    <thead>
                                        <tr>
                                            <th>Kendaraan</th>
                                            <th>Driver Terakhir</th>
                                            <th>System KM</th>
                                            <th>Aktual KM</th>
                                            <th>Selisih</th>
                                            <th>Status</th>
                                            <th>Diupdate Oleh</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        ${vehicles.map(v => {
                const audit = auditsByVehicle.get(v.id);
                const diff = audit ? parseFloat(audit.difference || 0) : null;
                const diffText = diff === null ? '-' : `${diff > 0 ? '+' : ''}${diff}`;
                const diffStyle = diff === null ? '' : (Math.abs(diff) > 50 ? 'color:var(--danger);font-weight:700' : '');

                return `
                                            <tr>
                                                <td>
                                                    <div style="font-weight:700">${v.plate}</div>
                                                    <div style="font-size:13px;color:var(--gray-500)">${v.brand}</div>
                                                </td>
                                                <td>
                                                    <div style="font-weight:600">${v.driver_name || '-'}</div>
                                                    <div style="font-size:12px;color:var(--gray-500)">${v.driver_nip || ''}</div>
                                                </td>
                                                <td><span class="badge badge-blue">${v.current_km} km</span></td>
                                                <td>${audit ? `${audit.actual_km} km` : '-'}</td>
                                                <td style="${diffStyle}">${diffText}</td>
                                                <td>${this.statusBadgeFromAudit(audit)}</td>
                                                <td>${audit && audit.user ? audit.user.name : '-'}</td>
                                            </tr>
                                        `;
            }).join('')}
                                    </tbody>
                                </table>
                            </div>
                        ` : '<div class="empty-state"><p>Tidak ada data kendaraan</p></div>'}
                    </div>
                </div>
            `;

            const securitySummaryHtml = `
                <div class="card mb-6">
                    <div class="card-header">
                        <h3><span class="material-icons-round" style="vertical-align:middle;margin-right:8px">today</span>Audit Hari Ini (${App.formatDate(this.getTodayDate())})</h3>
                        <span class="badge ${pendingCount > 0 ? 'badge-yellow' : 'badge-green'}">${updatedCount}/${totalVehicles} kendaraan</span>
                    </div>
                    <div class="card-body">
                        <p style="font-size:13px;color:var(--gray-500)">Setiap kendaraan wajib diupdate minimal 1 kali per hari.</p>
                        ${pendingCount > 0 ? `
                            <div style="margin-top:10px;background:#fff7ed;border:1px solid #fdba74;color:#9a3412;padding:10px 12px;border-radius:10px">
                                Masih ada <strong>${pendingCount}</strong> kendaraan yang belum diupdate hari ini.
                            </div>
                        ` : `
                            <div style="margin-top:10px;background:#ecfdf5;border:1px solid #86efac;color:#166534;padding:10px 12px;border-radius:10px">
                                Semua kendaraan sudah diupdate hari ini.
                            </div>
                        `}
                    </div>
                </div>
            `;

            const securityTableHtml = `
                <div class="card mb-6">
                    <div class="card-header">
                        <h3><span class="material-icons-round" style="vertical-align:middle;margin-right:8px">speed</span>Input Audit Harian</h3>
                    </div>
                    <div class="card-body">
                        ${vehicles.length > 0 ? `
                            <div class="table-container">
                                <table>
                                    <thead>
                                        <tr>
                                            <th>Kendaraan</th>
                                            <th>Driver Terakhir</th>
                                            <th>System KM</th>
                                            <th>Status Hari Ini</th>
                                            <th style="width:200px">Aktual KM</th>
                                            <th style="width:130px">Aksi</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        ${vehicles.map(v => {
                const todayAudit = auditsByVehicle.get(v.id);
                const defaultValue = todayAudit ? todayAudit.actual_km : '';
                const buttonLabel = todayAudit ? 'Perbarui' : 'Simpan';

                return `
                                            <tr>
                                                <td>
                                                    <div style="font-weight:700">${v.plate}</div>
                                                    <div style="font-size:13px;color:var(--gray-500)">${v.brand}</div>
                                                </td>
                                                <td>${v.driver_name || '-'}</td>
                                                <td><span class="badge badge-blue">${v.current_km} km</span></td>
                                                <td>${this.statusBadgeFromAudit(todayAudit)}</td>
                                                <td>
                                                    <input
                                                        type="number"
                                                        class="form-input form-input-sm"
                                                        id="audit-input-${v.id}"
                                                        placeholder="${v.current_km}"
                                                        value="${defaultValue}"
                                                        step="0.1"
                                                        min="0"
                                                    >
                                                </td>
                                                <td>
                                                    <button class="btn btn-primary btn-sm" onclick="App.Pages.AuditKM.submitAudit(${v.id}, '${v.current_km}')">
                                                        ${buttonLabel}
                                                    </button>
                                                </td>
                                            </tr>
                                        `;
            }).join('')}
                                    </tbody>
                                </table>
                            </div>
                        ` : '<div class="empty-state"><p>Tidak ada data kendaraan</p></div>'}
                    </div>
                </div>
            `;

            const historyTitle = isAdmin
                ? `Riwayat Audit (${App.formatDate(selectedDate)})`
                : 'Riwayat Audit Hari Ini';

            const historyHtml = `
                <div class="card">
                    <div class="card-header"><h3>${historyTitle}</h3></div>
                    <div class="card-body">
                        <div class="table-container">
                            <table>
                                <thead><tr><th>Tanggal</th><th>Kendaraan</th><th>Oleh</th><th>System</th><th>Aktual</th><th>Selisih</th><th>Status</th><th>Waktu Update</th></tr></thead>
                                <tbody>
                                    ${this.renderHistoryRows(audits)}
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            `;

            content.innerHTML = `
                ${isAdmin && hasAlert ? `
                    <div class="mb-6" style="background:#fee2e2;border:1px solid #ef4444;color:#b91c1c;padding:16px;border-radius:12px;display:flex;align-items:center;gap:12px">
                        <span class="material-icons-round">warning</span>
                        <strong>Perhatian:</strong> Ada selisih KM > 50 pada tanggal yang dipilih.
                    </div>
                ` : ''}
                ${filterHtml}
                ${isAdmin ? adminTableHtml : `${securitySummaryHtml}${securityTableHtml}`}
                ${historyHtml}
            `;

            if (isAdmin) {
                document.getElementById('akm-filter-form')?.addEventListener('submit', (e) => {
                    e.preventDefault();
                    const dateValue = document.getElementById('akm-filter-date')?.value || this.getTodayDate();
                    this.state.selectedDate = dateValue;
                    this.refresh();
                });
            }
        } catch (err) {
            if (loading) loading.innerHTML = '<p>Gagal memuat data</p>';
        }
    },

    refresh() {
        App.Router.routes['/audit-km'].renderFn();
    },

    exportData() {
        const date = this.state.selectedDate || this.getTodayDate();
        const query = { date };
        App.Api.downloadFile('/export/km-audits', query, 'laporan-audit-km.pdf')
            .catch((e) => App.toast('Gagal export PDF: ' + e.message, 'error'));
    },

    async submitAudit(vehicleId, systemKmStr) {
        const input = document.getElementById(`audit-input-${vehicleId}`);
        if (!input) return;

        const actualKm = parseFloat(input.value);
        const systemKm = parseFloat(systemKmStr);

        if (!input.value || isNaN(actualKm)) {
            App.toast('Masukkan angka KM aktual', 'warning');
            return;
        }

        if (actualKm < systemKm) {
            if (!confirm(`KM Aktual (${actualKm}) lebih kecil dari System (${systemKm}). Yakin data benar?`)) return;
        }

        try {
            const res = await App.Api.post('/km-audits', {
                vehicle_id: vehicleId,
                actual_km: actualKm,
            });

            if (res.is_alert || (res.data && res.data.is_alert)) {
                App.toast('Disimpan: Selisih KM > 50 KM', 'error');
            } else if (res.updated) {
                App.toast('Audit hari ini berhasil diperbarui', 'success');
            } else {
                App.toast('Audit hari ini berhasil disimpan', 'success');
            }

            this.refresh();
        } catch (e) {
            App.toast('Gagal: ' + e.message, 'error');
        }
    },
};



