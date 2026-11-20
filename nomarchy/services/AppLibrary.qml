import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import waku.services
import "AppSearch.js" as AppSearch

// Shared application library: the engine's Start-menu list, filtered by the hide list in
// default/nomarchy/launcher.hides. Injected as shell.appLibrary; the menu's Apps submenu is the
// consumer.
Item {
  id: root

  property string nomarchyPath: Quickshell.shellDir

  property var configuredHiddenEntryIds: ({})

  // Emitted whenever the visible application set may have changed: apps appeared or vanished,
  // or the hide list reloaded.
  signal appsChanged()

  function entryName(entry: var): string {
    return AppSearch.entryName(entry)
  }

  function entrySubtext(entry: var): string {
    return AppSearch.entrySubtext(entry)
  }

  function isHiddenEntry(entry: var): bool {
    var id = String(AppSearch.entryId(entry) || "")
    return root.configuredHiddenEntryIds[id] === true
  }

  function sortedEntries(query: string): var {
    var values = AppSearch.applicationValues(DesktopEntries.applications)
    return AppSearch.sortedEntries(values, query, function(entry: var): bool { return root.isHiddenEntry(entry) })
  }

  function iconSource(icon: string): string {
    var value = String(icon || "")
    if (value.length === 0) return Quickshell.iconPath("application-x-executable", true)
    if (value.indexOf("file://") === 0 || value.indexOf("image://") === 0) return value
    if (value.charAt(0) === "/" || /^[A-Za-z]:[\\/]/.test(value)) return Util.fileUrl(value)
    var themed = Quickshell.iconPath(value, true)
    if (themed.length > 0) return themed
    return Quickshell.iconPath("application-x-executable", true)
  }

  // Consumers call this when they open; the engine keeps its own icons current.
  function refreshIcons(): void {
  }

  // The engine's entry starts itself: an exe, a UWP app or a shortcut.
  function launch(desktopId: string, name: string): void {
    var id = String(desktopId || "")
    if (!id) return
    var entry = DesktopEntries.byId(id)
    if (entry && typeof entry.execute === "function") entry.execute()
  }

  function normalizeDesktopId(id: string): string {
    var value = String(id || "").trim()
    if (value.slice(-8) === ".desktop") value = value.slice(0, -8)
    return value
  }

  function loadConfiguredHides(rawText: string): void {
    var next = ({})
    var lines = String(rawText || "").split(/\n/)
    for (let i = 0; i < lines.length; i++) {
      let id = root.normalizeDesktopId(lines[i])
      if (id.length > 0) next[id] = true
    }
    root.configuredHiddenEntryIds = next
    root.appsChanged()
  }

  FileView {
    path: root.nomarchyPath + "/default/nomarchy/launcher.hides"
    watchChanges: true
    printErrors: false
    onLoaded: root.loadConfiguredHides(text())
    onFileChanged: root.loadConfiguredHides(text())
    onLoadFailed: root.loadConfiguredHides("")
  }

  Connections {
    target: DesktopEntries.applications
    function onValuesChanged() { root.appsChanged() }
  }

  // The Start-menu scan starts only on request.
  Component.onCompleted: AppsService.refresh()
}
