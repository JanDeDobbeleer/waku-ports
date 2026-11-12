.pragma library

function closeTray(item) { if (item && typeof item.closeTray === "function") item.closeTray(); }
function checkPopout(item, y) { if (item && typeof item.checkPopout === "function") item.checkPopout(y); }
function debugEntries(item) { return item && typeof item.debugEntries === "function" ? item.debugEntries() : "no content"; }
function openPopoutNamed(item, name) { return item && typeof item.openPopoutNamed === "function" ? item.openPopoutNamed(name) : false; }
function entryItem(item, id) { return item && typeof item.entryItem === "function" ? item.entryItem(id) : null; }
function emptyAt(item, x, y) { return item && typeof item.emptyAt === "function" ? item.emptyAt(x, y) : false; }
function clickClock(item) { return item && typeof item.clickClock === "function" ? item.clickClock() : "no content"; }
function handleWheel(item, y, angleDelta) { if (item && typeof item.handleWheel === "function") item.handleWheel(y, angleDelta); }
