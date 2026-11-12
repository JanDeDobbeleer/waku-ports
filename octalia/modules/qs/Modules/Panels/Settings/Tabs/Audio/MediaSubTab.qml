import QtQuick 6.10
import QtQuick.Layouts
import qs.Commons
import qs.Services.Media
import qs.Widgets
import "../../SettingsValue.js" as SettingsValue

ColumnLayout {
  id: root
  spacing: Style.marginL
  Layout.fillWidth: true

  // Preferred player
  NTextInput {
    label: I18n.tr("panels.audio.media-primary-player-label")
    description: I18n.tr("panels.audio.media-primary-player-description")
    placeholderText: I18n.tr("panels.audio.media-primary-player-placeholder")
    text: Settings.data.audio.preferredPlayer
    defaultValue: Settings.getDefaultValue("audio.preferredPlayer")
    onTextChanged: {
      Settings.data.audio.preferredPlayer = text;
      MediaService.updateCurrentPlayer();
    }
  }

  // Blacklist editor
  ColumnLayout {
    spacing: Style.marginS
    Layout.fillWidth: true

    NTextInputButton {
      id: blacklistInput
      label: I18n.tr("panels.audio.media-excluded-player-label")
      description: I18n.tr("panels.audio.media-excluded-player-description")
      placeholderText: I18n.tr("panels.audio.media-excluded-player-placeholder")
      buttonIcon: "add"
      Layout.fillWidth: true
      onButtonClicked: SettingsValue.addMediaBlacklistEntry(blacklistInput, Settings.data.audio, MediaService)
    }

    // Current blacklist entries
    Flow {
      Layout.fillWidth: true
      Layout.leftMargin: Style.marginS
      spacing: Style.marginS

      Repeater {
        model: Settings.data.audio.mprisBlacklist
        delegate: Rectangle {
          id: blacklistEntry
          required property string modelData
          property real pad: Style.marginS
          color: Qt.alpha(Color.mOnSurface, 0.125)
          border.color: Qt.alpha(Color.mOnSurface, Style.opacityLight)
          border.width: Style.borderS

          RowLayout {
            id: chipRow
            spacing: Style.marginXS
            anchors.fill: parent
            anchors.margins: blacklistEntry.pad

            NText {
              text: blacklistEntry.modelData
              color: Color.mOnSurface
              pointSize: Style.fontSizeS
              Layout.alignment: Qt.AlignVCenter
              Layout.leftMargin: Style.marginS
            }

            NIconButton {
              icon: "close"
              baseSize: Style.baseWidgetSize * 0.8
              Layout.alignment: Qt.AlignVCenter
              Layout.rightMargin: Style.marginXS
              onClicked: SettingsValue.removeMediaBlacklistEntry(Settings.data.audio, MediaService, blacklistEntry.modelData)
            }
          }

          implicitWidth: chipRow.implicitWidth + pad * 2
          implicitHeight: Math.max(chipRow.implicitHeight + pad * 2, Style.baseWidgetSize * 0.8)
          radius: Style.radiusM
        }
      }
    }
  }
}
