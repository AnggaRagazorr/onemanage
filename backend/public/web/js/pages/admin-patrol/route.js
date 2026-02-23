/**
 * Admin - Data Patroli
 */
App.Router.register('/admin/patrol', async function () {
    App.renderLayout('Data Patroli', 'Semua data patroli security', `
        <div class="loading-placeholder" id="ap-loading">
            <span class="material-icons-round">autorenew</span>
            <p>Memuat data...</p>
        </div>
        <div id="ap-content" class="hidden"></div>
    `, 'admin-patrol');

    App.Pages.AdminPatrol.loadData();
});
