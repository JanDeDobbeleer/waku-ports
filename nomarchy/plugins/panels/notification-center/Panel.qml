pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import qs.Ui
import qs.Commons
import qs.Commons as Commons
import "Model.js" as Model

Panel {
  id: root
  moduleName: "nomarchy.notification-center"
  ipcTarget: "nomarchy.notification-center"

  readonly property color contentForeground: bar ? BarValues.foreground(bar) : Commons.Color.foreground
  readonly property string contentFontFamily: bar ? BarValues.fontFamily(bar) : Style.font.family
  readonly property color hoverFill: bar
    ? Style.hoverFillFor(BarValues.foreground(bar), Commons.Color.accent, Commons.Color.urgent)
    : Commons.Color.accent
  readonly property color dim: Qt.darker(contentForeground, 1.5)

  readonly property var service: BarValues.firstPartyServiceFor(bar, "nomarchy.notifications")
  readonly property bool dnd: Model.field(service, "doNotDisturb") === true
  property double now: Date.now()
  readonly property var rows: Model.entries(service, now / 1000)
  readonly property int rowCount: Model.length(rows)
  // Arrivals since the panel was last opened; the bell marks them.
  property double seenTs: Date.now() / 1000
  readonly property int unread: opened ? 0 : Model.unreadCount(rows, seenTs)
  // -1 is the hero switch, -2 the clear button, 0.. the rows.
  property int cursor: -1

  readonly property string icon: dnd ? "󰪑" : (unread > 0 ? "󰅸" : "󰂜")

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onOpenedChanged: {
    if (opened) {
      root.now = Date.now()
      root.cursor = -1
      closeTimer.stop()
    } else {
      root.seenTs = Date.now() / 1000
      closeTimer.restart()
    }
  }
  onRowCountChanged: if (cursor >= rowCount || (cursor === -2 && rowCount === 0)) cursor = rowCount - 1

  Timer {
    id: closeTimer
    interval: Style.duration(300)
  }

  Timer {
    interval: 30000
    repeat: true
    running: root.opened
    onTriggered: root.now = Date.now()
  }

  function setDnd(value: bool): void {
    Model.call(root.service, "setDoNotDisturb", [value])
  }

  function clearAll(): void {
    Model.call(root.service, "clearHistory", [])
  }

  function forget(key: string): void {
    if (key !== "") Model.call(root.service, "forgetEntry", [key])
  }

  function activate(key: string, live: bool): void {
    if (!live || key === "") return
    root.close()
    Model.call(root.service, "activateEntry", [key])
  }

  function moveCursor(dy: int): void {
    const stops = [-1]
    if (root.rowCount > 0) stops.push(-2)
    for (let i = 0; i < root.rowCount; i++) stops.push(i)
    const at = Math.max(0, stops.indexOf(root.cursor))
    root.cursor = stops[Math.max(0, Math.min(stops.length - 1, at + dy))]
  }

  function activateCursor(): void {
    if (root.cursor === -1) root.setDnd(!root.dnd)
    else if (root.cursor === -2) root.clearAll()
    else {
      const row = root.rows[root.cursor]
      root.activate(Model.text(row, "key"), Model.flag(row, "live"))
    }
  }

  function ago(ts: real): string {
    var seconds = Math.max(0, root.now / 1000 - ts)
    if (seconds < 60) return Commons.I18n.t("notificationCenter.now")
    if (seconds < 3600) return Commons.I18n.t("notifications.minutesAgo").arg(Commons.I18n.formatNumber(Math.round(seconds / 60)))
    var then = new Date(ts * 1000)
    if (new Date(root.now).toDateString() === then.toDateString())
      return Qt.formatTime(then, "HH:mm")
    return Commons.I18n.t("notifications.yesterday")
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.icon
    active: root.unread > 0 && !root.dnd
    tooltipText: root.dnd ? Commons.I18n.t("bar.allowNotifications") : Commons.I18n.t("notificationCenter.title")
    onPressed: function(b) {
      if (b === Qt.RightButton) root.setDnd(!root.dnd)
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
        contentWidth: panel.fittedContentWidth(Style.space(400), undefined)
        contentHeight: panel.fittedContentHeight(panel.loadedContentHeight, undefined)
        panelContent: centerContent
      }
    }
  }

  Component {
    id: centerContent
    PanelKeyCatcher {
      anchors.fill: parent
      implicitHeight: column.implicitHeight
      onMoveRequested: function(dx, dy) { if (dy !== 0) root.moveCursor(dy) }
      onActivateRequested: root.activateCursor()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onDeleteRequested: if (root.cursor >= 0) root.forget(Model.keyAt(root.rows, root.cursor))
      onTextKey: function(t) {
        if (t === "d" || t === "D") root.setDnd(!root.dnd)
      }

      Column {
        id: column
        anchors.fill: parent
        spacing: Style.space(14)

        // ---------- Hero: bell · count, with the Do Not Disturb switch ----------
        Item {
          width: parent.width
          implicitHeight: Math.max(heroIcon.implicitHeight, heroLabels.implicitHeight, dndSwitch.implicitHeight)

          Text {
            id: heroIcon
            textFormat: Text.PlainText
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: root.dnd ? "󰂛" : "󰂚"
            color: root.contentForeground
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.display
            opacity: root.dnd ? 0.5 : 1.0
          }

          // On means notifications show; off is Do Not Disturb.
          ToggleSwitch {
            id: dndSwitch
            checked: !root.dnd
            hasCursor: root.cursor === -1
            foreground: root.contentForeground
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            onHovered: function(on) { if (on) root.cursor = -1 }
            onToggled: root.setDnd(!root.dnd)

            PanelToolTip {
              visible: dndSwitch.containsMouse
              text: root.dnd ? Commons.I18n.t("bar.allowNotifications") : Commons.I18n.t("bar.silenceNotifications")
              fontFamily: root.contentFontFamily
            }
          }

          Column {
            id: heroLabels
            anchors.left: heroIcon.right
            anchors.leftMargin: Style.space(14)
            anchors.right: dndSwitch.left
            anchors.rightMargin: Style.space(12)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Text {
              text: Commons.I18n.t("notificationCenter.title")
              textFormat: Text.PlainText
              color: root.contentForeground
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.title
              font.bold: true
              elide: Text.ElideRight
              width: parent.width
            }

            Text {
              textFormat: Text.PlainText
              text: (root.dnd ? Commons.I18n.t("notificationCenter.dnd")
                : root.rowCount === 1 ? Commons.I18n.t("notificationCenter.one")
                : Commons.I18n.t("notificationCenter.count").arg(Commons.I18n.formatNumber(root.rowCount))).toUpperCase()
              color: Qt.darker(root.contentForeground, 1.4)
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.2
              elide: Text.ElideRight
              width: parent.width
            }
          }
        }

        PanelSeparator { foreground: root.contentForeground }

        Item {
          width: parent.width
          visible: root.rowCount > 0
          implicitHeight: Math.max(recentHeader.implicitHeight, clearButton.implicitHeight)

          PanelSectionHeader {
            id: recentHeader
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: Commons.I18n.t("notificationCenter.recent")
            foreground: root.contentForeground
            fontFamily: root.contentFontFamily
          }

          Button {
            id: clearButton
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: Commons.I18n.t("notificationCenter.clearAll")
            foreground: root.contentForeground
            fontFamily: root.contentFontFamily
            fontSize: Style.font.bodySmall
            bordered: true
            hasCursor: root.cursor === -2
            onHovered: function(on) { if (on) root.cursor = -2 }
            onClicked: root.clearAll()
          }
        }

        ListView {
          id: list
          width: parent.width
          height: Math.min(contentHeight, Style.space(440))
          visible: root.rowCount > 0
          spacing: Style.space(6)
          clip: true
          boundsBehavior: Flickable.StopAtBounds
          interactive: contentHeight > height
          model: root.rows
          currentIndex: root.cursor
          onCurrentIndexChanged: if (currentIndex >= 0) positionViewAtIndex(currentIndex, ListView.Contain)

          ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

          delegate: CursorSurface {
            id: row
            required property var modelData
            required property int index

            readonly property string key: Model.text(modelData, "key")
            readonly property bool live: Model.flag(modelData, "live")
            readonly property bool redacted: Model.flag(modelData, "redacted")
            readonly property string glyph: Model.text(modelData, "glyph")
            readonly property string summary: redacted ? Commons.I18n.t("notifications.redactedSummary") : Model.text(modelData, "summary")
            readonly property string body: redacted ? Commons.I18n.t("notifications.redactedBody") : Model.text(modelData, "body")
            readonly property string app: Model.text(modelData, "app")
            readonly property bool urgent: Model.flag(modelData, "urgent")

            width: ListView.view.width
            hasCursor: root.cursor === index
            current: live
            foreground: root.contentForeground
            fill: root.hoverFill
            implicitHeight: rowContent.implicitHeight + Style.spacing.rowPaddingX

            MouseArea {
              id: rowMouse
              anchors.fill: parent
              hoverEnabled: true
              acceptedButtons: Qt.LeftButton | Qt.MiddleButton
              cursorShape: row.live ? Qt.PointingHandCursor : Qt.ArrowCursor
              onContainsMouseChanged: if (containsMouse) root.cursor = row.index
              onClicked: function(mouse) {
                if (mouse.button === Qt.MiddleButton) root.forget(row.key)
                else root.activate(row.key, row.live)
              }
            }

            Item {
              id: rowContent
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              anchors.leftMargin: Style.space(10)
              anchors.rightMargin: Style.space(10)
              implicitHeight: Math.max(rowIcon.implicitHeight, info.implicitHeight)

              Text {
                id: rowIcon
                textFormat: Text.PlainText
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.topMargin: Style.space(2)
                width: Style.space(22)
                horizontalAlignment: Text.AlignHCenter
                text: row.glyph !== "" ? row.glyph : (row.urgent ? "󰀦" : "󰂚")
                color: row.urgent ? Commons.Color.urgent : root.contentForeground
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.heading
              }

              Column {
                id: info
                anchors.left: rowIcon.right
                anchors.leftMargin: Style.space(10)
                anchors.right: parent.right
                anchors.rightMargin: forgetButton.width + Style.space(6)
                spacing: Style.space(2)

                Item {
                  width: parent.width
                  implicitHeight: Math.max(appText.implicitHeight, timeText.implicitHeight)

                  Text {
                    id: appText
                    textFormat: Text.PlainText
                    anchors.left: parent.left
                    anchors.right: timeText.left
                    anchors.rightMargin: Style.space(8)
                    text: row.app.toUpperCase()
                    color: root.dim
                    font.family: root.contentFontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: true
                    font.letterSpacing: 1.0
                    elide: Text.ElideRight
                  }

                  Text {
                    id: timeText
                    textFormat: Text.PlainText
                    anchors.right: parent.right
                    text: root.ago(Model.number(row.modelData, "ts"))
                    color: root.dim
                    font.family: root.contentFontFamily
                    font.pixelSize: Style.font.caption
                  }
                }

                Text {
                  textFormat: Text.PlainText
                  text: row.summary
                  visible: text !== ""
                  color: root.contentForeground
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                  elide: Text.ElideRight
                  width: parent.width
                }

                Text {
                  textFormat: Text.PlainText
                  text: row.body
                  visible: text !== ""
                  color: Qt.darker(root.contentForeground, 1.2)
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.bodySmall
                  wrapMode: Text.Wrap
                  maximumLineCount: 3
                  elide: Text.ElideRight
                  width: parent.width
                }
              }

              PanelActionButton {
                id: forgetButton
                anchors.right: parent.right
                anchors.top: parent.top
                opacity: rowMouse.containsMouse || row.hasCursor ? 1 : 0
                iconText: "󰅙"
                tooltipText: Commons.I18n.t("notificationCenter.dismiss")
                foreground: root.contentForeground
                hoverColor: root.contentForeground
                fontFamily: root.contentFontFamily
                onHovered: function(isHovered) { if (isHovered) root.cursor = row.index }
                onClicked: root.forget(row.key)
              }
            }
          }
        }

        Text {
          textFormat: Text.PlainText
          visible: root.rowCount === 0
          text: Commons.I18n.t("notifications.noneRecent")
          color: root.dim
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.bodySmall
          width: parent.width
        }
      }
    }
  }
}
