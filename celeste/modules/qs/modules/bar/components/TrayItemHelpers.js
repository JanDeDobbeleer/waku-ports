.pragma library

function name(item) { return item.tooltipTitle || item.title || item.id; }
function fakeGlyph(item) { return item.fakeGlyph || ""; }
function iconPath(item, icons) { return icons.getTrayIcon(item.id, item.icon); }
function activate(item, event, qt, window) {
    if (event.button === qt.LeftButton)
        item.activate();
    else if (event.button === qt.MiddleButton)
        item.secondaryActivate();
    else
        item.display(window, event.x, event.y);
}
