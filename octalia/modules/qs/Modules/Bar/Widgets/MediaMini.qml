pragma ComponentBehavior: Bound

import QtQuick 6.10
import QtQuick.Layouts
import Quickshell
import qs.Commons
import "../BarWidgetHelpers.js" as BarWidgetHelpers
import qs.Services.Media
import qs.Services.UI
import qs.Widgets
import qs.Widgets.AudioSpectrum

Item {
  id: root

  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  // Settings
  property var widgetMetadata: BarWidgetRegistry.widgetMetadata[widgetId] ?? {}
  // Explicit screenName property ensures reactive binding when screen changes
  readonly property string screenName: screen ? screen.name : ""
  property var widgetSettings: {
    var widgets;
    if (section && sectionWidgetIndex >= 0 && screenName) {
      widgets = Settings.getBarWidgetsForScreen(screenName)[section];
      if (widgets && sectionWidgetIndex < widgets.length) {
        return widgets[sectionWidgetIndex];
      }
    }
    return {};
  }

  // Bar orientation (per-screen)
  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool isVertical: barPosition === "left" || barPosition === "right"
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
  readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

  // Widget settings
  readonly property string hideMode: BarWidgetHelpers.readProperty(widgetSettings, "hideMode") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "hideMode") : BarWidgetHelpers.readProperty(widgetMetadata, "hideMode")
  readonly property bool hideWhenIdle: BarWidgetHelpers.readProperty(widgetSettings, "hideWhenIdle") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "hideWhenIdle") : BarWidgetHelpers.readProperty(widgetMetadata, "hideWhenIdle")
  readonly property bool showAlbumArt: BarWidgetHelpers.readProperty(widgetSettings, "showAlbumArt") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "showAlbumArt") : BarWidgetHelpers.readProperty(widgetMetadata, "showAlbumArt")
  readonly property bool showArtistFirst: BarWidgetHelpers.readProperty(widgetSettings, "showArtistFirst") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "showArtistFirst") : BarWidgetHelpers.readProperty(widgetMetadata, "showArtistFirst")
  readonly property bool showVisualizer: BarWidgetHelpers.readProperty(widgetSettings, "showVisualizer") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "showVisualizer") : BarWidgetHelpers.readProperty(widgetMetadata, "showVisualizer")
  readonly property string visualizerType: BarWidgetHelpers.readProperty(widgetSettings, "visualizerType") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "visualizerType") : BarWidgetHelpers.readProperty(widgetMetadata, "visualizerType")
  readonly property string scrollingMode: BarWidgetHelpers.readProperty(widgetSettings, "scrollingMode") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "scrollingMode") : BarWidgetHelpers.readProperty(widgetMetadata, "scrollingMode")
  readonly property bool showProgressRing: BarWidgetHelpers.readProperty(widgetSettings, "showProgressRing") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "showProgressRing") : BarWidgetHelpers.readProperty(widgetMetadata, "showProgressRing")
  readonly property bool useFixedWidth: BarWidgetHelpers.readProperty(widgetSettings, "useFixedWidth") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "useFixedWidth") : BarWidgetHelpers.readProperty(widgetMetadata, "useFixedWidth")
  readonly property real maxWidth: BarWidgetHelpers.readProperty(widgetSettings, "maxWidth") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "maxWidth") : Math.max(BarWidgetHelpers.readProperty(widgetMetadata, "maxWidth"), screen ? screen.width * 0.06 : 0)
  readonly property string textColorKey: BarWidgetHelpers.readProperty(widgetSettings, "textColor") !== undefined ? BarWidgetHelpers.readProperty(widgetSettings, "textColor") : BarWidgetHelpers.readProperty(widgetMetadata, "textColor")
  readonly property color textColor: Color.resolveColorKey(textColorKey)

  // Dimensions
  readonly property int artSize: Style.toOdd(capsuleHeight * 0.75)
  readonly property int iconSize: Style.toOdd(capsuleHeight * 0.75)
  readonly property int verticalSize: Style.toOdd(capsuleHeight * 0.85)
  readonly property int progressWidth: 2

  // State
  readonly property bool hasPlayer: MediaService.currentPlayer !== null
  readonly property bool shouldHideIdle: (hideMode === "idle" || hideWhenIdle) && !MediaService.isPlaying
  readonly property bool shouldHideEmpty: !hasPlayer && hideMode === "hidden"
  readonly property bool isHidden: shouldHideIdle || shouldHideEmpty

  // Title
  readonly property string title: {
    if (!hasPlayer)
      return I18n.tr("bar.media-mini.no-active-player");
    var artist = MediaService.trackArtist;
    var track = MediaService.trackTitle;
    return showArtistFirst ? (artist ? `${artist} - ${track}` : track) : (artist ? `${track} - ${artist}` : track);
  }

  // SpectrumService registration for visualizer
  readonly property string spectrumComponentId: "bar:mediamini:" + root.screen?.name + ":" + root.section + ":" + root.sectionWidgetIndex
  readonly property bool needsSpectrum: root.showVisualizer && root.visualizerType !== "" && root.visualizerType !== "none" && !root.isHidden

  Layout.preferredHeight: isVertical ? -1 : Style.getBarHeightForScreen(screenName)
  Layout.preferredWidth: isVertical ? Style.getBarHeightForScreen(screenName) : -1
  Layout.fillHeight: false
  Layout.fillWidth: false

  onNeedsSpectrumChanged: {
    if (root.needsSpectrum) {
      SpectrumService.registerComponent(root.spectrumComponentId);
    } else {
      SpectrumService.unregisterComponent(root.spectrumComponentId);
    }
  }

  Component.onCompleted: {
    if (root.needsSpectrum) {
      SpectrumService.registerComponent(root.spectrumComponentId);
    }
  }

  Component.onDestruction: {
    SpectrumService.unregisterComponent(root.spectrumComponentId);
  }

  // Layout
  // For horizontal bars, height is always capsuleHeight (no animation needed to prevent jitter)
  // For vertical bars, collapse to 0 when hidden
  implicitWidth: isVertical ? (isHidden ? 0 : verticalSize) : (isHidden ? 0 : contentWidth)
  implicitHeight: isVertical ? (isHidden ? 0 : verticalSize) : capsuleHeight
  visible: !shouldHideIdle && (hideMode !== "hidden" || opacity > 0)
  opacity: isHidden ? 0.0 : ((hideMode === "transparent" && !hasPlayer) ? 0.0 : 1.0)

  property real mainContentWidth: 0
  readonly property real contentWidth: {
    if (useFixedWidth)
      return maxWidth;

    // Calculate icon/art width (must match RowLayout visibility)
    var iconWidth = 0;
    if (!hasPlayer) {
      iconWidth = iconSize;
    } else if (showAlbumArt || showProgressRing) {
      iconWidth = artSize;
    }

    var margins = isVertical ? 0 : Style.margin2S;

    // Add spacing and text width
    var textWidth = 0;
    if (titleContainer.measuredWidth > 0) {
      if (iconWidth > 0)
        margins += Style.marginS;
      textWidth = titleContainer.measuredWidth + Style.margin2XXS;
    }

    var total = iconWidth + textWidth + margins;

    // calculate the width of all elements except the scrolling text
    mainContentWidth = total - textWidth;

    return hasPlayer ? Math.min(total, maxWidth) : total;
  }

  Behavior on opacity {
    NumberAnimation {
      duration: Style.animationNormal
      easing.type: Easing.InOutCubic
    }
  }
  Behavior on implicitWidth {
    NumberAnimation {
      duration: Style.animationNormal
      easing.type: Easing.InOutCubic
    }
  }
  Behavior on implicitHeight {
    NumberAnimation {
      duration: Style.animationNormal
      easing.type: Easing.InOutCubic
    }
  }

  // Context menu
  NPopupContextMenu {
    id: contextMenu
    model: {
      var i, isCurrent;
      var items = [];
      if (root.hasPlayer && MediaService.canPlay) {
        items.push({
                     "label": MediaService.isPlaying ? I18n.tr("common.pause") : I18n.tr("common.play"),
                     "action": "play-pause",
                     "icon": MediaService.isPlaying ? "media-pause" : "media-play"
                   });
      }
      if (root.hasPlayer && MediaService.canGoPrevious) {
        items.push({
                     "label": I18n.tr("common.previous"),
                     "action": "previous",
                     "icon": "media-prev"
                   });
      }
      if (root.hasPlayer && MediaService.canGoNext) {
        items.push({
                     "label": I18n.tr("common.next"),
                     "action": "next",
                     "icon": "media-next"
                   });
      }

      // Append available players (like in Control Center) so user can switch from the bar
      var players = MediaService.getAvailablePlayers ? MediaService.getAvailablePlayers() : [];
      if (players && BarWidgetHelpers.readProperty(players, "length") > 1) {
        for (i = 0; i < BarWidgetHelpers.readProperty(players, "length"); i++) {
          isCurrent = (i === MediaService.selectedPlayerIndex);
          items.push({
                       "label": players[i].identity,
                       "action": "player-" + i,
                       "icon": isCurrent ? "check" : "disc",
                       "enabled": true,
                       "visible": true
                     });
        }
      }

      items.push({
                   "label": I18n.tr("actions.widget-settings"),
                   "action": "widget-settings",
                   "icon": "settings"
                 });
      return items;
    }

    onTriggered: action => {
      var idx;
                   contextMenu.close();
                   PanelService.closeContextMenu(screen);

                   if (action === "play-pause")
                   MediaService.playPause();
                   else if (action === "previous")
                   MediaService.previous();
                   else if (action === "next")
                   MediaService.next();
                   else if (action && action.indexOf("player-") === 0) {
                     idx = parseInt(action.split("-")[1]);
                     if (!isNaN(idx)) {
                       MediaService.switchToPlayer(idx);
                     }
                   } else if (action === "widget-settings") {
                     BarService.openWidgetSettings(screen, root.section, root.sectionWidgetIndex, root.widgetId, root.widgetSettings);
                   }
                 }
  }

  // Main container - stays at content size, pixel-perfect centered in parent
  Rectangle {
    id: container
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)
    width: Style.toOdd(root.isVertical ? (root.isHidden ? 0 : root.verticalSize) : (root.isHidden ? 0 : root.contentWidth))
    height: Style.toOdd(root.isVertical ? (root.isHidden ? 0 : root.verticalSize) : root.capsuleHeight)
    radius: Style.radiusM
    color: Style.capsuleColor
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    Behavior on width {
      NumberAnimation {
        duration: Style.animationNormal
        easing.type: Easing.InOutCubic
      }
    }
    Behavior on height {
      NumberAnimation {
        duration: Style.animationNormal
        easing.type: Easing.InOutCubic
      }
    }

    Item {
      anchors.fill: parent
      anchors.leftMargin: root.isVertical ? 0 : Style.marginS
      anchors.rightMargin: root.isVertical ? 0 : Style.marginS

      // Visualizer
      Loader {
        x: Style.pixelAlignCenter(parent.width, width)
        y: Style.pixelAlignCenter(parent.height, height)
        width: Style.toOdd(parent.width)
        height: Style.toOdd(parent.height)
        active: root.showVisualizer
        z: 0
        sourceComponent: {
          if (!root.showVisualizer)
            return null;
          if (root.visualizerType === "linear")
            return linearSpectrum;
          if (root.visualizerType === "mirrored")
            return mirroredSpectrum;
          if (root.visualizerType === "wave")
            return waveSpectrum;
          return null;
        }
      }

      // Horizontal layout
      RowLayout {
        anchors.fill: parent
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.marginS
        visible: !root.isVertical
        z: 1

        // Album art / Progress ring
        Item {
          visible: root.hasPlayer && (root.showAlbumArt || root.showProgressRing)
          Layout.preferredWidth: visible ? root.artSize : 0
          Layout.preferredHeight: visible ? root.artSize : 0
          Layout.alignment: Qt.AlignVCenter

          ProgressRing {
            id: progressRing
            anchors.fill: parent
            visible: root.showProgressRing
            progress: MediaService.trackLength > 0 ? MediaService.currentPosition / MediaService.trackLength : 0
            lineWidth: root.progressWidth
          }

          NImageRounded {
            visible: root.showAlbumArt && root.hasPlayer
            anchors.fill: parent
            anchors.margins: root.showProgressRing ? root.progressWidth * 2 : 0
            radius: width / 2
            imagePath: MediaService.trackArtUrl
            borderWidth: 0
            imageFillMode: Image.PreserveAspectCrop
          }
        }

        // Scrolling title
        NScrollText {
          id: titleContainer
          Layout.fillWidth: true
          Layout.alignment: Qt.AlignVCenter
          Layout.preferredHeight: root.capsuleHeight
          fadeRoundLeftCorners: !(root.showAlbumArt || root.showProgressRing)

          text: root.title

          scrollMode: {
            if (root.scrollingMode === "always")
              return NScrollText.ScrollMode.Always;
            if (root.scrollingMode === "hover")
              return NScrollText.ScrollMode.Hover;
            return NScrollText.ScrollMode.Never;
          }
          cursorShape: root.hasPlayer ? Qt.PointingHandCursor : Qt.ArrowCursor
          maxWidth: root.maxWidth - root.mainContentWidth
          forcedHover: mainMouseArea.containsMouse
          fadeExtent: 0.1
          fadeCornerRadius: Style.radiusM

          NText {
            color: root.hasPlayer ? root.textColor : Color.mOnSurfaceVariant
            pointSize: root.barFontSize
            elide: Text.ElideNone
          }
        }
      }

      // Vertical layout
      Item {
        id: verticalLayout
        visible: root.isVertical
        width: Style.toOdd(root.verticalSize)
        height: Style.toOdd(width)
        x: Style.pixelAlignCenter(parent.width, width)
        y: Style.pixelAlignCenter(parent.height, height)
        z: 1

        ProgressRing {
          anchors.fill: parent
          visible: root.showProgressRing
          progress: MediaService.trackLength > 0 ? MediaService.currentPosition / MediaService.trackLength : 0
          lineWidth: root.progressWidth
        }

        NImageRounded {
          visible: root.showAlbumArt && root.hasPlayer
          anchors.fill: parent
          anchors.margins: root.showProgressRing ? root.progressWidth * 2 : 0
          radius: width / 2
          imagePath: MediaService.trackArtUrl
          borderWidth: 0
          imageFillMode: Image.PreserveAspectCrop
        }
      }

      // Mouse interaction moved to root
    }
  }

  // Mouse interaction
  MouseArea {
    id: mainMouseArea
    anchors.fill: parent

    // Extend click area to screen edge if widget is at the start/end
    anchors.leftMargin: (!root.isVertical && root.section === "left" && root.sectionWidgetIndex === 0) ? -Style.marginS : 0
    anchors.rightMargin: (!root.isVertical && root.section === "right" && root.sectionWidgetIndex === root.sectionWidgetsCount - 1) ? -Style.marginS : 0
    anchors.topMargin: (root.isVertical && root.section === "left" && root.sectionWidgetIndex === 0) ? -Style.marginM : 0
    anchors.bottomMargin: (root.isVertical && root.section === "right" && root.sectionWidgetIndex === root.sectionWidgetsCount - 1) ? -Style.marginM : 0

    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton | Qt.ForwardButton | Qt.BackButton

    onClicked: mouse => {
                 if (mouse.button === Qt.LeftButton) {
                   PanelService.invokePanel(PanelService.getPanel("mediaPlayerPanel", root.screen), "toggle", [container]);
                 } else if (mouse.button === Qt.RightButton) {
                   PanelService.showContextMenu(contextMenu, container, root.screen, null);
                 } else if (mouse.button === Qt.MiddleButton && root.hasPlayer) {
                   MediaService.playPause();
                 } else if (mouse.button === Qt.ForwardButton && root.hasPlayer) {
                   MediaService.next();
                 } else if (mouse.button === Qt.BackButton && root.hasPlayer) {
                   MediaService.previous();
                 }
               }
  }

  // Components
  Component {
    id: linearSpectrum
    NLinearSpectrum {
      width: parent.width - Style.marginS
      height: 20
      values: SpectrumService.values
      fillColor: Color.mPrimary
      opacity: 0.4
      barPosition: root.barPosition
      mirrored: Settings.data.audio.spectrumMirrored
    }
  }

  Component {
    id: mirroredSpectrum
    NMirroredSpectrum {
      width: parent.width - Style.marginS
      height: parent.height - Style.marginS
      values: SpectrumService.values
      fillColor: Color.mPrimary
      opacity: 0.4
      mirrored: Settings.data.audio.spectrumMirrored
    }
  }

  Component {
    id: waveSpectrum
    NWaveSpectrum {
      width: parent.width - Style.marginS
      height: parent.height - Style.marginS
      values: SpectrumService.values
      fillColor: Color.mPrimary
      opacity: 0.4
      mirrored: Settings.data.audio.spectrumMirrored
    }
  }

  // Progress Ring Component
  component ProgressRing: Canvas {
    id: progressRingCanvas
    property real progress: 0
    property real lineWidth: 2

    function repaint() {
      if (this.visible && this.opacity > 0)
        requestPaint();
    }

    onProgressChanged: progressRingCanvas.repaint()
    Component.onCompleted: progressRingCanvas.repaint()

    Connections {
      target: Color
      function onMPrimaryChanged() {
        progressRingCanvas.repaint();
      }
    }

    onPaint: {
      if (width <= 0 || height <= 0)
        return;

      var ctx = getContext("2d");
      var centerX = width / 2;
      var centerY = height / 2;
      var radius = Math.min(width, height) / 2 - lineWidth;

      ctx.reset();

      // Background
      ctx.beginPath();
      ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
      ctx.lineWidth = lineWidth;
      ctx.strokeStyle = Qt.alpha(Color.mOnSurface, 0.4);
      ctx.stroke();

      // Progress
      ctx.beginPath();
      ctx.arc(centerX, centerY, radius, -Math.PI / 2, -Math.PI / 2 + progress * 2 * Math.PI);
      ctx.lineWidth = lineWidth;
      ctx.strokeStyle = Color.mPrimary;
      ctx.lineCap = "round";
      ctx.stroke();
    }
  }
}
