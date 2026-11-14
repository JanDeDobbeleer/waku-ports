.pragma library

function field(object, key) { return object ? object[key] : undefined }
function arrayLength(value) { return value ? value.length : 0 }
function arrayAt(value, index) { return value ? value[index] : undefined }
