/**
 * Audit KM Route Module
 */
App.Router.register('/audit-km', async function () {
    const role = App.Auth.getRole();
    const isAdmin = role === 'admin';

    App.renderLayout('Audit KM', isAdmin ? 'Monitoring pencatatan KM harian' : 'Input audit KM harian', `
        <div class="loading-placeholder" id="akm-loading">
            <span class="material-icons-round">autorenew</span>
            <p>Memuat data audit...</p>
        </div>
        <div id="akm-content" class="hidden"></div>
    `, 'audit-km');

    App.Pages.AuditKM.load({ isAdmin });
}, ['admin', 'security']);
