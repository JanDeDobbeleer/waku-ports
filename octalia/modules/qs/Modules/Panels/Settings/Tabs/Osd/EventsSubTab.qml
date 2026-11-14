pragma ComponentBehavior: Bound

import QtQuick 6.10
import QtQuick.Layouts
import qs.Commons
import qs.Modules.OSD
import qs.Widgets
import "../../SettingsValue.js" as SettingsValue

ColumnLayout {
  id: root
  spacing: Style.marginL
  Layout.fillWidth: true

  property var addType
  property var removeType

  Repeater {
    model: [
      {
        type: OSD.Type.Volume,
        key: "types-volume"
      },
      {
        type: OSD.Type.InputVolume,
        key: "types-input-volume"
      },
      {
        type: OSD.Type.Brightness,
        key: "types-brightness"
      },
      {
        type: OSD.Type.LockKey,
        key: "types-lockkey"
      }
    ]
    delegate: NCheckbox {
      required property int type
      required property string key
      Layout.fillWidth: true
      label: I18n.tr("panels.osd." + key + "-label")
      description: I18n.tr("panels.osd." + key + "-description")
      checked: (Settings.data.osd.enabledTypes || []).includes(type)
      onToggled: checked => {
                   if (checked) {
                     Settings.data.osd.enabledTypes = SettingsValue.invoke(root, "addType", Settings.data.osd.enabledTypes, type);
                   } else {
                     Settings.data.osd.enabledTypes = SettingsValue.invoke(root, "removeType", Settings.data.osd.enabledTypes, type);
                   }
                 }
    }
  }
}
