pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import Quickshell
import qs.Ui

BarWidget {
  id: root
  moduleName: "nomarchy.menu"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    // Windows port: the Windows logo replaces the Nomarchy glyph, painted in the bar foreground.
    iconComponent: Component {
      Item {
        Image {
          id: logo
          anchors.fill: parent
          source: "file:///" + String(Quickshell.shellDir).replace(/\\/g, "/") + "/assets/windows.svg"
          sourceSize.width: width
          sourceSize.height: height
          fillMode: Image.PreserveAspectFit
          visible: false
          layer.enabled: true
        }
        Rectangle {
          anchors.fill: logo
          color: button.foreground
          layer.enabled: true
          layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: logo
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
          }
        }
      }
    }
    onPressed: function(button) {
      if (!root.bar) return
      // Windows port: the shell host is called directly (nomarchy-shell and xdg-terminal-exec are Linux
      // programs), and a right click opens Windows Terminal.
      if (button === Qt.RightButton) Quickshell.execDetached(["wt.exe"])
      else if (BarValues.hasShell(root.bar)) BarValues.toggle(root.bar, "nomarchy.menu", "{\"menu\":\"root\"}")
    }
  }
}
