/**
 * Admin Dokumen Masuk
 */
App.Router.register('/admin/dokumen', async function () {
    App.renderLayout('Dokumen Masuk', 'Semua data barang/dokumen masuk', `
        <div class="loading-placeholder" id="ad-loading">
            <span class="material-icons-round">autorenew</span>
            <p>Memuat data...</p>
        </div>
        <div id="ad-content" class="hidden"></div>
    `, 'admin-dokumen');

    App.Pages.AdminDokumen.loadData();
});
