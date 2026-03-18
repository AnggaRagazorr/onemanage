/**
 * Rekap Harian Page
 */
App.Router.register('/rekap', async function () {
    App.renderLayout('Rekap Harian', 'Catat rekap aktivitas harian', `
        <div class="loading-placeholder" id="rekap-loading">
            <span class="material-icons-round">autorenew</span>
            <p>Memuat data rekap...</p>
        </div>
        <div id="rekap-content" class="hidden"></div>
    `, 'rekap');

    App.Pages.Rekap.loadData();
});
