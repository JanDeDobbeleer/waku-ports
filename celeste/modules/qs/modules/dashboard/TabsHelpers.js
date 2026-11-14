.pragma library

function iconName(tab) { return tab.iconName; }
function text(tab) { return tab.text; }
function implicitWidth(item, fallback) { return item ? item.implicitWidth : (fallback || 0); }
function doubleHeight(item) { return item.implicitHeight * 2; }
