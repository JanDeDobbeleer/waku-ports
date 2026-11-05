import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.Power
import qs.Widgets

NIconButtonHot {
  property ShellScreen screen

  icon: PowerProfileService.octaliaPerformanceMode ? "rocket" : "rocket-off"
  hot: PowerProfileService.octaliaPerformanceMode
  onClicked: PowerProfileService.toggleOctaliaPerformance()
}
