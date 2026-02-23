/**
 * Patrol Shared Module
 * Keeps existing constants/utilities unchanged, only namespaced.
 */
App.PatrolCore = App.PatrolCore || {};
App.PatrolCore.PATROL_AREAS = ['Area Luar', 'Area Balkon', 'Area Smoking'];
App.PatrolCore.PATROL_ROUNDS_PER_SHIFT = 4;
App.PatrolCore.PATROL_TARGET_PER_SHIFT =
    App.PatrolCore.PATROL_AREAS.length * App.PatrolCore.PATROL_ROUNDS_PER_SHIFT;

App.PatrolCore.normalizePatrolArea = function (rawValue) {
    const value = (rawValue || '').toString().trim().toLowerCase();
    if (!value) return '';
    if (value.includes('luar')) return 'Area Luar';
    if (value.includes('balkon')) return 'Area Balkon';
    if (value.includes('smoking')) return 'Area Smoking';
    return rawValue;
};

App.PatrolCore.resolvePatrolAreaFromCode = function (rawCode) {
    const code = (rawCode || '').toString().trim();
    if (!code) return '';

    try {
        const parsed = JSON.parse(code);
        if (parsed && parsed.area) {
            const normalized = App.PatrolCore.normalizePatrolArea(parsed.area);
            if (App.PatrolCore.PATROL_AREAS.includes(normalized)) return normalized;
        }
    } catch (e) {
        // Not JSON, continue with plain text parsing.
    }

    const normalized = App.PatrolCore.normalizePatrolArea(code);
    if (App.PatrolCore.PATROL_AREAS.includes(normalized)) return normalized;

    const compact = code.toLowerCase().replace(/[^a-z]/g, '');
    if (compact.includes('arealuar') || compact.includes('luar')) return 'Area Luar';
    if (compact.includes('areabalkon') || compact.includes('balkon')) return 'Area Balkon';
    if (compact.includes('areasmoking') || compact.includes('smoking')) return 'Area Smoking';
    return '';
};

App.PatrolCore.isTodayDate = function (value) {
    if (!value) return false;
    const d = new Date(value);
    if (Number.isNaN(d.getTime())) return false;
    const now = new Date();
    return d.getFullYear() === now.getFullYear()
        && d.getMonth() === now.getMonth()
        && d.getDate() === now.getDate();
};
