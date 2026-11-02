import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.System
import qs.Services.UI
import qs.Widgets

// Unified system card: monitors CPU, temp, memory, disk
NBox {
  id: root

  Component.onCompleted: SystemStatService.registerComponent("card-sysmonitor")
  Component.onDestruction: SystemStatService.unregisterComponent("card-sysmonitor")

  readonly property string diskPath: Settings.data.controlCenter.diskPath || "/"
  readonly property real contentScale: 0.95 * Style.uiScaleRatio

  Item {
    id: content
    anchors.fill: parent
    anchors.margins: Style.marginS

    Column {
      anchors.fill: parent

      Item {
        width: parent.width
        height: parent.height / 4

        NCircleStat {
          id: cpuUsageGauge
          anchors.centerIn: parent
          ratio: SystemStatService.cpuUsage / 100
          icon: "cpu-usage"
          contentScale: root.contentScale
          fillColor: SystemStatService.cpuColor
        }
      }

      Item {
        width: parent.width
        height: parent.height / 4

        NCircleStat {
          id: cpuTempGauge
          anchors.centerIn: parent
          ratio: SystemStatService.cpuTemp / 100
          suffix: "°C"
          icon: "cpu-temperature"
          contentScale: root.contentScale
          fillColor: SystemStatService.tempColor
        }
      }

      Item {
        width: parent.width
        height: parent.height / 4

        NCircleStat {
          id: memPercentGauge
          anchors.centerIn: parent
          ratio: SystemStatService.memPercent / 100
          icon: "memory"
          contentScale: root.contentScale
          fillColor: SystemStatService.memColor
        }
      }

      Item {
        width: parent.width
        height: parent.height / 4

        NCircleStat {
          id: diskPercentsGauge
          anchors.centerIn: parent
          ratio: (SystemStatService.diskPercents[root.diskPath] ?? 0) / 100
          icon: "storage"
          contentScale: root.contentScale
          fillColor: SystemStatService.getDiskColor(root.diskPath)
        }
      }
    }
  }
}
