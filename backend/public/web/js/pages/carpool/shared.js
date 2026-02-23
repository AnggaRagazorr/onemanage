/**
 * Carpool Shared Module
 */
App.CarpoolCore = App.CarpoolCore || {};

App.CarpoolCore.parseList = function (response) {
    return Array.isArray(response) ? response : (response && response.data) || [];
};

App.CarpoolCore.statusMap = {
    requested: ['badge-gray', 'Requested'],
    approved: ['badge-gray', 'Approved'],
    confirmed: ['badge-blue', 'Siap Jalan'],
    in_use: ['badge-blue', 'In Use'],
    pending_key: ['badge-yellow', 'Pending Key'],
    completed: ['badge-green', 'Completed']
};

App.CarpoolCore.statusMeta = function (status) {
    const [cls, lbl] = App.CarpoolCore.statusMap[status] || ['badge-gray', status || '-'];
    return { cls, lbl };
};
