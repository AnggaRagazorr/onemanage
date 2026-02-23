/**
 * Admin Dashboard Page
 */
App.Router.register('/admin/dashboard', async function () {
    App.renderLayout('Dashboard Admin', 'Overview semua aktivitas', `
        <div class="loading-placeholder" id="adash-loading">
            <span class="material-icons-round">autorenew</span>
            <p>Memuat data dashboard...</p>
        </div>
        <div id="adash-content" class="hidden"></div>
    `, 'admin-dashboard');

    App.Pages.AdminDashboard.loadData();
});
