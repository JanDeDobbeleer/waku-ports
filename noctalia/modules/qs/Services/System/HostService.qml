pragma Singleton

import QtQuick
import Quickshell
import waku.services as S
import qs.Commons
import qs.compat

// Noctalia's HostService on Windows: the user and machine names come from the engine's ControlCenter
// (the Windows account) and the environment. There is no distro, so `osPretty` is "Windows" and
// `osLogo` is the Windows logo.
Singleton {
  id: root

  // Public properties
  readonly property string osPretty: "Windows"
  readonly property string osLogo: Qt.resolvedUrl(Quickshell.shellDir + "/Assets/windows.svg")
  readonly property bool isNixOS: false
  readonly property bool isReady: true

  // User info
  readonly property string username: (S.ControlCenter.userName || Quickshell.env("USERNAME") || "")
  readonly property string envRealName: (Quickshell.env("NOCTALIA_REALNAME") || "")
  readonly property string realName: S.ControlCenter.userName

  // Machine info
  readonly property string hostName: (Quickshell.env("COMPUTERNAME") || "")

  property string pendingLogoName: ""

  readonly property string displayName: {
    if (envRealName.length > 0)
      return envRealName;
    if (realName.length > 0)
      return realName;
    if (username.length > 0)
      return username;
    return "User";
  }

  function init() {
    Logger.i("HostService", "Service started");
  }
}
