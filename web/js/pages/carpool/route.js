/**
 * Carpool Route Module
 */
App.Router.register('/carpool', async function () {
    App.renderLayout('Carpool', 'Catat Keluar & Validasi Kunci', `
        <div class="loading-placeholder" id="carpool-loading">
            <span class="material-icons-round">autorenew</span>
            <p>Memuat data carpool...</p>
        </div>
        <div id="carpool-content" class="hidden"></div>
    `, 'carpool');

    App.Pages.CarpoolSecurity.load();
}, ['admin', 'security']);
