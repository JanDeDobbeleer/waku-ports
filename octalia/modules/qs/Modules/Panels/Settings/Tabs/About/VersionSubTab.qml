import QtQuick 6.10
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.Compositor
import qs.Services.Octalia
import qs.Services.System
import qs.Services.UI
import qs.Widgets
import qs.compat

ColumnLayout {
  id: root

  property string latestVersion: GitHubService.latestVersion
  property string currentVersion: UpdateService.currentVersion
  property string commitInfo: ""
  property string qsVersion: ""
  property string qsRevision: ""

  readonly property bool isGitVersion: root.currentVersion.endsWith("-git")
  readonly property int gigaB: (1024 * 1024 * 1024)
  readonly property int gigaD: (1000 * 1000 * 1000)

  // Update status: compare versions
  readonly property bool updateAvailable: {
    if (!root.latestVersion || !root.currentVersion || root.latestVersion === I18n.tr("common.unknown"))
      return false;
    return UpdateService.compareVersions(root.latestVersion, root.currentVersion) > 0 && !root.isGitVersion;
  }
  readonly property bool isUpToDate: {
    if (!root.latestVersion || !root.currentVersion || root.latestVersion === I18n.tr("common.unknown"))
      return false;
    return UpdateService.compareVersions(root.latestVersion, root.currentVersion) <= 0;
  }

  readonly property bool qsUpdateAvailable: {
    if (!GitHubService.latestQSVersion || !root.qsVersion || GitHubService.latestQSVersion === I18n.tr("common.unknown"))
      return false;
    return UpdateService.compareVersions(GitHubService.latestQSVersion, root.qsVersion) > 0;
  }

  readonly property bool qsIsUpToDate: {
    if (!GitHubService.latestQSVersion || !root.qsVersion || GitHubService.latestQSVersion === I18n.tr("common.unknown"))
      return false;
    return UpdateService.compareVersions(GitHubService.latestQSVersion, root.qsVersion) <= 0;
  }

  spacing: Style.marginL

  function getMonitorsText(separator) {
    const sep = separator || "\n";
    const screens = Quickshell.screens || [];
    const scales = CompositorService.displayScales || {};
    let lines = [];
    for (let i = 0; i < screens.length; i++) {
      const screen = screens[i];
      const name = screen.name || "Unknown";
      const scaleData = scales[name];
      const scaleValue = (typeof scaleData === "object" && scaleData !== null) ? (scaleData.scale || 1.0) : (scaleData || 1.0);
      lines.push(name + ": " + screen.width + "x" + screen.height + " @ " + scaleValue + "x");
    }
    return lines.join(sep);
  }

  function copyInfoToClipboard() {
    let info = "Octalia Shell: " + root.currentVersion;
    if (root.isGitVersion && root.commitInfo) {
      info += " (" + root.commitInfo + ")";
    }
    info += "\n";

    if (root.qsVersion) {
      let qsV = root.qsVersion.startsWith("v") ? root.qsVersion : "v" + root.qsVersion;
      info += "Octalia QS: " + qsV;
      if (root.qsRevision) {
        info += " (" + root.qsRevision + ")";
      }
      info += "\n";
    }

    info += "\nSystem Information\n";
    info += "==================\n";
    info += "OS: " + HostService.osPretty + "\n";
    info += "Host: " + (HostService.hostName || "N/A") + "\n";
    const monitors = getMonitorsText("\n").split("\n");
    for (const mon of monitors) {
      info += "Monitor: " + mon + "\n";
    }
    info += "\nSettings\n";
    info += "========\n";
    info += "UI Scale: " + Settings.data.general.scaleRatio + "\n";
    info += "Default Font: " + (Settings.data.ui.fontDefault || "default") + " @ " + Settings.data.ui.fontDefaultScale + "x\n";
    info += "Fixed Font: " + (Settings.data.ui.fontFixed || "default") + " @ " + Settings.data.ui.fontFixedScale + "x\n";
    Os.copy(info);
    ToastService.showNotice(I18n.tr("panels.about.title"), I18n.tr("panels.about.info-copied"));
  }

  Component.onCompleted: {
    Logger.d("VersionSubTab", "Current version:", root.currentVersion);
    // Only fetch commit info for -git versions
    if (root.isGitVersion)
      fetchGitCommit();
  }

  function fetchGitCommit() {
    var shellDir = Quickshell.shellDir || "";
    Logger.d("VersionSubTab", "fetchGitCommit - shellDir:", shellDir);
    if (!shellDir) {
      Logger.d("VersionSubTab", "fetchGitCommit - Cannot determine shell directory, skipping git commit fetch");
      return;
    }

    gitProcess.workingDirectory = shellDir;
    gitProcess.running = true;
  }

  Process {
    id: gitProcess
    command: ["git", "rev-parse", "--short", "HEAD"]
    running: false

    onExited: function (exitCode) {
      Logger.d("VersionSubTab", "gitProcess - Process exited with code:", exitCode);
      if (exitCode === 0) {
        var gitOutput = stdout.text.trim();
        Logger.d("VersionSubTab", "gitProcess - gitOutput:", gitOutput);
        if (gitOutput) {
          root.commitInfo = gitOutput;
          Logger.d("VersionSubTab", "gitProcess - Set commitInfo to:", root.commitInfo);
        }
      } else {
        Logger.d("VersionSubTab", "gitProcess - Git command failed. Exit code:", exitCode);
      }
    }

    stdout: StdioCollector {}
    stderr: StdioCollector {}
  }

  RowLayout {
    Layout.alignment: Qt.AlignHCenter
    spacing: Style.marginXL

    // Octalia logo
    Image {
      source: ShellUrl.dir + "/Assets/octalia.svg"
      width: 96 * Style.uiScaleRatio
      height: width
      fillMode: Image.PreserveAspectFit
      sourceSize.width: width
      sourceSize.height: height
      mipmap: true
      smooth: true
      Layout.alignment: Qt.AlignBottom
      rotation: Settings.isDebug ? 180 : 0

      Behavior on rotation {
        NumberAnimation {
          duration: Style.animationSlowest
          easing.type: Easing.OutBack
        }
      }

      property int debugTapCount: 0

      Timer {
        id: debugTapTimer
        interval: 5000
        onTriggered: parent.debugTapCount = 0
      }

      MouseArea {
        anchors.fill: parent
        onClicked: {
          if (parent.debugTapCount === 0) {
            debugTapTimer.restart();
          }
          parent.debugTapCount++;
          if (parent.debugTapCount >= 8) {
            parent.debugTapCount = 0;
            debugTapTimer.stop();
            Settings.isDebug = !Settings.isDebug;
            if (Settings.isDebug) {
              ToastService.showNotice("Debug", I18n.tr("panels.about.debug-enabled"));
            } else {
              ToastService.showNotice("Debug", I18n.tr("panels.about.debug-disabled"));
            }
          }
        }
      }
    }

    ColumnLayout {
      NHeader {
        label: "Octalia Shell"
      }

      // Versions
      GridLayout {
        columns: 2
        rowSpacing: Style.marginXS
        columnSpacing: Style.marginM

        // Installed Version (Shell)
        NText {
          text: "Octalia Shell:"
          color: Color.mOnSurfaceVariant
          Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
        }

        RowLayout {
          spacing: Style.marginS

          NText {
            text: root.currentVersion
            color: Color.mOnSurface
            font.weight: Style.fontWeightBold
          }

          // Git commit in parentheses
          NText {
            id: commitText
            visible: root.isGitVersion && root.commitInfo !== ""
            text: "(" + (root.commitInfo || I18n.tr("common.loading")) + ")"
            color: commitMouseArea.containsMouse ? Color.mPrimary : Color.mOnSurfaceVariant
            pointSize: Style.fontSizeXS
            font.underline: commitMouseArea.containsMouse && root.commitInfo

            MouseArea {
              id: commitMouseArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: root.commitInfo ? Qt.PointingHandCursor : Qt.ArrowCursor
              onClicked: {
                if (root.commitInfo) {
                  Os.open("https://github.com/noctalia-dev/noctalia-shell/commit/" + root.commitInfo);
                }
              }
            }
          }

          // Update status indicator
          NIcon {
            id: upToDateIcon
            visible: root.isUpToDate
            icon: "circle-check"
            pointSize: Style.fontSizeM
            color: Color.mPrimary
          }

          NIcon {
            id: updateAvailableIcon
            visible: root.updateAvailable
            icon: "arrow-up-circle"
            pointSize: Style.fontSizeS
            color: Color.mPrimary
          }
        }

        // Latest Version (Shell)
        NText {
          visible: root.updateAvailable
          text: I18n.tr("panels.about.octalia-available")
          color: Color.mOnSurfaceVariant
          Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
        }

        NText {
          visible: root.updateAvailable
          text: root.latestVersion
          color: Color.mOnSurface
          font.weight: Style.fontWeightBold
        }

        // Divider-like spacing
        Item {
          visible: root.qsUpdateAvailable || root.updateAvailable
          Layout.columnSpan: 2
          Layout.preferredHeight: Style.marginXS
        }

        // Quickshell Version
        NText {
          visible: root.qsVersion !== ""
          text: "Octalia QS:"
          color: Color.mOnSurfaceVariant
          Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
        }

        RowLayout {
          visible: root.qsVersion !== ""
          spacing: Style.marginS

          NText {
            text: root.qsVersion.startsWith("v") ? root.qsVersion : "v" + root.qsVersion
            color: Color.mOnSurface
            font.weight: Style.fontWeightBold
          }

          // Git revision in parentheses
          NText {
            id: qsRevisionText
            visible: root.qsRevision !== ""
            text: "(" + root.qsRevision + ")"
            color: qsRevisionMouseArea.containsMouse ? Color.mPrimary : Color.mOnSurfaceVariant
            pointSize: Style.fontSizeXS
            font.underline: qsRevisionMouseArea.containsMouse

            MouseArea {
              id: qsRevisionMouseArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                Os.open("https://github.com/noctalia-dev/noctalia-qs/commit/" + root.qsRevision);
              }
            }
          }

          // Update status indicator
          NIcon {
            id: qsUpToDateIcon
            visible: root.qsIsUpToDate
            icon: "circle-check"
            pointSize: Style.fontSizeM
            color: Color.mPrimary
          }

          NIcon {
            id: qsUpdateAvailableIcon
            visible: root.qsUpdateAvailable
            icon: "arrow-up-circle"
            pointSize: Style.fontSizeS
            color: Color.mPrimary
          }
        }

        // Latest Quickshell Version
        NText {
          visible: root.qsUpdateAvailable
          text: I18n.tr("panels.about.octalia-available")
          color: Color.mOnSurfaceVariant
          Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
        }

        NText {
          visible: root.qsUpdateAvailable
          text: GitHubService.latestQSVersion
          color: Color.mOnSurface
          font.weight: Style.fontWeightBold
        }
      }
    }
  }

  GridLayout {
    id: actionsGrid
    Layout.alignment: Qt.AlignHCenter
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
    rowSpacing: Style.marginM
    columnSpacing: Style.marginM

    columns: (changelogBtn.implicitWidth + copyBtn.implicitWidth + supportBtn.implicitWidth + 2 * columnSpacing) < root.width ? 3 : 1

    NButton {
      id: changelogBtn
      icon: "sparkles"
      text: I18n.tr("panels.about.changelog")
      outlined: true
      Layout.alignment: Qt.AlignHCenter
      onClicked: {
        var screen = PanelService.openedPanel?.screen || SettingsPanelService.settingsWindow?.screen || PanelService.findScreenForPanels();
        SettingsPanelService.close(screen);
        UpdateService.viewChangelog(screen);
      }
    }

    NButton {
      id: copyBtn
      icon: "copy"
      text: I18n.tr("panels.about.copy-info")
      outlined: true
      Layout.alignment: Qt.AlignHCenter
      onClicked: root.copyInfoToClipboard()
    }

    NButton {
      id: supportBtn
      icon: "heart"
      text: I18n.tr("panels.about.support")
      outlined: true
      Layout.alignment: Qt.AlignHCenter
      onClicked: {
        Os.open("https://buymeacoffee.com/noctalia");
        ToastService.showNotice(I18n.tr("panels.about.support"), I18n.tr("toast.donation-opened"));
      }
    }
  }

  NToggle {
    Layout.fillWidth: true
    label: I18n.tr("panels.about.changelog-on-startup")
    description: I18n.tr("panels.about.changelog-on-startup-desc")
    checked: Settings.data.general.showChangelogOnStartup
    onToggled: checked => Settings.data.general.showChangelogOnStartup = checked
  }

  // System Information Section
  NDivider {
    Layout.fillWidth: true
  }

  NHeader {
    label: I18n.tr("panels.about.system-title")
  }

  GridLayout {
    id: sysInfo
    readonly property real textSize: Style.fontSizeS

    Layout.fillWidth: true
    columns: 2
    rowSpacing: Style.marginXS
    columnSpacing: Style.marginM

    NText {
      text: I18n.tr("panels.about.system-os")
      color: Color.mOnSurfaceVariant
      pointSize: sysInfo.textSize
    }
    NText {
      text: HostService.osPretty
      color: Color.mOnSurface
      pointSize: sysInfo.textSize
      Layout.fillWidth: true
      wrapMode: Text.Wrap
    }

    NText {
      text: I18n.tr("panels.about.system-host")
      color: Color.mOnSurfaceVariant
      pointSize: sysInfo.textSize
    }
    NText {
      text: HostService.hostName || "N/A"
      color: Color.mOnSurface
      pointSize: sysInfo.textSize
      Layout.fillWidth: true
      wrapMode: Text.Wrap
    }

    // Monitors (2 items per screen: label + value)
    Repeater {
      model: Quickshell.screens.length * 2

      NText {
        readonly property int screenIndex: Math.floor(index / 2)
        readonly property bool isLabel: index % 2 === 0
        readonly property var screen: Quickshell.screens[screenIndex]

        text: {
          if (isLabel)
            return I18n.tr("panels.about.system-monitor");
          const name = screen?.name || "Unknown";
          const scales = CompositorService.displayScales || {};
          const scaleData = scales[name];
          const scaleValue = (typeof scaleData === "object" && scaleData !== null) ? (scaleData.scale || 1.0) : (scaleData || 1.0);
          return name + ": " + (screen?.width || 0) + "x" + (screen?.height || 0) + " @ " + scaleValue + "x";
        }
        color: isLabel ? Color.mOnSurfaceVariant : Color.mOnSurface
        pointSize: sysInfo.textSize
        Layout.fillWidth: !isLabel
        wrapMode: Text.Wrap
      }
    }
  }
}
