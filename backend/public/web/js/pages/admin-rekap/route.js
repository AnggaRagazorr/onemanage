/**
 * Admin Rekap Harian
 */
App.Router.register('/admin/rekap', async function () {
    App.renderLayout('Rekap Harian', 'Semua data rekap dari security', `
        <div class="loading-placeholder" id="ar-loading">
            <span class="material-icons-round">autorenew</span>
            <p>Memuat data...</p>
        </div>
        <div id="ar-content" class="hidden"></div>
    `, 'admin-rekap');

    App.Pages.AdminRekap.loadData();
});
