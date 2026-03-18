/**
 * Admin Carpool Shared Module
 * Keeps helpers centralized without changing existing behavior.
 */
App.AdminCarpoolCore = App.AdminCarpoolCore || {};

App.AdminCarpoolCore.getTodayDate = function () {
    return App.getTodayDate();
};

App.AdminCarpoolCore.esc = function (value) {
    const esc = App.escapeHtml || ((v) => String(v ?? ''));
    return esc(value);
};

App.AdminCarpoolCore.toId = function (value) {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : 0;
};

App.AdminCarpoolCore.safeBadgeClass = function (cls) {
    return ['badge-green', 'badge-blue', 'badge-yellow', 'badge-gray'].includes(cls) ? cls : 'badge-gray';
};

