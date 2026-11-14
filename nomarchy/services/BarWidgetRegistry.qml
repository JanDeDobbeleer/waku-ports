import QtQuick
import "WidgetRegistryData.js" as Data

// Instance, not a singleton — instantiated once by shell.qml and injected into
// plugins that need to read or extend the widget catalogue. Relative-path
// singleton imports were creating per-importer instances which prevented the
// shell host from seeing what the bar registered.
QtObject {
  id: registry

  // { widgetId: { component: Component, metadata: var } }
  property var widgets: ({})
  property int revision: 0

  signal changed()

  function register(id: var, component: var, metadata: var): void {
    let key = String(id)
    if (!key) return
    widgets = Data.register(widgets, key, component, metadata)
    revision++
    changed()
  }

  function unregister(id: var): void {
    let key = String(id)
    if (!Data.contains(widgets, key)) return
    widgets = Data.unregister(widgets, key)
    revision++
    changed()
  }

  function metadataFor(id: var): var {
    return Data.metadataFor(widgets, id)
  }

  function availableIds(): var {
    return Data.availableIds(widgets)
  }

  function has(id: var): bool {
    return Data.has(widgets, id)
  }
}
