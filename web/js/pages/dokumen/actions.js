App.Pages = App.Pages || {};
App.Pages.Dokumen = {
    async loadData() {
        const loading = document.getElementById('doc-loading');
        const content = document.getElementById('doc-content');
        if (loading) loading.classList.remove('hidden');
        if (content) content.classList.add('hidden');

        try {
            const res = await App.Api.get('/dokumen');
            const docs = res.data || res || [];
            this.render(docs);
        } catch (err) {
            if (loading) loading.innerHTML = '<p>Gagal memuat data</p>';
        }
    },

    render(docs) {
        const loading = document.getElementById('doc-loading');
        const content = document.getElementById('doc-content');
        if (loading) loading.classList.add('hidden');
        if (content) content.classList.remove('hidden');
        if (!content) return;

        const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
        const todayDay = days[new Date().getDay()];
        const nowTime = new Date().toTimeString().slice(0, 5);

        content.innerHTML = `
            <div class="card mb-6">
                <div class="card-header">
                    <h3><span class="material-icons-round" style="vertical-align:middle;margin-right:8px">note_add</span>Catat Barang / Dokumen Masuk</h3>
                </div>
                <div class="card-body">
                    <form id="doc-form">
                        <div class="form-row">
                            <div class="form-group">
                                <label class="form-label">Tanggal</label>
                                <input type="date" class="form-input" id="doc-date" value="${new Date().toISOString().split('T')[0]}" required>
                            </div>
                            <div class="form-group">
                                <label class="form-label">Hari</label>
                                <input type="text" class="form-input" id="doc-day" value="${todayDay}" required>
                            </div>
                            <div class="form-group">
                                <label class="form-label">Waktu</label>
                                <input type="time" class="form-input" id="doc-time" value="${nowTime}" required>
                            </div>
                        </div>
                        <div class="form-row">
                            <div class="form-group">
                                <label class="form-label">Asal / Origin</label>
                                <input type="text" class="form-input" id="doc-origin" placeholder="Asal barang/dokumen" required>
                            </div>
                            <div class="form-group">
                                <label class="form-label">Nama Barang</label>
                                <input type="text" class="form-input" id="doc-item-name" placeholder="Nama barang/dokumen" required>
                            </div>
                        </div>
                        <div class="form-row">
                            <div class="form-group">
                                <label class="form-label">Jumlah (Qty)</label>
                                <input type="text" class="form-input" id="doc-qty" placeholder="Jumlah" required>
                            </div>
                            <div class="form-group">
                                <label class="form-label">Pemilik</label>
                                <input type="text" class="form-input" id="doc-owner" placeholder="Pemilik" required>
                            </div>
                            <div class="form-group">
                                <label class="form-label">Penerima</label>
                                <input type="text" class="form-input" id="doc-receiver" placeholder="Penerima" required>
                            </div>
                        </div>
                        <button type="submit" class="btn btn-primary">
                            <span class="material-icons-round">save</span> Simpan
                        </button>
                    </form>
                </div>
            </div>

            <div class="card">
                <div class="card-header"><h3>Daftar Barang/Dokumen Masuk</h3></div>
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
                                            <td>${App.formatDate(d.date)}</td>
                                            <td>${d.day || '-'}</td>
                                            <td>${d.time || '-'}</td>
                                            <td>${d.origin || '-'}</td>
                                            <td><strong>${d.item_name || '-'}</strong></td>
                                            <td>${d.qty || '-'}</td>
                                            <td>${d.owner || '-'}</td>
                                            <td>${d.receiver || '-'}</td>
                                        </tr>
                                    `).join('')}
                                </tbody>
                            </table>
                        </div>
                    ` : `
                        <div class="empty-state">
                            <span class="material-icons-round">folder_open</span>
                            <p>Belum ada dokumen masuk</p>
                        </div>
                    `}
                </div>
            </div>
        `;

        document.getElementById('doc-form')?.addEventListener('submit', async (e) => {
            e.preventDefault();
            const data = {
                date: document.getElementById('doc-date')?.value,
                day: document.getElementById('doc-day')?.value?.trim(),
                time: document.getElementById('doc-time')?.value,
                origin: document.getElementById('doc-origin')?.value?.trim(),
                item_name: document.getElementById('doc-item-name')?.value?.trim(),
                qty: document.getElementById('doc-qty')?.value?.trim(),
                owner: document.getElementById('doc-owner')?.value?.trim(),
                receiver: document.getElementById('doc-receiver')?.value?.trim(),
            };

            if (!data.origin || !data.item_name || !data.qty || !data.owner || !data.receiver) {
                App.toast('Semua field wajib diisi', 'warning');
                return;
            }

            try {
                await App.Api.post('/dokumen', data);
                App.toast('Dokumen berhasil disimpan!', 'success');
                App.Router.navigate('/dokumen');
            } catch (err) {
                App.toast('Gagal menyimpan: ' + err.message, 'error');
            }
        });
    }
};
