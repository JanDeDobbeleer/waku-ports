import QtQuick
import "PluginShellApiUtils.js" as PluginShellApiUtils

// Capability-scoped shell surface for installed third-party plugins.
//
// The callbacks are closed over one plugin id by shell.qml. A plugin can call
// them directly, but it cannot widen their scope: ordinary plugins are limited
// to their own id, and full-bar callbacks independently enforce their explicit
// non-authentication UI scope. This object avoids directly injecting the host
// shell, but it is not a QML sandbox: visual plugins share the host object tree.
QtObject {
  id: api

  required property string pluginId

  property var appLibrary: null
  property var bar: null
  property var barConfig: ({})
  property var idleConfig: ({})

  property var _serviceLookup: null
  property var _firstPartyServiceLookup: null
  property var _barEntryShellLookup: null
  property var _summon: null
  property var _hide: null
  property var _toggle: null
  property var _isOpen: null
  property var _updateSettings: null
  property var _mutateBarConfig: null

  function serviceFor(id: string): var {
    return PluginShellApiUtils.invoke(_serviceLookup, [String(id || "")], api)
  }

  // Only full-bar facades receive narrow proxies for the specific
  // non-authentication services used by the built-in bar widgets.
  function firstPartyServiceFor(id: string): var {
    return PluginShellApiUtils.invoke(_firstPartyServiceLookup, [String(id || "")], api)
  }

  function pluginShellForBarEntry(ownerId: string, moduleName: string): var {
    return PluginShellApiUtils.invoke(_barEntryShellLookup, [String(ownerId || ""), String(moduleName || "")], api)
  }

  function summon(id: string, payloadJson: string): bool {
    return !!PluginShellApiUtils.invoke(_summon, [String(id || ""), String(payloadJson || "")], api)
  }

  function hide(id: string): bool {
    return !!PluginShellApiUtils.invoke(_hide, [String(id || "")], api)
  }

  function toggle(id: string, payloadJson: string): bool {
    return !!PluginShellApiUtils.invoke(_toggle, [String(id || ""), String(payloadJson || "")], api)
  }

  function isPluginOpen(id: string): bool {
    return !!PluginShellApiUtils.invoke(_isOpen, [String(id || "")], api)
  }

  function updateEntryInline(id: string, settings: var): bool {
    return !!PluginShellApiUtils.invoke(_updateSettings, [String(id || ""), settings], api)
  }

  function mutateShellConfig(mutator: var): bool {
    return !!PluginShellApiUtils.invoke(_mutateBarConfig, [mutator], api)
  }
}
