.pragma library

function pressed(indicator) { return indicator ? (indicator.pressed || false) : false; }
function hovered(indicator) { return indicator ? (indicator.hovered || false) : false; }
