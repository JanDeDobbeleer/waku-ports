pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import "BackgroundIntroUtils.js" as IntroUtils

// Keep theme covers alive across background service handoffs.
Item {
  id: root

  property var host: null
  property string themeToken: ""
  property string transitionToken: ""
  property string themeBackground: ""
  property var themeNativeSize: null
  property string themeColors: ""
  property string themeShell: ""
  property real themeOpacity: 1
  // A finished switch whose wallpaper is still hidden or decoding keeps its
  // cover until the wallpaper is on screen, so the fade never reveals a gap.
  property bool themeFinishing: false
  // A switch to a still without an intro of its own opens the cover with the
  // same slanted cut as an ordinary background transition, not the intro fade.
  property bool themeCut: false
  property real themeCutProgress: 0
  // A new palette restyles the whole shell in the frame it lands, and an
  // animation started in that frame begins already advanced by its length,
  // about 40% of the fade. The reveal starts two frames later instead.
  property int revealDelayFrames: 0
  readonly property bool revealing: revealDelayFrames > 0 || themeFade.running || themeCutReveal.running
  // The outgoing frame reached, or failed to reach, the screen.
  signal coverPresented()
  readonly property var backgroundService: IntroUtils.backgroundService(host)
  readonly property bool backgroundActive: !!backgroundService && !IntroUtils.field(backgroundService, "suspended")
  readonly property bool backgroundReady: backgroundActive && IntroUtils.field(backgroundService, "ready") !== false

  onBackgroundReadyChanged: {
    if (themeFinishing && backgroundReady) revealTheme()
  }

  function prepareTheme(fromPath: string, token: string, colors: string, shell: string): void {
    framePoll.stop()
    themeFade.stop()
    themeCutReveal.stop()
    revealDelayFrames = 0
    themeCut = false
    themeCutProgress = 0
    themeToken = token
    transitionToken = token
    if (themeBackground !== fromPath) {
      themeNativeSize = IntroUtils.nativeSize(backgroundService)
    }
    themeBackground = fromPath
    themeColors = colors
    themeShell = shell
    themeOpacity = 1
    themeFinishing = false
    themeFallback.restart()
  }

  function revealTheme(): void {
    if (!themeToken) return
    themeFinishing = false
    framePoll.stop()
    themeFallback.stop()
    // A background change keeps the theme, so it hands over no palette.
    if (themeToken && (themeColors || themeShell)) {
      Commons.Color.loadColors(Util.decodeBase64(themeColors))
      Commons.Color.loadShell(Util.decodeBase64(themeShell))
      Style.scheduleRefresh()
    }
    themeToken = ""
    themeColors = ""
    themeShell = ""
    revealDelayFrames = 2
  }

  // OWE hands the desktop back to the shell when an intro ends or is cut
  // short, and the new still may still be decoding then.
  function finishTheme(token: string, cut: bool): void {
    if (token !== themeToken) return
    themeCut = !!cut
    if (backgroundReady || !backgroundService) revealTheme()
    else themeFinishing = true
  }

  function themeStatus(token: string): string {
    return IntroUtils.themeStatus(token, transitionToken, themeToken, revealing)
  }

  function themeCoverStatus(token: string): string {
    return IntroUtils.coverStatus(token, themeToken, themeBackground, covers.instances)
  }

  function cancelTheme(): void {
    themeFinishing = false
    framePoll.stop()
    themeFallback.stop()
    themeFade.stop()
    themeCutReveal.stop()
    revealDelayFrames = 0
    themeCut = false
    themeCutProgress = 0
    themeToken = ""
    transitionToken = ""
    themeBackground = ""
    themeColors = ""
    themeShell = ""
  }

  NumberAnimation {
    id: themeFade
    target: root
    property: "themeOpacity"
    to: 0
    duration: Style.duration(420)
    easing.type: Easing.OutCubic
    onFinished: root.themeBackground = ""
  }

  // Matches the background service's own transition.
  NumberAnimation {
    id: themeCutReveal
    target: root
    property: "themeCutProgress"
    from: 0
    to: 1
    duration: Style.duration(840)
    easing.type: Easing.OutCubic
    onFinished: {
      root.themeBackground = ""
      root.themeCut = false
      root.themeCutProgress = 0
    }
  }

  FrameAnimation {
    running: root.revealDelayFrames > 0
    onTriggered: {
      root.revealDelayFrames -= 1
      if (root.revealDelayFrames > 0) return
      if (root.themeCut) themeCutReveal.restart()
      else themeFade.restart()
    }
  }

  Timer {
    id: themeFallback
    interval: 10000
    onTriggered: root.revealTheme()
  }

  // A renderer left over from another intro can first fade from its still.
  // Keep that preparation hidden until the actual video is fully revealed.
  // Stop once nothing is covered: a still wallpaper never reports video.
  Timer {
    id: framePoll
    interval: 16
    repeat: true
    onTriggered: {
      if (!root.themeToken) stop()
      else if (!frameStatus.running) frameStatus.running = true
    }
  }

  Process {
    id: frameStatus
    command: ["owe", "render-status"]
    property string token: ""
    onStarted: token = root.themeToken
    stdout: StdioCollector { id: frameStatusOut }
    onExited: function(exitCode) {
      if (exitCode !== 0 || token !== root.themeToken || !token) return
      if (IntroUtils.readyVideo(frameStatusOut.text)) root.revealTheme()
    }
  }

  onBackgroundActiveChanged: {
    if (!backgroundActive && themeToken) {
      framePoll.start()
      if (!frameStatus.running) frameStatus.running = true
    }
  }

  Variants {
    id: covers
    model: Quickshell.screens

    PanelWindow {
      id: panel
      required property var modelData
      property int coverFrames: 0
      readonly property bool coverReady: outgoingFrame.status === Image.Ready && coverFrames >= 2
      readonly property bool coverFailed: outgoingFrame.status === Image.Error
      onCoverReadyChanged: root.coverPresented()
      onCoverFailedChanged: root.coverPresented()
      screen: modelData
      visible: root.themeBackground !== ""
      color: "transparent"
      mask: Region {}
      anchors { top: true; bottom: true; left: true; right: true }
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.layer: WlrLayer.Bottom
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      WlrLayershell.namespace: "nomarchy-background"

      Image {
        id: outgoingFrame
        anchors.fill: parent
        source: root.themeBackground ? Util.fileUrl(root.themeBackground) : ""
        sourceSize: {
          var w = Math.ceil((parent.width || IntroUtils.field(panel.modelData, "width")) * IntroUtils.field(panel.modelData, "devicePixelRatio"))
          var h = Math.ceil((parent.height || IntroUtils.field(panel.modelData, "height")) * IntroUtils.field(panel.modelData, "devicePixelRatio"))
          var nativeSz = root.themeNativeSize
          return nativeSz && (IntroUtils.field(nativeSz, "width") < w || IntroUtils.field(nativeSz, "height") < h) ? Qt.size(IntroUtils.field(nativeSz, "width"), IntroUtils.field(nativeSz, "height")) : Qt.size(w, h)
        }
        fillMode: Image.PreserveAspectCrop
        opacity: root.themeOpacity
        // Start decoding while the remaining theme configs render.
        asynchronous: true
        onStatusChanged: panel.coverFrames = 0
        layer.enabled: root.themeCut && root.themeCutProgress > 0
        layer.smooth: true
        layer.effect: MultiEffect {
          maskEnabled: true
          maskInverted: true
          maskSource: cutMask
          maskThresholdMin: 0.5
          maskSpreadAtMin: 0.02
        }
      }

      // The background service's reveal band, opening a hole in the cover.
      Item {
        id: cutMask
        anchors.fill: parent
        visible: false
        layer.enabled: root.themeCut

        readonly property real slant: -0.18
        readonly property real centerTop: width / 2 - slant * height / 2
        readonly property real centerBottom: width / 2 + slant * height / 2
        readonly property real reach: width / 2 + Math.abs(slant) * height / 2 + 4
        readonly property real spread: reach * root.themeCutProgress

        Shape {
          anchors.fill: parent
          antialiasing: true
          preferredRendererType: Shape.CurveRenderer
          ShapePath {
            fillColor: "white"
            strokeColor: "transparent"
            startX: cutMask.centerTop - cutMask.spread; startY: 0
            PathLine { x: cutMask.centerTop + cutMask.spread; y: 0 }
            PathLine { x: cutMask.centerBottom + cutMask.spread; y: cutMask.height }
            PathLine { x: cutMask.centerBottom - cutMask.spread; y: cutMask.height }
            PathLine { x: cutMask.centerTop - cutMask.spread; y: 0 }
          }
        }
      }

      // Give the ready image a frame to reach the compositor before OWE
      // releases the shell's wallpaper underneath this cover.
      FrameAnimation {
        running: outgoingFrame.status === Image.Ready && panel.coverFrames < 2
        onTriggered: panel.coverFrames += 1
      }
    }
  }

}
