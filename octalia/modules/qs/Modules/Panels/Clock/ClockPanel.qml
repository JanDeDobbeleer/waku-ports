import QtQuick 6.10
import QtQuick.Layouts
import qs.Commons
import qs.Modules.MainScreen
import "ClockPanelUtils.js" as ClockPanelUtils

SmartPanel {
  id: root

  panelContent: Item {
    id: panelContent
    anchors.fill: parent

    readonly property real contentPreferredWidth: Math.round((Settings.data.location.showWeekNumberInCalendar ? 440 : 420) * Style.uiScaleRatio)
    readonly property real contentPreferredHeight: content.implicitHeight + Style.margin2L

    ColumnLayout {
      id: content
      x: Style.marginL
      y: Style.marginL
      width: parent.width - Style.margin2L
      spacing: Style.marginM

      // All clock panel cards
      Repeater {
        model: Settings.data.calendar.cards
        delegate: Loader {
          required property var modelData
          readonly property bool cardEnabled: ClockPanelUtils.cardEnabled(modelData, Settings.data.location.weatherEnabled)
          active: cardEnabled
          visible: active
          Layout.fillWidth: true
          source: ClockPanelUtils.sourceForCard(modelData)
          onLoaded: ClockPanelUtils.configureItem(modelData, item)
        }
      }
    }
  }

}
