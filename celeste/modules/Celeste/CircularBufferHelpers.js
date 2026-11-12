.pragma library

function length(values) { return values.length; }
function push(values, capacity, value) {
    var next = values.length >= capacity ? values.slice(values.length - capacity + 1) : values.slice();
    next.push(value);
    return next;
}
function maximum(values) {
    var max = 0;
    for (var i = 0; i < values.length; i++)
        max = Math.max(max, values[i]);
    return max;
}
function at(values, index) {
    return index < 0 || index >= values.length ? 0 : values[index];
}
