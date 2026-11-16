pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Services.Mpris
import qs.Ui
import qs.Commons
import qs.Commons as Commons
import "MediaBarWidgetUtils.js" as MediaBarWidgetUtils

Panel {
  id: root
  moduleName: "nomarchy.media"
  // The service answers "media"; this target opens and closes the flyout.
  ipcTarget: "nomarchy.media"

  readonly property color contentForeground: bar ? BarValues.foreground(bar) : Commons.Color.foreground
  readonly property string contentFontFamily: bar ? BarValues.fontFamily(bar) : Style.font.family
  readonly property color contentBarForeground: bar ? BarValues.barForeground(bar) : Commons.Color.foreground
  readonly property color dim: Qt.darker(contentForeground, 1.5)

  readonly property var mediaService: BarValues.firstPartyServiceFor(bar, "nomarchy.media")
  readonly property MprisPlayer activePlayer: MediaBarWidgetUtils.field(mediaService, "activePlayer") as MprisPlayer
  readonly property var sourcePlayers: MediaBarWidgetUtils.field(mediaService, "sourcePlayers") || []

  readonly property bool hasMedia: activePlayer !== null && (activePlayer.trackTitle !== "" || activePlayer.trackArtist !== "")
  readonly property bool isPlaying: !!activePlayer && activePlayer.isPlaying
  readonly property string title: activePlayer ? activePlayer.trackTitle : ""
  readonly property string artist: activePlayer ? activePlayer.trackArtist : ""
  readonly property real length: activePlayer && activePlayer.lengthSupported ? activePlayer.length : 0
  readonly property bool canSeek: !!activePlayer && activePlayer.canSeek && length > 0
  // Not FINAL on MprisPlayer, so read through the helper.
  readonly property real position: MediaBarWidgetUtils.number(activePlayer, "position")
  readonly property bool shuffle: MediaBarWidgetUtils.flag(activePlayer, "shuffle")
  readonly property int loopState: MediaBarWidgetUtils.number(activePlayer, "loopState")

  // On the bar only while something plays. A short linger keeps it from
  // flickering away between tracks or while the flyout is being used.
  property bool lingering: false
  readonly property bool shown: hasMedia && (isPlaying || lingering || opened || closeTimer.running)
  onIsPlayingChanged: if (!isPlaying) linger.restart()

  property real maxLabelWidth: 180

  visible: shown
  implicitWidth: shown ? row.implicitWidth + Style.space(14) : 0
  implicitHeight: bar ? BarValues.barSize(bar) : Style.bar.sizeHorizontal

  onOpenedChanged: if (!opened) closeTimer.restart()

  Timer {
    id: linger
    interval: 4000
    onRunningChanged: root.lingering = running
  }

  Timer {
    id: closeTimer
    interval: Style.duration(300)
  }

  function playerKey(player: var): string {
    return String(MediaBarWidgetUtils.call(mediaService, "playerKey", [player]) || "")
  }
  function runAction(action: string): void {
    MediaBarWidgetUtils.call(mediaService, "runAction", [action, false, playerKey(activePlayer)])
  }
  function seekTo(seconds: real): void {
    if (root.canSeek) MediaBarWidgetUtils.setField(root.activePlayer, "position", Math.max(0, Math.min(root.length, seconds)))
  }
  function seekBy(offset: real): void {
    root.seekTo(root.position + offset)
  }
  function toggleShuffle(): void {
    if (root.activePlayer && root.activePlayer.shuffleSupported) MediaBarWidgetUtils.setField(root.activePlayer, "shuffle", !root.shuffle)
  }
  function cycleLoop(): void {
    if (!root.activePlayer || !root.activePlayer.loopSupported) return
    MediaBarWidgetUtils.setField(root.activePlayer, "loopState",
      root.loopState === MprisLoopState.None ? MprisLoopState.Playlist
      : root.loopState === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None)
  }

  Row {
    id: row
    anchors.centerIn: parent
    spacing: Style.space(6)

    Text {
      id: glyph
      textFormat: Text.PlainText
      anchors.verticalCenter: parent.verticalCenter
      text: "󰝚"
      color: root.isPlaying ? root.contentBarForeground : Qt.darker(root.contentBarForeground, 1.5)
      font.family: root.contentFontFamily
      font.pixelSize: Style.font.body
      Behavior on color {
        enabled: !root.bar || BarValues.foregroundAnimationEnabled(root.bar)
        ColorAnimation { duration: Style.duration(160) }
      }
    }

    Item {
      id: scrollClip
      width: Math.min(root.maxLabelWidth, labelText.implicitWidth)
      height: glyph.height
      clip: true
      anchors.verticalCenter: parent.verticalCenter
      visible: !BarValues.vertical(root.bar) && root.title !== ""

      Text {
        id: labelText
        textFormat: Text.PlainText
        text: root.title + (root.artist ? "  ·  " + root.artist : "")
        color: root.contentBarForeground
        font.family: root.contentFontFamily
        font.pixelSize: Style.font.body
        anchors.verticalCenter: parent.verticalCenter

        property bool needsScroll: implicitWidth > scrollClip.width

        // Each frame of the scroll redraws the bar, so it only runs while the
        // track is playing and the bar is on screen to show it.
        NumberAnimation on x {
          running: labelText.needsScroll && root.isPlaying && root.visible && !BarValues.barHidden(root.bar) && !root.opened && !BarValues.vertical(root.bar) && !Style.reduceMotion
          // Stopped, the title reads from its start again.
          onRunningChanged: if (!running) labelText.x = 0
          loops: Animation.Infinite
          duration: Style.duration(Math.max(6000, labelText.implicitWidth * 25))
          from: scrollClip.width
          to: -labelText.implicitWidth
          easing.type: Easing.Linear
        }
      }
    }
  }

  MouseArea {
    id: barMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

    onClicked: function(mouse) {
      if (mouse.button === Qt.MiddleButton) root.runAction("playPause")
      else root.toggle()
    }
    onWheel: function(wheel) {
      if (wheel.angleDelta.y > 0) root.runAction("previous")
      else if (wheel.angleDelta.y < 0) root.runAction("next")
    }
    onEntered: if (root.bar && !root.opened) BarValues.showTooltip(root.bar, root, root.title + (root.artist ? " · " + root.artist : ""))
    onExited: if (root.bar) BarValues.hideTooltip(root.bar, root)
  }

  Loader {
    active: root.opened || closeTimer.running
    sourceComponent: Component {
      KeyboardPanel {
        id: panel
        anchorItem: root
        owner: root
        bar: root.bar
        open: root.opened
        focusTarget: panel.loadedContent
        contentWidth: panel.fittedContentWidth(Style.space(360), undefined)
        contentHeight: panel.fittedContentHeight(panel.loadedContentHeight, undefined)
        panelContent: mediaContent
      }
    }
  }

  Component {
    id: mediaContent
    PanelKeyCatcher {
      anchors.fill: parent
      implicitHeight: column.implicitHeight
      onMoveRequested: function(dx, dy) {
        if (dx !== 0) root.seekBy(dx * 10)
        else if (dy !== 0) root.runAction(dy > 0 ? "next" : "previous")
      }
      onActivateRequested: root.runAction("playPause")
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) {
        if (t === " ") root.runAction("playPause")
        else if (t === "n") root.runAction("next")
        else if (t === "p") root.runAction("previous")
        else if (t === "s") root.toggleShuffle()
        else if (t === "r") root.cycleLoop()
      }

      Column {
        id: column
        anchors.fill: parent
        spacing: Style.space(14)

        // ---------- Hero: cover art · title, artist, album ----------
        Item {
          width: parent.width
          implicitHeight: Math.max(art.height, heroLabels.implicitHeight)

          BorderSurface {
            id: art
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: Style.space(72)
            height: Style.space(72)
            radius: Style.spacing.labelGap
            color: Style.normalFillFor(root.contentForeground, Commons.Color.accent, Commons.Color.urgent)
            borderSpec: Border.controlSpec("normal", root.contentForeground, Commons.Color.accent)

            // Decoded at the size it is drawn, not the size the player serves.
            SizedImage {
              id: artImage
              anchors.fill: parent
              anchors.margins: Style.space(2)
              crop: true
              url: root.activePlayer ? root.activePlayer.trackArtUrl : ""
              visible: String(url) !== ""
            }

            Text {
              anchors.centerIn: parent
              visible: !artImage.visible
              text: "󰝚"
              textFormat: Text.PlainText
              color: root.contentForeground
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.display
            }
          }

          Column {
            id: heroLabels
            anchors.left: art.right
            anchors.leftMargin: Style.space(14)
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(3)

            Text {
              textFormat: Text.PlainText
              text: (root.activePlayer ? (root.activePlayer.identity || root.activePlayer.desktopEntry) : "").toUpperCase()
              visible: text !== ""
              color: Qt.darker(root.contentForeground, 1.4)
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.2
              elide: Text.ElideRight
              width: parent.width
            }

            Text {
              textFormat: Text.PlainText
              text: root.title || Commons.I18n.t("media.nothingPlaying")
              color: root.contentForeground
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.title
              font.bold: true
              elide: Text.ElideRight
              width: parent.width
            }

            Text {
              textFormat: Text.PlainText
              text: root.artist + (root.activePlayer && root.activePlayer.trackAlbum !== "" ? (root.artist !== "" ? " · " : "") + root.activePlayer.trackAlbum : "")
              visible: text !== ""
              color: Qt.darker(root.contentForeground, 1.2)
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.bodySmall
              elide: Text.ElideRight
              width: parent.width
            }
          }
        }

        // ---------- Seek bar with elapsed and total time ----------
        Column {
          width: parent.width
          spacing: Style.space(4)
          visible: root.length > 0

          PanelSlider {
            bar: root.bar
            width: parent.width
            height: Style.space(24)
            minimum: 0
            maximum: Math.max(1, root.length)
            step: 1
            value: root.position
            enabled: root.canSeek
            opacity: enabled ? 1.0 : 0.5
            onReleased: function(v) { root.seekTo(v) }
          }

          Item {
            width: parent.width
            implicitHeight: elapsed.implicitHeight

            Text {
              id: elapsed
              textFormat: Text.PlainText
              anchors.left: parent.left
              text: MediaBarWidgetUtils.clock(root.position)
              color: root.dim
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
            }

            Text {
              textFormat: Text.PlainText
              anchors.right: parent.right
              text: MediaBarWidgetUtils.clock(root.length)
              color: root.dim
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
            }
          }
        }

        // ---------- Transport ----------
        Item {
          width: parent.width
          implicitHeight: transport.implicitHeight
          // Transport controls keep previous, play, next in every language,
          // matching their glyphs; media controls are not mirrored.
          LayoutMirroring.enabled: false
          LayoutMirroring.childrenInherit: true

          PanelActionButton {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            visible: !!root.activePlayer && root.activePlayer.shuffleSupported
            iconText: "󰒝"
            tooltipText: Commons.I18n.t("media.shuffle")
            foreground: root.shuffle ? root.contentForeground : root.dim
            hoverColor: root.contentForeground
            fontFamily: root.contentFontFamily
            bordered: !!root.shuffle
            onClicked: root.toggleShuffle()
          }

          Row {
            id: transport
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Style.space(6)

            Button {
              iconText: "󰒮"
              tooltipText: Commons.I18n.t("media.previous")
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              enabled: !!root.activePlayer && root.activePlayer.canGoPrevious
              opacity: enabled ? 1.0 : 0.4
              onClicked: root.runAction("previous")
            }

            Button {
              iconText: root.isPlaying ? "󰏤" : "󰐊"
              tooltipText: Commons.I18n.t("media.playPause")
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              horizontalPadding: Style.spacing.panelGap
              iconSize: Style.font.iconLarge
              bordered: true
              enabled: !!root.activePlayer && (root.activePlayer.canTogglePlaying || root.activePlayer.canPlay || root.activePlayer.canPause)
              opacity: enabled ? 1.0 : 0.4
              onClicked: root.runAction("playPause")
            }

            Button {
              iconText: "󰒭"
              tooltipText: Commons.I18n.t("media.next")
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              enabled: !!root.activePlayer && root.activePlayer.canGoNext
              opacity: enabled ? 1.0 : 0.4
              onClicked: root.runAction("next")
            }
          }

          PanelActionButton {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: !!root.activePlayer && root.activePlayer.loopSupported
            readonly property int loop: root.loopState
            iconText: loop === MprisLoopState.Track ? "󰑘" : "󰑖"
            tooltipText: Commons.I18n.t("media.repeat")
            foreground: loop === MprisLoopState.None ? root.dim : root.contentForeground
            hoverColor: root.contentForeground
            fontFamily: root.contentFontFamily
            bordered: loop !== MprisLoopState.None
            onClicked: root.cycleLoop()
          }
        }

        // ---------- Sources, when more than one app plays ----------
        PanelSeparator {
          visible: MediaBarWidgetUtils.arrayLength(root.sourcePlayers) > 1
          foreground: root.contentForeground
        }

        PanelSectionHeader {
          visible: MediaBarWidgetUtils.arrayLength(root.sourcePlayers) > 1
          text: Commons.I18n.t("media.source")
          foreground: root.contentForeground
          fontFamily: root.contentFontFamily
        }

        Column {
          id: sourceList
          visible: MediaBarWidgetUtils.arrayLength(root.sourcePlayers) > 1
          width: parent.width
          spacing: Style.space(4)

          Repeater {
            model: root.sourcePlayers

            CursorSurface {
              id: sourceRow
              required property var modelData

              readonly property MprisPlayer player: modelData as MprisPlayer
              readonly property bool selected: !!root.activePlayer && !!player
                && root.playerKey(root.activePlayer) === root.playerKey(player)

              width: sourceList.width
              implicitHeight: sourceInner.implicitHeight + Style.space(12)
              current: selected
              hasCursor: sourceMouse.containsMouse
              foreground: root.contentForeground

              Row {
                id: sourceInner
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Style.space(10)
                anchors.rightMargin: Style.space(10)
                spacing: Style.space(10)

                Text {
                  textFormat: Text.PlainText
                  text: sourceRow.player && sourceRow.player.isPlaying ? "󰏤" : "󰐊"
                  color: root.contentForeground
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.body
                  width: Style.space(18)
                  horizontalAlignment: Text.AlignHCenter
                  anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                  width: parent.width - Style.space(28)
                  spacing: Style.space(1)
                  anchors.verticalCenter: parent.verticalCenter

                  Text {
                    textFormat: Text.PlainText
                    text: sourceRow.player ? (sourceRow.player.trackTitle || sourceRow.player.identity || Commons.I18n.t("media.mediaSource")) : ""
                    color: root.contentForeground
                    font.family: root.contentFontFamily
                    font.pixelSize: Style.font.bodySmall
                    font.bold: sourceRow.selected
                    elide: Text.ElideRight
                    width: parent.width
                  }

                  Text {
                    textFormat: Text.PlainText
                    text: sourceRow.player ? (sourceRow.player.identity || sourceRow.player.desktopEntry) : ""
                    visible: text !== ""
                    color: root.dim
                    font.family: root.contentFontFamily
                    font.pixelSize: Style.font.caption
                    elide: Text.ElideRight
                    width: parent.width
                  }
                }
              }

              MouseArea {
                id: sourceMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: MediaBarWidgetUtils.call(root.mediaService, "selectPlayer", [root.playerKey(sourceRow.player)])
              }
            }
          }
        }
      }
    }
  }
}
