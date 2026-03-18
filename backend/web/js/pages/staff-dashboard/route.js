/**
 * Staff Dashboard Route Module
 */
App.Router.register('/staff/dashboard', async function () {
    App.renderLayout('Dashboard Staff', 'Buat request, admin akan menentukan kendaraan dan driver', `
        <div class="loading-placeholder" id="sd-loading">
            <span class="material-icons-round">autorenew</span>
            <p>Memuat data...</p>
        </div>
        <div id="sd-content" class="hidden"></div>
    `, 'staff-dashboard');

    App.Pages.StaffDashboard.load();
}, ['staff']);
