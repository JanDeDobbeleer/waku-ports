pragma Singleton

import QtQuick
import Quickshell
import qs.Commons
import qs.compat

// The port makes no calls to GitHub: no version check, no contributor list. The names stay so the
// About tab loads; it shows "unknown" versions and no contributors.
Singleton {
  id: root

  property bool isFetchingData: false
  readonly property var data: ({})

  property string latestVersion: I18n.tr("common.unknown")
  property string latestQSVersion: I18n.tr("common.unknown")
  property var contributors: []

  property var cachedAvatars: ({})
  property bool avatarsCached: false
  property bool isInitialized: false

  function init() {
    isInitialized = true;
  }

  function loadFromCache() {
  }

  function fetchFromGitHub() {
  }

  function saveData() {
  }

  function checkAndSaveData() {
  }

  function resetCache() {
  }

  function getAvatarPath(username) {
    return "";
  }

  function cacheTopContributorAvatars() {
  }
}
