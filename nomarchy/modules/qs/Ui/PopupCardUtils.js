.pragma library

function field(object, key) { return object ? object[key] : undefined }
function number(object, key) { return object ? Number(object[key]) : 0 }
