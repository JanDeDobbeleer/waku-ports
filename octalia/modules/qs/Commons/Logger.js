.pragma library
.import qs.Commons 1.0 as Commons
.import "LoggerUtils.js" as Utils

function _formatMessage(...args) {
  return Utils.format(args, Commons.Time.getFormattedTimestamp(undefined));
}

function _getStackTrace() {
  return Utils.getStackTrace();
}

function d(...args) {
  if (Commons.Settings?.isDebug)
    console.debug(Utils.format(args, Commons.Time.getFormattedTimestamp(undefined)));
}

function i(...args) {
  console.info(Utils.format(args, Commons.Time.getFormattedTimestamp(undefined)));
}

function w(...args) {
  console.warn(Utils.format(args, Commons.Time.getFormattedTimestamp(undefined)));
}

function e(...args) {
  console.error(Utils.format(args, Commons.Time.getFormattedTimestamp(undefined)));
}

function callStack() {
  var stack = _getStackTrace();
  i("Debug", "--------------------------");
  i("Debug", "Current call stack");
  var stackLines = stack.split("\n");
  for (var n = 0; n < stackLines.length; n++) {
    var line = stackLines[n].trim();
    if (line.length > 0)
      i("Debug", `- ${line}`);
  }
  i("Debug", "--------------------------");
}
