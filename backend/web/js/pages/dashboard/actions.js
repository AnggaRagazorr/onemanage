App.Pages = App.Pages || {};
App.Pages.Dashboard = {
    async clockIn(type) {
        try {
            await App.Api.post('/shifts/clock-in', { shift_type: type });
            App.toast(`Clock In shift ${type} berhasil!`, 'success');
            App.Router.navigate('/dashboard');
        } catch (e) {
            App.toast('Gagal clock in: ' + e.message, 'error');
        }
    },

    async clockOut() {
        try {
            await App.Api.post('/shifts/clock-out');
            App.toast('Clock Out berhasil!', 'success');
            App.Router.navigate('/dashboard');
        } catch (e) {
            App.toast('Gagal clock out: ' + e.message, 'error');
        }
    }
};
