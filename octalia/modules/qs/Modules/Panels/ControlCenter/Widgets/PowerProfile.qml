import Quickshell
import qs.Services.Power
import qs.Widgets

// Performance
NIconButtonHot {
  property ShellScreen screen

  readonly property bool hasPP: PowerProfileService.available

  enabled: hasPP
  icon: PowerProfileService.getIcon(undefined)
  hot: !PowerProfileService.isDefault()
  onClicked: PowerProfileService.cycleProfile()
}
