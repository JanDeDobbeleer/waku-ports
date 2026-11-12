import Quickshell
import qs.Services.Power
import qs.Widgets

NIconButtonHot {
  property ShellScreen screen

  icon: IdleInhibitorService.isInhibited ? "keep-awake-on" : "keep-awake-off"
  hot: IdleInhibitorService.isInhibited
  onClicked: IdleInhibitorService.manualToggle()
}
