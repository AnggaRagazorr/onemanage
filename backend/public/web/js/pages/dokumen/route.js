/**
 * Dokumen Masuk Page
 */
App.Router.register('/dokumen', async function () {
    App.renderLayout('Dokumen Masuk', 'Pencatatan barang/dokumen masuk', `
        <div class="loading-placeholder" id="doc-loading">
            <span class="material-icons-round">autorenew</span>
            <p>Memuat data dokumen...</p>
        </div>
        <div id="doc-content" class="hidden"></div>
    `, 'dokumen');

    App.Pages.Dokumen.loadData();
});
