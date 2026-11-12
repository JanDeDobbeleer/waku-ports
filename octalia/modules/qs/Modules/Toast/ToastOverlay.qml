import QtQuick 6.10
import Quickshell
import qs.Commons
import "ToastOverlayUtils.js" as ToastOverlayUtils

Variants {
  model: ToastOverlayUtils.visibleScreens(Quickshell.screens, Settings.data.notifications.monitors)

  delegate: ToastScreen {
    required property ShellScreen modelData
    screen: modelData
  }
}
