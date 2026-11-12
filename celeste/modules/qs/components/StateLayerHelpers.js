.pragma library

function radius(item) { return item ? (item.radius || 0) : 0; }
function cornerRadius(item, corner, fallback) {
    return item && item[corner] !== undefined ? item[corner] : fallback || 0;
}
