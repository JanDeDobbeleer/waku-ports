pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import waku.services as S
import qs.Commons
import qs.Commons as Commons
import qs.Ui

Panel {
  id: root
  moduleName: "nomarchy.controls"
  ipcTarget: "nomarchy.controls"

  readonly property color foreground: bar ? BarValues.foreground(bar) : Commons.Color.foreground
  readonly property string family: bar ? BarValues.fontFamily(bar) : Style.font.family
  property int selectedIndex: 0
  readonly property bool stayAwake: BarValues.stayAwake(root.bar)

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onOpenedChanged: {
    if (opened) closeTimer.stop()
    else closeTimer.restart()
  }

  Timer {
    id: closeTimer
    interval: Style.duration(300)
  }

  function adjustBrightness(delta: int): void {
    if (S.ControlCenter.brightnessAvailable)
      S.ControlCenter.setBrightness(Math.max(0, Math.min(100, S.ControlCenter.brightness + delta)))
  }

  function activate(index: int): void {
    if (index === 1) {
      if (S.ControlCenter.available) S.ControlCenter.toggleTheme()
      return
    }
    if (index === 2) {
      BarValues.setStayAwake(root.bar, !root.stayAwake)
      return
    }
    // Windows' own flyouts and pages; each one has no other entry in the shell.
    var targets = ["ms-settings-displays-topology:", "ms-settings-connectabledevices:devicediscovery",
      "ms-settings:network-airplanemode", "devmgmt.msc", "ms-settings:"]
    if (index >= 3 && index < 3 + targets.length) {
      root.close()
      const target = targets[index - 3]
      Quickshell.execDetached([target.endsWith(".msc") ? "mmc.exe" : "explorer.exe", target])
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰢻"
    tooltipText: Commons.I18n.t("controls.title")
    onPressed: root.toggle()
  }

  Loader {
    active: root.opened || closeTimer.running
    sourceComponent: Component {
      KeyboardPanel {
        id: panel
        anchorItem: button
        owner: root
        bar: root.bar
        open: root.opened
        focusTarget: panel.loadedContent
        contentWidth: panel.fittedContentWidth(Style.space(320), undefined)
        contentHeight: panel.fittedContentHeight(panel.loadedContentHeight, undefined)
        panelContent: controls
      }
    }
  }

  Component {
    id: controls
    PanelKeyCatcher {
      id: keys
      anchors.fill: parent
      implicitHeight: column.implicitHeight
      onMoveRequested: function(dx, dy) {
        if (dy !== 0) root.selectedIndex = Math.max(0, Math.min(7, root.selectedIndex + dy))
        else if (dx !== 0 && root.selectedIndex === 0) root.adjustBrightness(dx * 5)
      }
      onActivateRequested: root.activate(root.selectedIndex)
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: column
        width: parent.width
        spacing: Style.space(10)

        Text {
          text: Commons.I18n.t("controls.title")
          color: root.foreground
          font.family: root.family
          font.pixelSize: Style.font.title
          font.bold: true
        }

        PanelSeparator { foreground: root.foreground }

        Text {
          text: S.ControlCenter.brightnessAvailable
            ? Commons.I18n.t("controls.brightness") + "  " + Commons.I18n.formatNumber(Math.round(brightnessSlider.dragging ? brightnessSlider.liveValue : S.ControlCenter.brightness)) + "%"
            : Commons.I18n.t("controls.brightnessUnavailable")
          color: root.foreground
          font.family: root.family
          font.pixelSize: Style.font.body
        }

        CursorSurface {
          width: parent.width
          height: brightnessSlider.implicitHeight + Style.spacing.controlGap
          hasCursor: root.selectedIndex === 0
          foreground: root.foreground
          outline: true

          PanelSlider {
            id: brightnessSlider
            bar: root.bar
            anchors.fill: parent
            anchors.leftMargin: Style.space(6)
            anchors.rightMargin: Style.space(6)
            minimum: 0
            maximum: 100
            step: 5
            integer: true
            value: S.ControlCenter.brightness
            enabled: S.ControlCenter.brightnessAvailable
            opacity: enabled ? 1 : 0.5
            onMoved: function(value) { S.ControlCenter.setBrightness(value) }
          }

          HoverHandler {
            onHoveredChanged: if (hovered) root.selectedIndex = 0
          }
        }

        Button {
          width: column.width
          text: Commons.I18n.t(S.ControlCenter.darkMode ? "controls.darkOn" : "controls.darkOff")
          foreground: root.foreground
          fontFamily: root.family
          leftAlign: true
          bordered: true
          enabled: S.ControlCenter.available
          active: S.ControlCenter.darkMode
          hasCursor: root.selectedIndex === 1
          onClicked: root.activate(1)
        }

        Button {
          width: column.width
          text: Commons.I18n.t(root.stayAwake ? "controls.awakeOn" : "controls.awakeOff")
          foreground: root.foreground
          fontFamily: root.family
          leftAlign: true
          bordered: true
          active: root.stayAwake
          hasCursor: root.selectedIndex === 2
          onClicked: root.activate(2)
        }

        PanelSeparator { foreground: root.foreground }

        Repeater {
          model: [Commons.I18n.t("controls.project"), Commons.I18n.t("controls.cast"),
            Commons.I18n.t("controls.airplane"),
            Commons.I18n.t("controls.deviceManager"), Commons.I18n.t("controls.windowsSettings")]
          Button {
            required property string modelData
            required property int index
            width: column.width
            text: modelData
            foreground: root.foreground
            fontFamily: root.family
            leftAlign: true
            bordered: true
            hasCursor: root.selectedIndex === index + 3
            onClicked: root.activate(index + 3)
          }
        }
      }
    }
  }
}
