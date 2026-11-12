import QtQuick 6.10
import QtQuick.Layouts
import Quickshell.Io
import qs.Commons
import qs.Modules.Panels.Settings
import qs.Services.System
import qs.Services.UI
import qs.Widgets
import "ProfileCardUtils.js" as PanelCardUtils

// Header card with avatar, user and quick actions
NBox {
  id: root

  property string uptimeText: "--"
  property var controlCenterScreen

  RowLayout {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.margins: Style.marginM
    spacing: Style.marginM

    NImageRounded {
      Layout.preferredWidth: Math.round(Style.baseWidgetSize * 1.25 * Style.uiScaleRatio)
      Layout.preferredHeight: Math.round(Style.baseWidgetSize * 1.25 * Style.uiScaleRatio)
      radius: Layout.preferredWidth / 2
      imagePath: Settings.preprocessPath(Settings.data.general.avatarImage)
      fallbackIcon: "person"
      borderColor: Color.mPrimary
      borderWidth: Style.borderS * 1.5
    }

    ColumnLayout {
      Layout.fillWidth: true
      Layout.minimumWidth: 0
      spacing: Style.marginXXS
      NText {
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        text: HostService.displayName
        font.weight: Style.fontWeightBold
      }
      NText {
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        text: I18n.trArgs("system.uptime", {
                        "uptime": root.uptimeText
                      })
        pointSize: Style.fontSizeS
        color: Color.mOnSurfaceVariant
      }
    }

    RowLayout {
      spacing: Style.marginS
      Layout.fillWidth: false
      Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
      Item {
        Layout.fillWidth: true
      }
      NIconButton {
        icon: "settings"
        onClicked: {
          // Better close the control center in case the settings open in a separate window
          PanelCardUtils.closePanel(PanelService.openedPanel);

          var panel = PanelService.getPanel("settingsPanel", root.controlCenterScreen);
          PanelService.openSettingsPanel(panel, SettingsPanel.Tab.General);
        }
      }

      NIconButton {
        icon: "power"
        onClicked: {
          PanelService.invokePanel(PanelService.getPanel("sessionMenuPanel", root.controlCenterScreen), "open", []);
          PanelService.invokePanel(PanelService.getPanel("controlCenterPanel", root.controlCenterScreen), "close", []);
        }
      }

      NIconButton {
        icon: "close"
        onClicked: {
          PanelService.invokePanel(PanelService.getPanel("controlCenterPanel", root.controlCenterScreen), "close", []);
        }
      }
    }
  }

  // ----------------------------------
  // Uptime
  Timer {
    interval: 60000
    repeat: true
    running: true
    onTriggered: uptimeProcess.running = true
  }

  Process {
    id: uptimeProcess
    // Seconds since boot; the Windows counterpart of /proc/uptime. A comma decimal parses as seconds.
    command: ["powershell", "-NoProfile", "-NonInteractive", "-Command", "[int]((Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime).TotalSeconds"]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        var uptimeSeconds = parseFloat(this.text.trim().split(' ')[0]);
        root.uptimeText = Time.formatVagueHumanReadableDuration(uptimeSeconds);
        uptimeProcess.running = false;
      }
    }
  }

  function updateSystemInfo() {
    uptimeProcess.running = true;
  }
}
