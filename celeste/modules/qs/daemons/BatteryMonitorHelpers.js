.pragma library

function sortWarnLevels(config) {
    const levels = config.values.slice();
    levels.sort(function(a, b) { return a.level - b.level; });
    return levels;
}

function handleWarnings(percentage, onBattery, lastPercentage, warnLevels, timer, criticalLevel, toaster, translation, errorType, warningType) {
    if (!onBattery)
        return percentage;
    if (lastPercentage >= 0) {
        for (let i = 0; i < warnLevels.length; i++) {
            const level = warnLevels[i];
            if (percentage <= level.level && lastPercentage > level.level) {
                toaster.toast(translation.trMarked(level.title || translation.tr("Battery warning")), translation.trMarked(level.message || translation.tr("Battery level is low")), level.icon || "battery_android_alert", level.critical ? errorType : warningType, 5000);
                break;
            }
        }
    }
    if (!timer.running && percentage <= criticalLevel) {
        toaster.toast(translation.tr("Hibernating in 5 seconds"), translation.tr("Hibernating to prevent data loss"), "battery_android_alert", errorType, 5000);
        timer.start();
    }
    return percentage;
}
