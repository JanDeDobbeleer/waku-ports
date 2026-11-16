pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import waku.services as S
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "Model.js" as Model

// CPU, memory and GPU load as small live graphs on the bar; the flyout shows
// the same graphs over a longer window with readings and the drives.
Panel {
  id: root
  moduleName: "nomarchy.sysmon"
  ipcTarget: "nomarchy.sysmon"

  readonly property color foreground: bar ? BarValues.foreground(bar) : Commons.Color.foreground
  readonly property string family: bar ? BarValues.fontFamily(bar) : Style.font.family
  readonly property color dimForeground: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.6)
  readonly property color contentUrgent: bar ? BarValues.urgent(bar) : Commons.Color.urgent
  readonly property bool hasGpu: gpu.available

  readonly property string cpuText: percentText(cpu.percent)
  readonly property string memoryText: percentText(memory.percent)
  readonly property string gpuText: percentText(gpu.percent)

  readonly property string cpuDetail: {
    var parts = []
    if (cpu.frequency > 0) parts.push(Commons.I18n.formatNumberWithDecimals(cpu.frequency / 1000, 1) + " GHz")
    if (cpu.temperatureAvailable) parts.push(Commons.I18n.formatNumber(Math.round(cpu.temperature)) + " °C")
    if (cpu.cores > 0) parts.push(Commons.I18n.t("sysmon.threads").arg(Commons.I18n.formatNumber(cpu.cores)))
    return parts.join("  ·  ")
  }
  readonly property string memoryDetail: Commons.I18n.t("sysmon.usedOf")
    .arg(gigabytesText(memory.used)).arg(gigabytesText(memory.total))
  readonly property string gpuDetail: {
    var parts = []
    if (gpu.name !== "") parts.push(Model.gpuName(gpu.name))
    // An integrated GPU reports a sliver of dedicated memory; it uses shared
    // memory, so the figure would mislead.
    if (gpu.memoryTotal >= 536870912)
      parts.push(Commons.I18n.t("sysmon.vram").arg(gigabytesText(gpu.memory)).arg(gigabytesText(gpu.memoryTotal)))
    if (gpu.temperatureAvailable) parts.push(Commons.I18n.formatNumber(Math.round(gpu.temperature)) + " °C")
    return parts.join("  ·  ")
  }

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

  function percentText(value: real): string {
    return Commons.I18n.formatNumber(Math.round(Model.clampPercent(value))) + "%"
  }

  function gigabytesText(bytes: real): string {
    return Commons.I18n.formatNumberWithDecimals(Model.gigabytes(bytes), 1)
  }

  function openTaskManager(): void {
    root.close()
    Quickshell.execDetached(["taskmgr.exe"])
  }

  // One sample every two seconds, kept while the panel is closed so it opens on
  // two minutes of history rather than an empty graph.
  S.Cpu { id: cpu; historySize: 60 }
  S.Memory { id: memory; historySize: 60 }
  // GPU counters are the costly sample on Windows, so they run only while the flyout shows.
  S.Gpu { id: gpu; historySize: 60; active: root.opened }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: ""
    tooltipText: root.opened ? "" : Commons.I18n.t("sysmon.tooltip")
      .arg(root.cpuText).arg(root.memoryText)
    onPressed: function(b) {
      if (b === Qt.RightButton) root.openTaskManager()
      else root.toggle()
    }
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
        contentWidth: panel.fittedContentWidth(Style.space(340), undefined)
        contentHeight: panel.fittedContentHeight(panel.loadedContentHeight, undefined)
        panelContent: details
      }
    }
  }

  Component {
    id: details
    PanelKeyCatcher {
      anchors.fill: parent
      implicitHeight: column.implicitHeight
      onActivateRequested: root.openTaskManager()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      S.Disks { id: disks; interval: 10000 }

      Column {
        id: column
        width: parent.width
        spacing: Style.space(10)

        Text {
          text: Commons.I18n.t("sysmon.title")
          color: root.foreground
          font.family: root.family
          font.pixelSize: Style.font.title
          font.bold: true
        }

        PanelSeparator { foreground: root.foreground }

        MetricBlock {
          width: column.width
          label: Commons.I18n.t("sysmon.cpu")
          value: root.cpuText
          detail: root.cpuDetail
          history: cpu.history
        }

        MetricBlock {
          width: column.width
          label: Commons.I18n.t("sysmon.memory")
          value: root.memoryText
          detail: root.memoryDetail
          history: memory.history
        }

        MetricBlock {
          visible: root.hasGpu
          width: column.width
          label: Commons.I18n.t("sysmon.gpu")
          value: root.gpuText
          detail: root.gpuDetail
          history: gpu.history
        }

        PanelSeparator { foreground: root.foreground }

        PanelSectionHeader {
          text: Commons.I18n.t("sysmon.disks")
          foreground: root.foreground
          fontFamily: root.family
        }

        Repeater {
          model: Model.diskRows(disks.disks)
          delegate: DiskRow {
            required property var modelData
            width: column.width
            mount: Model.rowField(modelData, "mount")
            used: Model.rowField(modelData, "used")
            total: Model.rowField(modelData, "total")
            percent: Model.rowField(modelData, "percent")
          }
        }

        PanelSeparator { foreground: root.foreground }

        Button {
          width: column.width
          text: Commons.I18n.t("sysmon.taskManager")
          foreground: root.foreground
          fontFamily: root.family
          leftAlign: true
          bordered: true
          hasCursor: true
          onClicked: root.openTaskManager()
        }
      }
    }
  }

  // Flyout section: name and load on one line, readings under it, then the
  // two-minute graph.
  component MetricBlock: Column {
    id: block
    property string label: ""
    property string value: ""
    property string detail: ""
    property var history: []
    spacing: Style.space(4)

    Item {
      width: block.width
      implicitHeight: blockLabel.implicitHeight

      Text {
        id: blockLabel
        anchors.left: parent.left
        text: block.label
        color: root.foreground
        font.family: root.family
        font.pixelSize: Style.font.body
      }

      Text {
        anchors.right: parent.right
        text: block.value
        color: root.foreground
        font.family: root.family
        font.pixelSize: Style.font.body
        font.bold: true
      }
    }

    Text {
      visible: block.detail !== ""
      width: block.width
      text: block.detail
      color: root.dimForeground
      font.family: root.family
      font.pixelSize: Style.font.caption
      elide: Text.ElideRight
    }

    Graph {
      width: block.width
      height: Style.space(38)
      samples: 60
      lineWidth: 1.5
      history: block.history
      color: root.foreground
    }
  }

  // One drive: mount and space on one line, a thin fill bar under it.
  component DiskRow: Column {
    id: disk
    property string mount: ""
    property real used: 0
    property real total: 0
    property real percent: 0
    spacing: Style.space(4)

    Item {
      width: disk.width
      implicitHeight: mountText.implicitHeight

      Text {
        id: mountText
        anchors.left: parent.left
        text: disk.mount
        color: root.foreground
        font.family: root.family
        font.pixelSize: Style.font.body
      }

      Text {
        anchors.right: parent.right
        text: Commons.I18n.t("sysmon.usedOf").arg(Commons.I18n.formatNumberWithDecimals(disk.used, 0))
          .arg(Commons.I18n.formatNumberWithDecimals(disk.total, 0))
        color: root.dimForeground
        font.family: root.family
        font.pixelSize: Style.font.caption
      }
    }

    Rectangle {
      width: disk.width
      height: Style.space(3)
      radius: height / 2
      color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.2)

      Rectangle {
        width: parent.width * disk.percent / 100
        height: parent.height
        radius: height / 2
        color: disk.percent >= 90 ? root.contentUrgent : root.foreground
      }
    }
  }
}
