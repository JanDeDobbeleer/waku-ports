.pragma library
function contains(shape, logo, uptime, mouse, point) {
    return shape.contains(point) && !logo.contains(mouse.mapToItem(logo, point)) && !uptime.contains(mouse.mapToItem(uptime, point));
}
function open(dialog) { dialog.open(); }
