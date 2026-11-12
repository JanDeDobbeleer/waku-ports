pragma Singleton

import "NotificationRulesUtils.js" as RulesUtils

import QtQuick 6.10
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.compat

Singleton {
  id: root

  readonly property string rulesFilePath: Settings.configDir + "notification-rules.json"

  property var rules: []

  property FileView rulesFileView: FileView {
    id: rulesFile
    path: root.rulesFilePath
    watchChanges: true
    printErrors: false

    adapter: JsonAdapter {
      id: rulesAdapter
      property var rules: []
    }

    onLoaded: {
      RulesUtils.load(root, rulesFile);
    }

    onLoadFailed: function (error) {
      root.rules = [];
    }
  }

  function init() {
  }

  function save() {
    Os.mkdirp(Settings.configDir);
    root.rules = RulesUtils.filterRules(root.rules);
    rulesAdapter.rules = root.rules;
    rulesFile.writeAdapter();
  }

  function evaluate(appName: var, summary: var, body: var): var {
    return RulesUtils.evaluate(appName, summary, body, root.rules, Logger);
  }
}
