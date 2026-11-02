pragma Singleton

import QtQuick
import Quickshell
import qs.Commons
import qs.compat

// The port fetches no supporter list. The names stay so the About tab loads.
Singleton {
  id: root

  property bool isFetching: false
  property bool isInitialized: false

  readonly property var data: ({})

  property var supporters: []
  property var cachedAvatars: ({})
  property bool avatarsCached: false

  function init() {
    isInitialized = true;
  }

  function loadFromCache() {
  }

  function fetchFromApi() {
  }

  function saveData() {
  }

  function getAvatarPath(username) {
    return "";
  }

  function cacheAvatars() {
  }
}
