.pragma library

function percent(source) { return source.percent / 100; }
function gpuType(source, types) { return source.available ? types.Generic : types.None; }
function name(source) { return source.name; }
function ready(source) { return source.ready; }
function used(source) { return source.used / 1024; }
function total(source) { return source.total / 1024; }
