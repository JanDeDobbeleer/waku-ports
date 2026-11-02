import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.Power
import qs.Widgets

NIconButtonHot {
  property ShellScreen screen

  icon: PowerProfileService.noctaliaPerformanceMode ? "rocket" : "rocket-off"
  hot: PowerProfileService.noctaliaPerformanceMode
  onClicked: PowerProfileService.toggleNoctaliaPerformance()
}
