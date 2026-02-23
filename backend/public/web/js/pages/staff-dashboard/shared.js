/**
 * Staff Dashboard Shared Module
 */
App.StaffDashboardCore = App.StaffDashboardCore || {};

App.StaffDashboardCore.statusLabelMap = {
    requested: 'Menunggu Approval',
    approved: 'Menunggu Approval',
    confirmed: 'Driver Sudah Menerima',
    in_use: 'Sedang Trip',
    pending_key: 'Pending Kunci',
    completed: 'Selesai'
};

App.StaffDashboardCore.statusBadgeClassMap = {
    requested: 'badge-yellow',
    approved: 'badge-yellow',
    confirmed: 'badge-blue',
    in_use: 'badge-blue',
    pending_key: 'badge-yellow',
    completed: 'badge-green'
};

App.StaffDashboardCore.notifStorageKey = 'staff_approval_notified';

App.StaffDashboardCore.parseList = function (response) {
    return Array.isArray(response) ? response : (response && response.data) || [];
};
