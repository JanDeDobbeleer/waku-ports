import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginL
  Layout.fillWidth: true

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("panels.system.octalia-performance-disable-wallpaper-label")
    description: I18n.tr("panels.system.octalia-performance-disable-wallpaper-description")
    checked: !Settings.data.octaliaPerformance.disableWallpaper
    defaultValue: !Settings.getDefaultValue("octaliaPerformance.disableWallpaper")
    onToggled: checked => Settings.data.octaliaPerformance.disableWallpaper = !checked
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("panels.system.octalia-performance-disable-desktop-widgets-label")
    description: I18n.tr("panels.system.octalia-performance-disable-desktop-widgets-description")
    checked: !Settings.data.octaliaPerformance.disableDesktopWidgets
    defaultValue: !Settings.getDefaultValue("octaliaPerformance.disableDesktopWidgets")
    onToggled: checked => Settings.data.octaliaPerformance.disableDesktopWidgets = !checked
  }
}
