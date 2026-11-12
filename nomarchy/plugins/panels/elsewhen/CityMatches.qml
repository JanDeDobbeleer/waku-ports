pragma ComponentBehavior: Bound
import QtQuick
import qs.Commons
import qs.Ui
import "Model.js" as Model

// The matches for a CitySearch; hosts that overlay results place this themselves.
Column {
  id: list

  required property var citySearch

  spacing: Style.space(2)

  Repeater {
    model: Model.value(list.citySearch, "matches")

    CursorSurface {
      id: match
      required property var modelData
      required property int index

      width: parent.width
      implicitHeight: Style.spacing.popupRowHeight
      foreground: Model.value(list.citySearch, "foreground")
      hasCursor: Model.value(list.citySearch, "selectedIndex") === index

      // The region is what tells Portland, Oregon from Portland, Maine; it
      // gives way first when the line is tight.
      Row {
        anchors.left: parent.left
        anchors.leftMargin: Style.spacing.xl
        anchors.right: matchZone.left
        anchors.rightMargin: Style.spacing.lg
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.spacing.md
        clip: true

        // Capped at its unelided width: an eliding Text's own implicitWidth
        // shrinks with it, which would make the cap circular.
        TextMetrics {
          id: matchNameMetrics
          font: matchName.font
          text: Model.value(match.modelData, "label")
        }

        Text {
          id: matchName
          width: Math.min(Math.ceil(matchNameMetrics.advanceWidth) + 1, parent.width)
          textFormat: Text.PlainText
          text: Model.value(match.modelData, "label")
          color: Model.value(list.citySearch, "foreground")
          font.family: Model.value(list.citySearch, "fontFamily")
          font.pixelSize: Model.value(list.citySearch, "fontSize")
          elide: Text.ElideRight
        }

        Caption {
          anchors.baseline: matchName.baseline
          width: Math.max(0, parent.width - matchName.width - Style.spacing.md)
          text: Model.value(match.modelData, "region") || ""
          visible: text !== ""
          color: Model.value(list.citySearch, "fainter")
          elide: Text.ElideRight
        }
      }

      // Two cities in one zone differ by name, two zones with one name by
      // offset. A place's region already says where it is, so its zone stays off.
      Row {
        id: matchZone
        anchors.right: parent.right
        anchors.rightMargin: Style.spacing.xl
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.spacing.md

        Caption {
          text: Model.value(match.modelData, "value")
          visible: !Model.value(match.modelData, "region")
          color: Model.value(list.citySearch, "fainter")
        }

        Caption {
          text: Model.callFunction(Model.value(list.citySearch, "offsetLabel"), [Model.value(match.modelData, "value")])
          visible: text !== ""
        }
      }

      // Only movement moves the selection, so a resting pointer cannot
      // steal it from the arrow keys as the list rebuilds.
      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPositionChanged: Model.setValue(list.citySearch, "selectedIndex", match.index)
        onClicked: Model.callFunction(Model.value(list.citySearch, "pick"), [match.modelData])
      }
    }
  }

  Caption {
    visible: Model.itemCount(Model.value(list.citySearch, "matches")) === 0
    width: parent.width
    horizontalAlignment: Text.AlignHCenter
    topPadding: Style.spacing.md
    text: Model.value(list.citySearch, "loading") ? Model.value(list.citySearch, "loadingText")
      : Model.value(list.citySearch, "searching") ? I18n.t("elsewhen.searchingPlaces") : I18n.t("common.noMatches")
    color: Model.value(list.citySearch, "fainter")
  }

  component Caption: Text {
    textFormat: Text.PlainText
    color: Model.value(list.citySearch, "dim")
    font.family: Model.value(list.citySearch, "fontFamily")
    font.pixelSize: Style.font.caption
  }
}
