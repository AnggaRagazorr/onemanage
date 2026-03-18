/**
 * Admin Security Stats
 */
App.Router.register('/admin/security-stats', async function () {
    App.renderLayout('Statistik Security', 'Performa dan skor patroli security', `
        <div class="loading-placeholder" id="as-loading">
            <span class="material-icons-round">autorenew</span>
            <p>Memuat data statistik...</p>
        </div>
        <div id="as-content" class="hidden"></div>
    `, 'admin-stats');

    App.Pages.AdminSecurityStats.loadData();
});
