import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "BackgroundSwitchUtils.js" as BackgroundSwitchUtils

// Sequence a background change around an intro. The outgoing frame is held
// under BackgroundIntro's cover, the link moves once that cover is on screen,
// the new still goes in beneath it, OWE plays the clip, and the cover fades
// once the clip is moving, or opens with the ordinary cut onto a still without
// one. Each step waits on the event that allows it, so the commands that
// start a change only hand it over.
Item {
  id: root

  property var intro: null
  readonly property var backgroundService: BackgroundSwitchUtils.field(intro, "backgroundService")
  readonly property string home: (Quickshell.env("HOME") || "")
  readonly property string backgroundLink: home + "/.local/state/nomarchy/current/background"
  readonly property string transitionCache: home + "/.cache/nomarchy/background-transitions"
  readonly property string themeSetLock: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/nomarchy-theme-set.lock"

  // The change in progress, named by its cover's token.
  property string token: ""
  property string still: ""
  property string clipPath: ""
  // Whether OWE already holds the clip decoded, as a theme switch prepares it
  // while its templates render.
  property bool prepared: false
  property bool linked: false
  property bool started: false
  property int serial: 0
  // Snapshots this service or a theme switch made for a cover, removed once
  // nothing shows them.
  property var ownedCovers: []
  // A selection made while an earlier change is still covered or revealing
  // waits for it, since its outgoing frame would miss that change's cover.
  property string queuedPath: ""
  // A theme switch reloads Hyprland once no intro plays: a reload pauses
  // video presentation.
  property bool reloadPending: false
  // The link's next target while an earlier ln still runs, so the link always
  // ends on the latest selection.
  property string pendingLink: ""

  // A theme switch waits while this is set, so it cannot capture a frame from
  // under a cover or take over from a change still being set up.
  readonly property bool busy: !!intro && (BackgroundSwitchUtils.field(intro, "themeToken") !== "" || BackgroundSwitchUtils.field(intro, "revealing")) || snapshotProc.running

  // The background the latest selection names. The link only moves once a
  // change is under way, so a selection still queued or covered is not there
  // yet.
  function selected(): string {
    if (queuedPath) return queuedPath
    if (token && intro && (snapshotProc.running || token === BackgroundSwitchUtils.field(intro, "themeToken"))) return still
    return backgroundService ? BackgroundSwitchUtils.field(backgroundService, "currentBackground") : ""
  }

  function displayedStill(): string {
    var path = backgroundService ? (BackgroundSwitchUtils.field(backgroundService, "displayedBackground") || BackgroundSwitchUtils.field(backgroundService, "currentBackground")) : ""
    return path && !Util.isVideoPath(path) ? path : ""
  }

  // nomarchy-theme-bg-set's selection, with the intro it found for it.
  function switchTo(path: string, clipPath: string): string {
    path = String(path || "").trim()
    if (!path || !intro || !backgroundService) return "unavailable"
    if (busy) {
      queuedPath = path
    } else if (path !== BackgroundSwitchUtils.field(backgroundService, "currentBackground")) {
      // A playing intro hides the shell's background, so even a still
      // without an intro of its own has to come in under the cover.
      if (clipPath || BackgroundSwitchUtils.field(backgroundService, "suspended")) {
        begin(path, clipPath)
      } else {
        link(path)
        backgroundService.setBackground(path, false)
      }
    }
    return "ok"
  }

  function link(target: string): void {
    pendingLink = target
    if (!linkProc.running) startLink()
  }

  function startLink(): void {
    linkProc.target = pendingLink
    pendingLink = ""
    linkProc.command = ["ln", "-nsf", linkProc.target, backgroundLink]
    linkProc.running = true
  }

  function begin(path: string, clipPath: string): void {
    serial += 1
    token = "background-" + serial
    still = path
    root.clipPath = clipPath
    prepared = false
    linked = false
    started = false
    if (BackgroundSwitchUtils.field(backgroundService, "suspended")) {
      // A playing video shows a frame only OWE can capture.
      snapshotProc.forToken = token
      snapshotProc.file = transitionCache + "/previous-" + serial + ".ppm"
      snapshotProc.command = ["C:/Program Files/Git/usr/bin/bash.exe", "-c", 'mkdir -p "$1" && exec owe render "$2"', "_", transitionCache,
                              JSON.stringify({ cmd: "snapshot", path: snapshotProc.file })]
      snapshotProc.running = true
    } else {
      cover(displayedStill())
    }
  }

  function cover(path: string): void {
    BackgroundSwitchUtils.call(intro, "prepareTheme", [path, token, "", ""])
    advance()
  }

  // A theme switch has put up its cover and repointed the link itself; the
  // rest is the same as a background change, plus Hyprland's reload.
  function play(tok: string, stillPath: string, clipPath: string, preparedFlag: string): string {
    reloadPending = true
    if (!intro || tok !== BackgroundSwitchUtils.field(intro, "themeToken")) return "superseded"
    token = tok
    still = stillPath
    root.clipPath = clipPath
    prepared = preparedFlag === "true"
    linked = true
    started = false
    own(BackgroundSwitchUtils.field(intro, "themeBackground"))
    advance()
    return "ok"
  }

  function own(path: string): void {
    if (path && path.indexOf(transitionCache + "/") === 0 && ownedCovers.indexOf(path) === -1)
      ownedCovers = ownedCovers.concat([path])
  }

  function advance(): void {
    if (!token || !intro || token !== BackgroundSwitchUtils.field(intro, "themeToken")) return
    var coverStatus = BackgroundSwitchUtils.call(intro, "themeCoverStatus", [token])
    if (coverStatus === "loading") return
    // Moving the link cancels a playing intro and hands the desktop back to
    // the shell, so it waits for the cover.
    if (!linked) {
      if (pendingLink !== still && !(linkProc.running && linkProc.target === still)) link(still)
      return
    }
    // An earlier clip ends once the link has moved on from it.
    if (started || playProc.running) return
    started = true
    // The shell holds the new still before OWE hands the desktop back, so the
    // old one cannot flash between the clip and the still. With the
    // background plugin disabled the cover still has to come down.
    if (backgroundService) BackgroundSwitchUtils.call(backgroundService, "setBackground", [still, true])
    if (clipPath && coverStatus !== "error") {
      playProc.forToken = token
      playProc.command = prepared
        ? ["owe", "intro", "--start", "first-frame", "--refresh", clipPath]
        : ["C:/Program Files/Git/usr/bin/bash.exe", "-c", 'owe refresh >/dev/null && exec owe intro --start first-frame "$1"', "_", clipPath]
      playProc.running = true
    } else {
      BackgroundSwitchUtils.call(intro, "finishTheme", [token, !clipPath])
    }
  }

  function settle(): void {
    if (busy) return
    if (reloadPending && !playProc.running && !reloadLock.running) reloadLock.running = true
    ownedCovers = BackgroundSwitchUtils.keepCover(ownedCovers, BackgroundSwitchUtils.field(intro, "themeBackground"), function(path: string): void {
      Quickshell.execDetached(["rm", "-f", path])
    })
    // The queued selection goes back through nomarchy-theme-bg-set, which
    // finds its intro under the settings and theme as they are now.
    if (queuedPath) {
      Quickshell.execDetached(["nomarchy-theme-bg-set", queuedPath])
      queuedPath = ""
    }
  }

  // A reveal clears its token just before its animation starts, so settling
  // waits until both have changed.
  Connections {
    target: root.intro
    function onCoverPresented() { root.advance() }
    function onThemeTokenChanged() {
      // A theme switch taking the cover brings its own background.
      if (BackgroundSwitchUtils.field(root.intro, "themeToken") && BackgroundSwitchUtils.field(root.intro, "themeToken") !== root.token) root.queuedPath = ""
      Qt.callLater(root.settle)
    }
    function onRevealingChanged() { Qt.callLater(root.settle) }
  }

  // A theme switch holds this lock while it stages, and may start an intro
  // of its own before releasing it. The reload is decided once the lock is
  // taken and runs before it is released, so no new intro can start between.
  Process {
    id: reloadLock
    command: ["flock", root.themeSetLock, "C:/Program Files/Git/usr/bin/bash.exe", "-c", 'echo locked; read -r go; [[ $go != reload ]] || exec nomarchy-restart-hyprctl']
    stdinEnabled: true
    stdout: SplitParser {
      onRead: {
        var go = !root.busy && !playProc.running
        if (go) root.reloadPending = false
        reloadLock.write(go ? "reload\n" : "wait\n")
      }
    }
  }

  Process {
    id: snapshotProc
    property string forToken: ""
    property string file: ""
    onExited: function(exitCode) {
      // A theme switch that took the cover meanwhile wins.
      if (forToken !== root.token || BackgroundSwitchUtils.field(root.intro, "themeToken") !== "") {
        Quickshell.execDetached(["rm", "-f", file])
      } else if (exitCode === 0) {
        root.own(file)
        root.cover(file)
      } else {
        root.cover(root.displayedStill())
      }
    }
  }

  Process {
    id: linkProc
    property string target: ""
    onExited: {
      if (root.pendingLink) root.startLink()
      else if (root.token && target === root.still) root.linked = true
      root.advance()
    }
  }

  Process {
    id: playProc
    property string forToken: ""
    onExited: {
      // Played or not, the cover then fades to the still beneath it.
      if (root.intro) root.intro.finishTheme(forToken)
      root.advance()
      root.settle()
    }
  }
}
