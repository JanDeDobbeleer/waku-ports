pragma Singleton

import "SettingsSearchUtils.js" as SearchUtils

import QtQuick 6.10
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.Compositor
import qs.Services.Power
import qs.Services.System

Singleton {
  id: root

  property var searchIndex: []

  FileView {
    id: searchIndexFile
    path: Quickshell.shellDir + "/Assets/settings-search-index.json"
    watchChanges: false
    printErrors: false

    onLoaded: {
      SearchUtils.loadSearchIndex(root, searchIndexFile);
    }
  }

  readonly property var _roots: ({
                                   "CompositorService": CompositorService,
                                   "Settings": Settings,
                                   "Quickshell": Quickshell,
                                   "IdleService": IdleService,
                                   "SystemStatService": SystemStatService,
                                   "SoundService": SoundService
                                 })

  function isEntryVisible(entry: var): bool {
    return SearchUtils.isEntryVisible(entry, _roots);
  }

  function _resolveValue(path: var): var {
    return SearchUtils._resolveValue(path, _roots);
  }

  function _splitAnd(expr: var): var {
    return SearchUtils._splitAnd(expr);
  }

  function _evalCondition(expr: var): bool {
    return SearchUtils._evalCondition(expr, _roots);
  }
}
