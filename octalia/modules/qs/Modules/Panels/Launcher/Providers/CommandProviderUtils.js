.pragma library

function field(object, name) {
  return object ? object[name] : undefined;
}

function setSearchText(launcher, text) {
  const setText = field(launcher, "setSearchText");
  if (setText)
    setText(text);
}

function commandResult(query, launcher, quickshell, logger, name, description, icon) {
  const expression = query.substring(4).trim();
  return {
    "name": name,
    "description": description,
    "icon": icon,
    "isTablerIcon": true,
    "isImage": false,
    "onActivate": function () {
      launcher.closeImmediately();
      Qt.callLater(function () {
        logger.d("CommandProvider", "Executing shell command: " + expression);
        quickshell.execDetached(["cmd", "/c", expression]);
      });
    }
  };
}
