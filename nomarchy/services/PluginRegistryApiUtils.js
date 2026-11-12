.pragma library

function field(object, key) { return object ? object[key] : undefined }
function invoke(callback, args, receiver) {
  return typeof callback === "function" ? callback.apply(receiver, args) : undefined
}
