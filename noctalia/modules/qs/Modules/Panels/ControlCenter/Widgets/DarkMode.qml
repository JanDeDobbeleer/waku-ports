import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.Power
import qs.Widgets

NIconButtonHot {
  property ShellScreen screen

  icon: "dark-mode"
  onClicked: Settings.data.colorSchemes.darkMode = !Settings.data.colorSchemes.darkMode
}
