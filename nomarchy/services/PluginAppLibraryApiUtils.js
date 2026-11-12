.pragma library

function invoke(callback, args, receiver) {
  return typeof callback === "function" ? callback.apply(receiver, args) : undefined
}
