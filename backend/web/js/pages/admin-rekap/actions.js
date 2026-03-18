App.Pages = App.Pages || {};
App.Pages.AdminRekap = {
    getTodayDate() {
        return App.getTodayDate();
    },

    state: {
        filter_date: '',
        search: '',
    },

    async loadData(params = {}) {
        this.state = { ...this.state, ...params };
        if (!this.state.filter_date) {
            this.state.filter_date = this.getTodayDate();
        }
        const esc = App.escapeHtml || ((v) => String(v ?? ''));

        const loading = document.getElementById('ar-loading');
        const content = document.getElementById('ar-content');
        if (loading) loading.classList.remove('hidden');
        if (content) content.classList.add('hidden');

        try {
            const query = {};
            if (this.state.filter_date) {
                query.start_date = this.state.filter_date;
                query.end_date = this.state.filter_date;
            }
            if (this.state.search) {
                query.search = this.state.search;
            }

            const res = await App.Api.get('/rekaps', query);
            const rekaps = res.data || res || [];

            if (loading) loading.classList.add('hidden');
            if (content) content.classList.remove('hidden');
            if (!content) return;

            content.innerHTML = `
                <div class="card mb-6">
                    <div class="card-body">
                        <form id="ar-filter-form" style="display:flex;gap:12px;align-items:flex-end;flex-wrap:wrap">
                            <div class="form-group" style="margin-bottom:0;min-width:180px;flex:1">
                                <label class="form-label">Tanggal</label>
                                <input type="date" class="form-input" id="ar-filter-date" value="${esc(this.state.filter_date || '')}">
                            </div>
                            <div class="form-group" style="margin-bottom:0;min-width:220px;flex:2">
                                <label class="form-label">Cari (Guard/Aktivitas)</label>
                                <input type="text" class="form-input" id="ar-filter-search" placeholder="Cari..." value="${esc(this.state.search || '')}">
                            </div>
                            <button type="submit" class="btn btn-primary" style="height:42px">
                                <span class="material-icons-round">filter_list</span> Filter
                            </button>
                            <button type="button" class="btn btn-outline" style="height:42px" onclick="App.Pages.AdminRekap.resetFilters()">
                                <span class="material-icons-round">restart_alt</span> Reset
                            </button>
                            <button type="button" class="btn btn-outline" style="height:42px" onclick="App.Pages.AdminRekap.exportData()">
                                <span class="material-icons-round">picture_as_pdf</span> Export PDF
                            </button>
                        </form>
                    </div>
                </div>

                <div class="stat-card green mb-6" style="max-width:250px">
                    <div class="stat-icon"><span class="material-icons-round">receipt_long</span></div>
                    <div class="stat-info">
                        <div class="stat-value">${Array.isArray(rekaps) ? rekaps.length : 0}</div>
                        <div class="stat-label">Total Rekap</div>
                    </div>
                </div>

                <div class="card">
                    <div class="card-header"><h3>Semua Rekap Harian</h3></div>
                    <div class="card-body">
                        ${Array.isArray(rekaps) && rekaps.length > 0 ? `
                            <div class="table-container">
                                <table>
                                    <thead><tr>
                                        <th>Tanggal</th><th>Shift</th><th>Guard</th><th>Aktivitas</th><th>Mulai</th><th>Selesai</th>
                                    </tr></thead>
                                    <tbody>
                                        ${rekaps.map((r) => `
                                            <tr>
                                                <td>${esc(App.formatDate(r.date))}</td>
                                                <td><span class="badge ${r.shift === 'pagi' ? 'badge-yellow' : 'badge-blue'}">${esc(r.shift || '-')}</span></td>
                                                <td>${esc(r.guard || '-')}</td>
                                                <td>${esc(r.activity || '-')}</td>
                                                <td>${esc(r.start_time || '-')}</td>
                                                <td>${esc(r.end_time || '-')}</td>
                                            </tr>
                                        `).join('')}
                                    </tbody>
                                </table>
                            </div>
                        ` : '<div class="empty-state"><span class="material-icons-round">receipt_long</span><p>Belum ada rekap</p></div>'}
                    </div>
                </div>
            `;

            document.getElementById('ar-filter-form')?.addEventListener('submit', (e) => {
                e.preventDefault();
                const filter_date = document.getElementById('ar-filter-date')?.value || '';
                const search = document.getElementById('ar-filter-search')?.value?.trim() || '';
                this.loadData({ filter_date, search });
            });
        } catch (err) {
            if (loading) loading.innerHTML = '<p>Gagal memuat data</p>';
        }
    },

    resetFilters() {
        this.state = { filter_date: this.getTodayDate(), search: '' };
        this.loadData();
    },

    exportData() {
        const query = {};
        if (this.state.filter_date) {
            query.start_date = this.state.filter_date;
            query.end_date = this.state.filter_date;
        }
        if (this.state.search) {
            query.search = this.state.search;
        }

        App.Api.downloadFile('/export/rekap', query, 'laporan-rekap.pdf')
            .catch((e) => App.toast('Gagal export PDF: ' + e.message, 'error'));
    },
};
