import QtQuick
import "WidgetRegistryData.js" as Data

// Detached widget-catalogue snapshot for third-party full-bar implementations.
// Plugins can render the referenced components, but mutating this local view
// cannot replace a registration in the host registry.
QtObject {
  id: api

  property var widgets: ({})
  property int revision: 0

  function metadataFor(id: var): var {
    return Data.metadataFor(widgets, id || "")
  }

  function availableIds(): var {
    return Data.availableIds(widgets)
  }

  function has(id: var): bool {
    return Data.has(widgets, id || "")
  }
}
