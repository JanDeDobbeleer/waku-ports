import QtQuick
import "PluginBarApiUtils.js" as PluginBarApiUtils

// Bar surface exposed to an installed third-party widget. Scalar presentation
// state is mirrored by Bar.qml and operations are delegated through scoped
// callbacks. The facade avoids direct host-Bar injection; it cannot isolate a
// visual child from the parent hierarchy of the QML scene that renders it.
QtObject {
  id: api

  required property string pluginId
  required property string moduleName
  property var shell: null

  property color foreground: "transparent"
  property color barForeground: "transparent"
  property color background: "transparent"
  property color urgent: "transparent"
  property string fontFamily: ""
  property string position: "top"
  property bool vertical: false
  property int barSize: 0
  property bool transparent: false
  property bool foregroundAnimationEnabled: true
  property bool centerSectionRevealHeld: false
  property bool traySectionDragActive: false
  property bool traySectionPopoutOpen: false
  property bool _centerHoverRevealSuppressed: false
  readonly property bool centerHoverRevealSuppressed: _centerHoverRevealSuppressed
  property var activePopout: null
  property var clickTargets: []
  property var layoutConfig: ({})
  readonly property var foreignPopoutMarker: ({ foreign: true })

  property var _showTooltip: null
  property var _hideTooltip: null
  property var _registerClickTarget: null
  property var _unregisterClickTarget: null
  property var _requestPopout: null
  property var _releasePopout: null
  property var _notePopoutCard: null
  property var _popoutCardFor: null
  property var _switchPanelFrom: null
  property var _targetBelongsToWindow: null
  property var _moduleWidgets: null
  property var _run: null
  property var _setCenterHoverRevealSuppressed: null

  function setCenterHoverRevealSuppressed(value: bool): void {
    PluginBarApiUtils.invoke(_setCenterHoverRevealSuppressed, [!!value], api)
  }

  function showTooltip(target: var, text: string): void {
    PluginBarApiUtils.invoke(_showTooltip, [target, String(text || "")], api)
  }

  function hideTooltip(target: var): void {
    PluginBarApiUtils.invoke(_hideTooltip, [target], api)
  }

  function registerClickTarget(target: var): void {
    PluginBarApiUtils.invoke(_registerClickTarget, [target], api)
  }

  function unregisterClickTarget(target: var): void {
    PluginBarApiUtils.invoke(_unregisterClickTarget, [target], api)
  }

  function requestPopout(owner: var): void {
    PluginBarApiUtils.invoke(_requestPopout, [owner], api)
  }

  function releasePopout(owner: var): void {
    PluginBarApiUtils.invoke(_releasePopout, [owner], api)
  }

  function notePopoutCard(card: var): void {
    PluginBarApiUtils.invoke(_notePopoutCard, [card], api)
  }

  // Where the last panel's card stood, if it was in this owner's section.
  function popoutCardFor(owner: var): var {
    return PluginBarApiUtils.invoke(_popoutCardFor, [owner], api)
  }

  function switchPanelFrom(owner: var, direction: var): bool {
    return !!PluginBarApiUtils.invoke(_switchPanelFrom, [owner, direction], api)
  }

  function targetBelongsToWindow(target: var, window: var): bool {
    return !!PluginBarApiUtils.invoke(_targetBelongsToWindow, [target, window], api)
  }

  function moduleWidgets(id: string): var {
    var result = PluginBarApiUtils.invoke(_moduleWidgets, [String(id || "")], api)
    return result === undefined ? [] : result
  }

  function run(command: string): void {
    PluginBarApiUtils.invoke(_run, [String(command || "")], api)
  }
}
