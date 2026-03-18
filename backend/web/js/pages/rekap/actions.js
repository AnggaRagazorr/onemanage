App.Pages = App.Pages || {};
App.Pages.Rekap = {
    getTodayDate() {
        return App.getTodayDate();
    },

    async loadData() {
        const loading = document.getElementById('rekap-loading');
        const content = document.getElementById('rekap-content');
        if (loading) loading.classList.remove('hidden');
        if (content) content.classList.add('hidden');

        try {
            const today = this.getTodayDate();
            const res = await App.Api.get('/rekaps', { start_date: today, end_date: today });
            const rekaps = res.data || res || [];
            this.render(rekaps);
        } catch (err) {
            if (loading) loading.innerHTML = '<p>Gagal memuat data</p>';
        }
    },

    render(rekaps) {
        const loading = document.getElementById('rekap-loading');
        const content = document.getElementById('rekap-content');
        if (loading) loading.classList.add('hidden');
        if (content) content.classList.remove('hidden');
        if (!content) return;

        content.innerHTML = `
            <div class="card mb-6">
                <div class="card-header">
                    <h3><span class="material-icons-round" style="vertical-align:middle;margin-right:8px">edit_note</span>Buat Rekap Baru</h3>
                </div>
                <div class="card-body">
                    <form id="rekap-form">
                        <div class="form-row">
                            <div class="form-group">
                                <label class="form-label">Tanggal</label>
                                <input type="date" class="form-input" id="rekap-date" value="${new Date().toISOString().split('T')[0]}" required>
                            </div>
                            <div class="form-group">
                                <label class="form-label">Shift</label>
                                <select class="form-select" id="rekap-shift">
                                    <option value="pagi">Pagi</option>
                                    <option value="malam">Malam</option>
                                </select>
                            </div>
                        </div>
                        <div class="form-row">
                            <div class="form-group">
                                <label class="form-label">Jam Mulai</label>
                                <input type="time" class="form-input" id="rekap-start-time" required>
                            </div>
                            <div class="form-group">
                                <label class="form-label">Jam Selesai</label>
                                <input type="time" class="form-input" id="rekap-end-time" required>
                            </div>
                        </div>
                        <div class="form-group">
                            <label class="form-label">Nama Penjaga</label>
                            <input type="text" class="form-input" id="rekap-guard" placeholder="Nama penjaga" required>
                        </div>
                        <div class="form-group">
                            <label class="form-label">Kegiatan / Aktivitas</label>
                            <textarea class="form-textarea" id="rekap-activity" placeholder="Tuliskan aktivitas harian..." rows="4" required></textarea>
                        </div>
                        <button type="submit" class="btn btn-primary">
                            <span class="material-icons-round">save</span> Simpan Rekap
                        </button>
                    </form>
                </div>
            </div>

            <div class="card">
                <div class="card-header"><h3>Riwayat Rekap Hari Ini</h3></div>
                <div class="card-body">
                    ${Array.isArray(rekaps) && rekaps.length > 0 ? `
                        <div class="table-container">
                            <table>
                                <thead><tr>
                                    <th>Tanggal</th><th>Shift</th><th>Guard</th><th>Aktivitas</th><th>Waktu</th>
                                </tr></thead>
                                <tbody>
                                    ${rekaps.map((r) => `
                                        <tr>
                                            <td>${App.formatDate(r.date)}</td>
                                            <td><span class="badge ${r.shift === 'pagi' ? 'badge-yellow' : 'badge-blue'}">${r.shift || '-'}</span></td>
                                            <td>${r.guard || '-'}</td>
                                            <td>${r.activity || '-'}</td>
                                            <td>${r.start_time || ''} - ${r.end_time || ''}</td>
                                        </tr>
                                    `).join('')}
                                </tbody>
                            </table>
                        </div>
                    ` : `
                        <div class="empty-state">
                            <span class="material-icons-round">receipt_long</span>
                            <p>Belum ada rekap hari ini</p>
                        </div>
                    `}
                </div>
            </div>
        `;

        document.getElementById('rekap-form')?.addEventListener('submit', async (e) => {
            e.preventDefault();
            const data = {
                date: document.getElementById('rekap-date')?.value,
                shift: document.getElementById('rekap-shift')?.value,
                start_time: document.getElementById('rekap-start-time')?.value,
                end_time: document.getElementById('rekap-end-time')?.value,
                guard: document.getElementById('rekap-guard')?.value?.trim(),
                activity: document.getElementById('rekap-activity')?.value?.trim(),
            };
            if (!data.activity || !data.guard || !data.start_time || !data.end_time) {
                App.toast('Semua field wajib diisi', 'warning');
                return;
            }
            try {
                await App.Api.post('/rekaps', data);
                App.toast('Rekap berhasil disimpan!', 'success');
                this.loadData();
            } catch (err) {
                App.toast('Gagal menyimpan rekap: ' + err.message, 'error');
            }
        });
    }
};
