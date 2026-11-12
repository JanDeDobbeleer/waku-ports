.pragma library

function functionNames(object) {
  var names = []
  for (var key in object) {
    if (typeof object[key] === "function") names.push(key)
  }
  return names
}

function leads(handler, handlers) {
  if (!handler.target || handlers.indexOf(handler) === -1) return false
  for (var i = 0; i < handlers.length; i++) {
    var other = handlers[i]
    if (other && other.target === handler.target) return other === handler
  }
  return false
}

function handlerFor(target, handlers) {
  for (var i = 0; i < handlers.length; i++) {
    var handler = handlers[i]
    if (handler && handler.enabled && handler.target === target) return handler
  }
  return null
}

function declaredFunctions(handler, builtins) {
  return functionNames(handler).filter(function(name) {
    return builtins.indexOf(name) === -1 && !/Changed$/.test(name)
  })
}

function call(target, method, args, handlers, builtins) {
  var handler = handlerFor(target, handlers)
  if (!handler) return { ran: false }
  if (declaredFunctions(handler, builtins).indexOf(method) === -1) return { ran: false }
  if (handler[method].length !== args.length) return { ran: false }

  var result
  try {
    result = handler[method].apply(handler, args)
  } catch (error) {
    console.warn("ipc " + target + " " + method + " failed: " + error)
    return { ran: true, output: "" }
  }
  return { ran: true, output: result === undefined || result === null ? "" : String(result) }
}
