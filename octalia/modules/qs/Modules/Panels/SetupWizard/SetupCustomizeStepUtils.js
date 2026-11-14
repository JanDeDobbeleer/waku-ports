.pragma library

function field(object, name) {
  return object ? object[name] : undefined;
}

function select(option) {
  const callback = field(option, "select");
  if (typeof callback === "function")
    callback();
}
