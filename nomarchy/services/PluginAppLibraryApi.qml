import QtQuick
import "PluginAppLibraryApiUtils.js" as PluginAppLibraryApiUtils

// Detached application-library capability for third-party menus. Callbacks
// expose the supported app-list operations without retaining AppLibrary or its
// ShellRoot parent in the plugin-visible object graph.
QtObject {
  id: api

  required property string ownerPluginId

  signal appsChanged()

  property var _entryName: null
  property var _entrySubtext: null
  property var _sortedEntries: null
  property var _iconSource: null
  property var _refreshIcons: null
  property var _launch: null
  property var _remove: null

  function entryName(entry: var): string {
    return _entryName ? PluginAppLibraryApiUtils.invoke(_entryName, [entry], api) : ""
  }

  function entrySubtext(entry: var): string {
    return _entrySubtext ? PluginAppLibraryApiUtils.invoke(_entrySubtext, [entry], api) : ""
  }

  function sortedEntries(query: string): var {
    return _sortedEntries ? PluginAppLibraryApiUtils.invoke(_sortedEntries, [String(query || "")], api) : []
  }

  function iconSource(icon: var): string {
    return _iconSource ? PluginAppLibraryApiUtils.invoke(_iconSource, [icon], api) : ""
  }

  function refreshIcons(): void {
    PluginAppLibraryApiUtils.invoke(_refreshIcons, [], api)
  }

  function launch(desktopId: string, name: string): void {
    PluginAppLibraryApiUtils.invoke(_launch, [String(desktopId || ""), String(name || "")], api)
  }

  function remove(desktopId: string, name: string): void {
    PluginAppLibraryApiUtils.invoke(_remove, [String(desktopId || ""), String(name || "")], api)
  }
}
