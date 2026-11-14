.pragma library

function dayName(model) { return model.shortName; }
function weekendColour(model, weekend, weekday) { return model.day === 0 || model.day === 6 ? weekend : weekday; }
function dateText(locale, model) { return locale.toString(model.day); }
function dateColour(model, weekend, weekday) {
    const day = model.date.getDay();
    return day === 0 || day === 6 ? weekend : weekday;
}
function dateOpacity(model, currentMonth) { return model.today || model.month === currentMonth ? 1 : 0.4; }
function findToday(grid) {
    const children = grid.contentItem.children;
    for (let i = 0; i < children.length; i++) {
        if (children[i].model && children[i].model.today)
            return children[i];
    }
    return null;
}
function todaySize(today, padding) {
    return today ? Math.max(today.implicitWidth, today.implicitHeight) + padding * 2 : 0;
}
