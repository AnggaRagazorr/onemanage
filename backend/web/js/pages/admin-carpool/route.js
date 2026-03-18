/**
 * Admin Carpool Route Module
 */
App.Router.register('/admin/carpool', async function () {
    App.renderLayout('Manajemen Carpool', 'Kelola kendaraan, driver, dan approve trip', `
        <div class="loading-placeholder" id="ac-loading">
            <span class="material-icons-round">autorenew</span>
            <p>Memuat data carpool...</p>
        </div>
        <div id="ac-content" class="hidden"></div>
    `, 'admin-carpool');

    App.Pages.AdminCarpool.loadData();
});

