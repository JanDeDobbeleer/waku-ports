import QtQuick 6.10
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// Brightness only. Night light needs wlsunset (Wayland), so its sub-tab is gone and the tab bar with it.
ColumnLayout {
  id: root
  spacing: 0

  BrightnessSubTab {}
}
