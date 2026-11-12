.pragma library

function invoke(target, methodName, ...args) {
  return target[methodName](...args);
}
