.pragma library

function format(args, t) {
  if (args.length > 1) {
    const maxLength = 14;
    const module = args.shift().substring(0, maxLength).padStart(maxLength, " ");
    return `\x1b[36m[${t}]\x1b[0m \x1b[35m${module}\x1b[0m ` + args.join(" ");
  }
  return `[\x1b[36m[${t}]\x1b[0m ` + args.join(" ");
}

function getStackTrace() {
  try { throw new Error("Stack trace"); }
  catch (e) { return e.stack; }
}
