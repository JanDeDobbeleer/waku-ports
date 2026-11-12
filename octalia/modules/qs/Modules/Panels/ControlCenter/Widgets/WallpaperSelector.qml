import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

NIconButtonHot {
  property ShellScreen screen

  enabled: Settings.data.wallpaper.enabled
  icon: "wallpaper-selector"
  onClicked: PanelService.getPanel("wallpaperPanel", screen)?.toggle()
  onRightClicked: WallpaperService.setRandomWallpaper()
}
