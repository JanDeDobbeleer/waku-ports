.pragma library

function invoke(item, list) { if (item) item.onClicked(list); }
function field(item, name) { return item ? (item[name] || "") : ""; }
function isCurrentVariant(item, current) { return item && item.variant === current; }
