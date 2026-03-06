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

    const today = new Date().toISOString().slice(0, 10);
    App.Pages.AdminPatrol.loadData({ start_date: today, end_date: today, filter_date: today });
});
