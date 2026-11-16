pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import waku.services as S
import "WallpaperTheme.js" as WallpaperTheme

Item {
  id: root

  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string portPath: Quickshell.env("NOMARCHY_PATH") || ""
  property string themeName: ""
  property string pendingPath: ""
  property string requestTheme: ""
  property bool pendingDark: true
  property string queuedPalette: ""
  property string queuedTheme: ""

  function normalizePath(path: string): string {
    return path.replace(/^file:\/+(?=[A-Za-z]:)/i, "").replace(/\\/g, "/")
  }

  function samePath(a: string, b: string): bool {
    return normalizePath(a).toLowerCase() === normalizePath(b).toLowerCase()
  }

  function request(manual: bool): string {
    if (!manual && themeName !== "wallpaper") return "inactive"
    var path = normalizePath(String(S.Wallpapers.current || ""))
    if (!path) return "no wallpaper"
    pendingPath = path
    requestTheme = themeName
    pendingDark = S.ControlCenter.darkMode
    Qt.callLater(root.startRequest)
    return "pending"
  }

  function startRequest(): void {
    if (pendingPath) S.ColorScheme.fromImage(pendingPath, "tonalspot", pendingDark)
  }

  function applyPalette(): void {
    if (!queuedPalette || apply.running) return
    if (queuedTheme !== themeName) {
      queuedPalette = ""
      return
    }
    apply.command = ["powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File",
      portPath + "/tools/theme-apply.ps1", "wallpaper", "-PaletteB64", queuedPalette,
      "-ExpectedTheme", "@" + queuedTheme]
    queuedPalette = ""
    apply.running = true
  }

  FileView {
    path: root.home + "/.local/state/nomarchy/current/theme.name"
    watchChanges: true
    printErrors: false
    onLoaded: {
      var previous = root.themeName
      root.themeName = String(text() || "").trim()
      if (previous !== root.themeName) root.pendingPath = ""
      if (root.themeName === "wallpaper" && previous !== "wallpaper") root.request(false)
    }
    onFileChanged: reload()
  }

  Connections {
    target: S.Wallpapers
    function onCurrentChanged(): void {
      if (root.themeName === "wallpaper") root.request(false)
      else if (root.pendingPath && !root.samePath(root.pendingPath, String(S.Wallpapers.current || "")))
        root.pendingPath = ""
    }
  }

  Connections {
    target: S.ControlCenter
    function onDarkModeChanged(): void {
      if (root.themeName === "wallpaper") root.request(false)
    }
  }

  Loader {
    active: root.pendingPath !== ""
    sourceComponent: Component {
      Connections {
        target: S.ColorScheme
        function onFromImageFinished(path: string, scheme: var): void {
          if (!root.pendingPath || !root.samePath(path, root.pendingPath)
              || !root.samePath(path, String(S.Wallpapers.current || ""))
              || root.requestTheme !== root.themeName) return
          if (WallpaperTheme.isDark(scheme) !== root.pendingDark) return
          var palette = String(WallpaperTheme.palette(scheme, root.pendingDark))
          root.pendingPath = ""
          if (!palette) {
            console.warn("Wallpaper theme: invalid palette")
            return
          }
          root.queuedTheme = root.requestTheme
          root.queuedPalette = WallpaperTheme.encode(Qt, palette)
          root.applyPalette()
        }
        function onFromImageFailed(path: string, error: string): void {
          if (!root.samePath(path, root.pendingPath)) return
          root.pendingPath = ""
          console.warn("Wallpaper theme: " + error)
        }
      }
    }
  }

  Process {
    id: apply
    onExited: function(exitCode: int): void {
      if (exitCode !== 0) console.warn("Wallpaper theme: could not apply palette")
      root.applyPalette()
    }
  }
}
