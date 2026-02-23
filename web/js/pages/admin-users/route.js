/**
 * Admin Users - CRUD
 */
App.Router.register('/admin/users', async function () {
    App.renderLayout('Manajemen User', 'Kelola akun security dan admin', `
        <div class="loading-placeholder" id="au-loading">
            <span class="material-icons-round">autorenew</span>
            <p>Memuat data...</p>
        </div>
        <div id="au-content" class="hidden"></div>
    `, 'admin-users');

    App.Pages.AdminUsers.loadData();
});
