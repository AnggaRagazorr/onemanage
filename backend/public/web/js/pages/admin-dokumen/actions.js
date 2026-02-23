App.Pages = App.Pages || {};
App.Pages.AdminDokumen = {
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

        const loading = document.getElementById('ad-loading');
        const content = document.getElementById('ad-content');
        if (loading) loading.classList.remove('hidden');
        if (content) content.classList.add('hidden');

        try {
            const query = {};
            if (this.state.filter_date) query.date = this.state.filter_date;
            if (this.state.search) query.search = this.state.search;

            const res = await App.Api.get('/dokumen', query);
            const docs = res.data || res || [];

            if (loading) loading.classList.add('hidden');
            if (content) content.classList.remove('hidden');
            if (!content) return;

            content.innerHTML = `
                <div class="card mb-6">
                    <div class="card-body">
                        <form id="ad-filter-form" style="display:flex;gap:12px;align-items:flex-end;flex-wrap:wrap">
                            <div class="form-group" style="margin-bottom:0;min-width:180px;flex:1">
                                <label class="form-label">Tanggal</label>
                                <input type="date" class="form-input" id="ad-filter-date" value="${esc(this.state.filter_date || '')}">
                            </div>
                            <div class="form-group" style="margin-bottom:0;min-width:220px;flex:2">
                                <label class="form-label">Cari (Asal/Barang/Pemilik/Penerima)</label>
                                <input type="text" class="form-input" id="ad-filter-search" placeholder="Cari..." value="${esc(this.state.search || '')}">
                            </div>
                            <button type="submit" class="btn btn-primary" style="height:42px">
                                <span class="material-icons-round">filter_list</span> Filter
                            </button>
                            <button type="button" class="btn btn-outline" style="height:42px" onclick="App.Pages.AdminDokumen.resetFilters()">
                                <span class="material-icons-round">restart_alt</span> Reset
                            </button>
                            <button type="button" class="btn btn-outline" style="height:42px" onclick="App.Pages.AdminDokumen.exportData()">
                                <span class="material-icons-round">picture_as_pdf</span> Export PDF
                            </button>
                        </form>
                    </div>
                </div>

                <div class="stat-card blue mb-6" style="max-width:250px">
                    <div class="stat-icon"><span class="material-icons-round">folder_shared</span></div>
                    <div class="stat-info">
                        <div class="stat-value">${Array.isArray(docs) ? docs.length : 0}</div>
                        <div class="stat-label">Total Dokumen</div>
                    </div>
                </div>

                <div class="card">
                    <div class="card-header"><h3>Semua Dokumen Masuk</h3></div>
                    <div class="card-body">
                        ${Array.isArray(docs) && docs.length > 0 ? `
                            <div class="table-container">
                                <table>
                                    <thead><tr>
                                        <th>Tanggal</th><th>Hari</th><th>Waktu</th><th>Asal</th><th>Nama Barang</th><th>Qty</th><th>Pemilik</th><th>Penerima</th>
                                    </tr></thead>
                                    <tbody>
                                        ${docs.map((d) => `
                                            <tr>
                                                <td>${esc(App.formatDate(d.date))}</td>
                                                <td>${esc(d.day || '-')}</td>
                                                <td>${esc(d.time || '-')}</td>
                                                <td>${esc(d.origin || '-')}</td>
                                                <td><strong>${esc(d.item_name || '-')}</strong></td>
                                                <td>${esc(d.qty || '-')}</td>
                                                <td>${esc(d.owner || '-')}</td>
                                                <td>${esc(d.receiver || '-')}</td>
                                            </tr>
                                        `).join('')}
                                    </tbody>
                                </table>
                            </div>
                        ` : '<div class="empty-state"><span class="material-icons-round">folder_open</span><p>Belum ada dokumen masuk</p></div>'}
                    </div>
                </div>
            `;

            document.getElementById('ad-filter-form')?.addEventListener('submit', (e) => {
                e.preventDefault();
                const filter_date = document.getElementById('ad-filter-date')?.value || '';
                const search = document.getElementById('ad-filter-search')?.value?.trim() || '';
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
        if (this.state.filter_date) query.date = this.state.filter_date;
        if (this.state.search) query.search = this.state.search;

        App.Api.downloadFile('/export/dokumen', query, 'laporan-dokumen.pdf')
            .catch((e) => App.toast('Gagal export PDF: ' + e.message, 'error'));
    },
};
