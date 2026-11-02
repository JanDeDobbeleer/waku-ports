import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginL
  width: parent.width

  // Enable/Disable Toggle
  NToggle {
    label: I18n.tr("panels.hooks.system-hooks-enable-label")
    description: I18n.tr("panels.hooks.system-hooks-enable-description")
    checked: Settings.data.hooks.enabled
    onToggled: checked => Settings.data.hooks.enabled = checked
  }

  NDivider {
    Layout.fillWidth: true
  }

  // Info section
  ColumnLayout {
    spacing: Style.marginM
    Layout.fillWidth: true

    NLabel {
      label: I18n.tr("panels.hooks.info-parameters-label")
      description: "• Wallpaper hook: $1 = wallpaper path, $2 = screen name, $3 = theme (dark/light)<br>• Theme toggle hook: $1 = true/false (Dark Mode state)<br>• Performance mode hooks: No parameters<br>• Session hook: $1 = action (shutdown/reboot)<br>Hooks run through cmd /c."
    }
  }
}
