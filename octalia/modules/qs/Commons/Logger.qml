pragma Singleton

import Quickshell
import qs.Commons
import qs.compat

Singleton {
  id: root

  function _formatMessage(...args) {
    var module;
    var t = Time.getFormattedTimestamp();
    if (args.length > 1) {
      const maxLength = 14;
      module = args.shift().substring(0, maxLength).padStart(maxLength, " ");
      return `\x1b[36m[${t}]\x1b[0m \x1b[35m${module}\x1b[0m ` + args.join(" ");
    } else {
      return `[\x1b[36m[${t}]\x1b[0m ` + args.join(" ");
    }
  }

  function _getStackTrace() {
    try {
      throw new Error("Stack trace");
    } catch (e) {
      return e.stack;
    }
  }

  // Debug log (only when Settings.isDebug is true)
  function d(...args) {
    var msg;
    if (Settings?.isDebug) {
      msg = _formatMessage(...args);
      console.debug(msg);
    }
  }

  // Info log (always visible)
  function i(...args) {
    var msg = _formatMessage(...args);
    console.info(msg);
  }

  // Warning log (always visible)
  function w(...args) {
    var msg = _formatMessage(...args);
    console.warn(msg);
  }

  // Error log (always visible)
  function e(...args) {
    var msg = _formatMessage(...args);
    console.error(msg);
  }

  function callStack() {
    var i, line;
    var stack = _getStackTrace();
    Logger.i("Debug", "--------------------------");
    Logger.i("Debug", "Current call stack");
    // Split the stack into lines and log each one
    var stackLines = stack.split('\n');
    for (i = 0; i < stackLines.length; i++) {
      line = stackLines[i].trim(); // Remove leading/trailing whitespace
      if (line.length > 0) {
        // Only log non-empty lines
        Logger.i("Debug", `- ${line}`);
      }
    }
    Logger.i("Debug", "--------------------------");
  }
}
