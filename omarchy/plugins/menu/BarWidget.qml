import QtQuick
import Quickshell
import qs.Ui

BarWidget {
  id: root
  moduleName: "omarchy.menu"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "\ue900"
    fontFamily: "omarchy"
    onPressed: function(button) {
      if (!root.bar) return
      // Windows port: the shell host is called directly (omarchy-shell and xdg-terminal-exec are Linux
      // programs), and a right click opens Windows Terminal.
      if (button === Qt.RightButton) Quickshell.execDetached(["wt.exe"])
      else if (root.bar.shell) root.bar.shell.toggle("omarchy.menu", "{\"menu\":\"root\"}")
    }
  }
}
