/**
 * Driver Dashboard - Trip management for drivers
 */
App.Router.register('/driver/dashboard', async function () {
    App.renderLayout('Dashboard Driver', 'Kelola trip kendaraan', `
        <div class="loading-placeholder" id="dd-loading">
            <span class="material-icons-round">autorenew</span>
            <p>Memuat data trip...</p>
        </div>
        <div id="dd-content" class="hidden"></div>
    `, 'driver-dashboard');

    App.Pages.DriverDashboard.loadData();
}, ['driver']);
