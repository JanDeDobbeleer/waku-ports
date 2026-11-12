pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQml.Models
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "BarModel.js" as BarModel

Item {
  id: root

  // The nomarchy-shell host injects nomarchyPath from NOMARCHY_PATH.
  property string nomarchyPath: (Quickshell.env("NOMARCHY_PATH") || "")
  // Injected by the host shell so bar slots can resolve enabled widgets.
  property var barWidgetRegistry: fallbackBarWidgetRegistry
  property int barWidgetRegistryRevision: 0
  // Read-only registry view for third-party full bars; the built-in bar does
  // not otherwise need it, but declaring it keeps clone construction atomic.
  property var pluginRegistry: null
  // Injected by the host shell every time shell.json is reloaded. Holds the
  // `bar:` subtree: position, background, layout. The host owns file IO;
  // the bar just renders whatever it's handed. The bar font follows the
  // OS-level fontconfig monospace binding — it is not stored in shell.json.
  property var barConfig: ({})
  // Injected by the host shell. Used for shell-wide actions such as opening
  // settings and persisting inline widget state.
  property var shell: null
  // Manifest for the active bar option. Present for custom bars and useful for
  // diagnostics; the built-in bar does not otherwise need it.
  property var manifest: null
  Connections {
    target: root.barWidgetRegistry
    ignoreUnknownSignals: true
    function onRevisionChanged(): void { root.barWidgetRegistryRevision++ }
  }
  QtObject {
    id: fallbackBarWidgetRegistry
    property var widgets: ({})
    property int revision: 0
    function metadataFor(id: var): var { return null }
  }
  // Mirrors the on-disk `bar-off` flag so the user can hide the bar without
  // killing the entire shell. Hidden panels stay mapped but park off-screen
  // without an exclusion zone; updated by the FileView watcher further down.
  property bool barHidden: false
  property string home: (Quickshell.env("HOME") || "")
  property string stateHome: home + "/.local/state"
  property string nomarchyConfigDir: home + "/.config/nomarchy"
  property var fallbackBarConfig: ({
    position: "top",
    background: "opaque",
    layout: { left: [], centerBegin: [], center: [], centerEnd: [], right: [] }
  })
  property var layoutConfig: ({ left: [], centerBegin: [], center: [], centerEnd: [], right: [], tray: [] })
  property bool requestedTransparent: false
  property bool useTransparentForeground: false
  property bool transparent: false
  // A see-through bar that Hyprland blurs behind (the bar-glassy toggle), so
  // its theme background stays faintly. A transparent bar wins over it.
  property bool glassy: false
  // The look the blur behind the bar was last synced for. A background set by
  // editing shell.json skips the CLI, so the bar syncs Hyprland's blur itself.
  property string glassSyncedLook: ""
  // One bar surface exists per monitor and each reports into this count, so a
  // pointer crossing from one monitor's bar to another's stays counted however
  // the enter and leave interleave. A single shared bool would be left false by
  // whichever event landed last.
  property int barHoverCount: 0
  // True while the pointer is over any bar, widgets included.
  readonly property bool barHovered: barHoverCount > 0
  // The indicator peek, open while the pointer is on any bar. Plugins read it
  // by this name through their bar API.
  property bool centerSectionRevealHeld: false
  property bool centerHoverRevealSuppressed: false
  property int barConfigSerial: 0
  property string position: "top"
  // Resolves through fontconfig at paint time (Style.font.family defaults
  // to "monospace"), so changing the system font (via `nomarchy-font-set`)
  // updates the bar without a reload.
  property string fontFamily: Style.font.family
  // Bound to the central Color singleton so the bar tracks shell.toml's
  // [bar] section. Property names kept for the rest of this file's bindings.
  property color themeForeground: Commons.Color.bar.text
  property color themeContrastForeground: Commons.Color.background
  property color transparentForeground: Commons.Color.bar.text
  property color foreground: themeForeground
  property color barForeground: useTransparentForeground ? transparentForeground : themeForeground
  property bool foregroundAnimationEnabled: true
  property color background: Commons.Color.bar.background
  readonly property color glassBackground: Qt.rgba(background.r, background.g, background.b, Math.min(background.a, 0.35))
  property color urgent: Commons.Color.bar.active

  // A theme change cross-fades the bar's colors. Cycling the background
  // between opaque, glassy and clear jumps, text color included.
  Behavior on barForeground { enabled: root.foregroundAnimationEnabled; ColorAnimation { duration: Style.duration(250); easing.type: Easing.OutCubic } }
  Behavior on background { ColorAnimation { duration: Style.duration(250); easing.type: Easing.OutCubic } }
  Behavior on urgent { ColorAnimation { duration: Style.duration(250); easing.type: Easing.OutCubic } }
  property var tooltipTarget: null
  property var pendingTooltipTarget: null
  property string tooltipText: ""
  property string pendingTooltipText: ""
  property bool tooltipShown: false
  property int tooltipRequest: 0
  property var activePopout: null
  // Where the open panel's card stands, and in which section of the bar, so
  // a panel taking over in the same section can start its card from there.
  property var popoutCard: null

  // The section a panel's widget sits in, the center's pieces counted as one,
  // as keyboard switching between panels counts them.
  function popoutSectionOf(owner: var): string {
    for (let i = 0; i < moduleSlots.length; i++) {
      let slot = moduleSlots[i]
      if (slot && slot.activeItem === owner) return BarModel.navigationRegions(slot.region).join(" ")
    }
    return ""
  }

  // Reported by the open panel. Only a screen name and four numbers are kept,
  // whoever reports them; the section comes from the bar's own layout.
  function notePopoutCard(card: var): void {
    popoutCard = BarModel.copyPopoutCard(card, popoutSectionOf(activePopout))
  }

  // The last card, copied, for a panel taking over in the same section: one
  // switching across the bar opens fresh instead of flying the card over it.
  function popoutCardFor(owner: var): var {
    return BarModel.popoutCardFor(popoutCard, popoutSectionOf(owner))
  }
  // A widget is being dragged that could go into the tray section, so the
  // tray's drawer opens to show where.
  readonly property bool traySectionDragActive: BarModel.traySectionDragActive(barDragSource)
  // An open panel from a widget in the tray section keeps the tray's drawer
  // open, so the panel's widget stays on screen under it.
  readonly property bool traySectionPopoutOpen: {
    var owner = activePopout
    if (!owner) return false
    for (let i = 0; i < moduleSlots.length; i++) {
      let slot = moduleSlots[i]
      if (slot && slot.activeItem === owner) return slot.region === "tray"
    }
    return false
  }
  property ModuleSlot barDragSource: null
  // Where the dragged widget would land: { slot, after } beside a widget, or
  // { region, after } at an end of a section (see BarModel.centerDropTarget
  // and BarModel.traySectionDropTarget).
  property var barDragTarget: null
  readonly property string barDragRegion: BarModel.dropRegion(barDragTarget)
  // Where room is open for the dragged widget (BarModel.dropRoom), and that
  // room's length along the bar.
  property var barDragRoom: null
  property real barDragExtent: 0
  // The room as the dragged widget's ghost draws it: its length along the
  // bar, and across it the widget's own size, as its spacers have.
  readonly property real barDragGhostWidth: BarModel.dragGhostWidth(vertical, barDragSource, barDragExtent)
  readonly property real barDragGhostHeight: BarModel.dragGhostHeight(vertical, barDragSource, barDragExtent)
  // How much of the room each place holds, keyed "region:index"
  // (BarModel.fadeShares), and so its length there in whole pixels
  // (BarModel.roomLengths). The places holding some of it, as one string,
  // change only as a place opens or closes, so a section's rows aren't worked
  // out again on every frame of a move. The dragged widget's own place is
  // `barDragHome`, where it keeps its room in its slot.
  property var barDragShares: ({})
  readonly property var barDragLengths: BarModel.roomLengths(barDragExtent, barDragShares)
  readonly property string barDragPlaces: Object.keys(barDragShares).filter(function(place: var): var { return barDragShares[place] > 0 }).sort().join(",")
  property string barDragHome: ""
  // The keys each section showed as the drag started (layoutWidgets). They
  // hold while no widget moves about.
  property string barDragKeys: ""
  // The spacers a drag has put in the sections, where a released widget can
  // land (DragSpacer).
  property list<DragSpacer> dragSpacers: []
  // A released widget's ghost gliding from the pointer to where it lands
  // (settleBarDrag), and how far along it is.
  property var barSettle: null
  property real barSettleProgress: 0
  property var barDragWindow: null
  property var barDragScreen: null
  property url barDragImageUrl: ""
  property real barDragSceneX: 0
  property real barDragSceneY: 0
  property real barDragScreenX: 0
  property real barDragScreenY: 0
  property real barDragOffsetX: 0
  property real barDragOffsetY: 0
  // True once the drag has pulled far enough off the bar that letting go
  // removes the widget instead of moving it. Its room closes meanwhile, as
  // though it were gone already (fadeDragRoom).
  property bool barDragRemoveArmed: false
  // Pulling a widget this far past the bar arms its removal. Generous enough
  // that overshooting a drop keeps reading as a move.
  readonly property real barDragRemoveDistance: Style.spaceReal(48)
  // A widget let go of past that, until its entry is written out of the
  // layout once its poof has played: { key, region, id }.
  property var barRemoval: null
  // The poof a removed widget vanishes in, while it plays: { screen, x, y,
  // width, height, image, seed }, the ghost as it was let go (its center,
  // size and picture) and a seed that lays each poof out a little
  // differently.
  property var barPoof: null
  property bool barMoveActive: false
  property string barMoveCandidate: ""
  property var barMoveWindow: null
  property var barMoveScreen: null
  property list<var> clickTargets: []
  // Every widget's place on every bar surface (ModuleSlot), and every widget
  // itself (WidgetHost), which its slot borrows from its surface's pool.
  property list<ModuleSlot> moduleSlots: []
  property list<WidgetHost> widgetHosts: []
  property list<CenterBox> centerBoxes: []
  property var pluginBarApis: ({})
  // target -> { target, pluginId, clickTarget, popout }. Keyed by object so a
  // registration edits one entry in place instead of copying and rescanning an
  // array in QML; Qt's Map still finds a key by a native linear scan.
  readonly property var pluginObjectOwners: new Map()
  property bool pluginBarApiSyncQueued: false

  Component {
    id: pluginBarApiComponent
    PluginBarApi { }
  }

  function publicLayoutConfig(): var {
    return JSON.parse(JSON.stringify(root.layoutConfig || {}))
  }

  function bindPluginBarApi(api: PluginBarApi): void {
    if (!api) return
    api.foreground = Qt.binding(function(): color { return root.foreground })
    api.barForeground = Qt.binding(function(): color { return root.barForeground })
    api.background = Qt.binding(function(): color { return root.background })
    api.urgent = Qt.binding(function(): color { return root.urgent })
    api.fontFamily = Qt.binding(function(): string { return root.fontFamily })
    api.position = Qt.binding(function(): string { return root.position })
    api.vertical = Qt.binding(function(): bool { return root.vertical })
    api.barSize = Qt.binding(function(): int { return root.barSize })
    api.transparent = Qt.binding(function(): bool { return root.transparent })
    api.foregroundAnimationEnabled = Qt.binding(function(): bool { return root.foregroundAnimationEnabled })
    api.centerSectionRevealHeld = Qt.binding(function(): bool { return root.centerSectionRevealHeld })
    api._centerHoverRevealSuppressed = Qt.binding(function(): bool { return root.centerHoverRevealSuppressed })
    api.traySectionDragActive = Qt.binding(function(): bool { return root.traySectionDragActive })
    api.traySectionPopoutOpen = Qt.binding(function(): bool { return root.traySectionPopoutOpen })
    root.syncPluginBarApiObjects(api, undefined)
  }

  // Each api keeps its own detached copy of the layout. A flush serialises
  // the layout once and passes the string in so it is not re-serialised for
  // every plugin.
  function syncPluginBarApiObjects(api: PluginBarApi, layoutSnapshot: var): void {
    BarModel.syncPluginBarApiObjects(root, api, layoutSnapshot)
  }

  function pluginObjectRecord(target: var): var {
    return BarModel.pluginObjectRecord(pluginObjectOwners, target)
  }

  function markPluginObject(pluginId: var, target: var, role: var): bool {
    var key = String(pluginId || "")
    if (!key || !target) return false
    return BarModel.markPluginObject(pluginObjectOwners, key, target, role)
  }

  function unmarkPluginObject(pluginId: var, target: var, role: var): void {
    var key = String(pluginId || "")
    BarModel.unmarkPluginObject(pluginObjectOwners, key, target, role)
  }

  function pluginOwnsBarObject(pluginId: var, target: var): bool {
    return BarModel.pluginOwnsBarObject(pluginObjectOwners, pluginId, target)
  }

  function pluginClickTargets(pluginId: var): var {
    var out = []
    for (let i = 0; i < root.clickTargets.length; i++) {
      let target = root.clickTargets[i]
      if (root.pluginOwnsBarObject(pluginId, target)) out.push(target)
    }
    return out
  }

  // Every click target registration, popout change and layout change used to
  // resync every plugin api synchronously. Startup alone is hundreds of
  // registrations, each walking every api and every target, so coalesce them
  // into one resync per event-loop turn (as onWidgetHostsChanged already does
  // for prunePluginBarApis). bindPluginBarApi still syncs a brand-new api
  // directly so a widget never sees an empty api on its first read.
  function schedulePluginBarApiSync(): var {
    if (pluginBarApiSyncQueued) return
    pluginBarApiSyncQueued = true
    Qt.callLater(root.syncAllPluginBarApiObjects)
  }

  function syncAllPluginBarApiObjects(): var {
    pluginBarApiSyncQueued = false
    var layoutSnapshot = JSON.stringify(root.layoutConfig || {})
    for (let id in pluginBarApis) {
      let api = pluginBarApis[id]
      if (api) root.syncPluginBarApiObjects(api, layoutSnapshot)
    }
  }

  function registerPluginClickTarget(pluginId: var, target: var): void {
    if (!root.markPluginObject(pluginId, target, "clickTarget")) return
    root.registerClickTarget(target)
  }

  function unregisterPluginClickTarget(pluginId: var, target: var): void {
    if (!root.pluginOwnsBarObject(pluginId, target)) return
    root.unregisterClickTarget(target)
    root.unmarkPluginObject(pluginId, target, "clickTarget")
  }

  // A plugin may read api.activePopout right after asking for its popout, so
  // its own api is brought up to date inline; everyone else waits for the
  // coalesced resync.
  function requestPluginPopout(pluginId: var, owner: var): void {
    if (!root.markPluginObject(pluginId, owner, "popout")) return
    root.requestPopout(owner)
    root.syncPluginBarApiObjects(pluginBarApis[String(pluginId || "")], undefined)
  }

  function releasePluginPopout(pluginId: var, owner: var): void {
    if (!root.pluginOwnsBarObject(pluginId, owner)) return
    root.releasePopout(owner)
    root.unmarkPluginObject(pluginId, owner, "popout")
    root.syncPluginBarApiObjects(pluginBarApis[String(pluginId || "")], undefined)
  }

  function pluginBarApiFor(pluginId: string, moduleName: var, registered: bool): var {
    if (!pluginId) return null

    if (pluginBarApis[pluginId]) {
      pluginBarApis[pluginId].shell = BarModel.pluginShell(root.shell, pluginId, moduleName, registered)
      return pluginBarApis[pluginId]
    }

    var api = pluginBarApiComponent.createObject(null, {
      pluginId: pluginId,
      moduleName: String(moduleName || ""),
      shell: BarModel.pluginShell(root.shell, pluginId, moduleName, registered),
      _showTooltip: function(target: var, text: var): var { root.showTooltip(target, text) },
      _hideTooltip: function(target: var): var { root.hideTooltip(target) },
      _registerClickTarget: function(target: var): var { root.registerPluginClickTarget(pluginId, target) },
      _unregisterClickTarget: function(target: var): var { root.unregisterPluginClickTarget(pluginId, target) },
      _requestPopout: function(owner: var): var { root.requestPluginPopout(pluginId, owner) },
      _releasePopout: function(owner: var): var { root.releasePluginPopout(pluginId, owner) },
      _switchPanelFrom: function(owner: var, direction: var): var { return root.switchPanelFrom(owner, direction) },
      _notePopoutCard: function(card: var): var { root.notePopoutCard(card) },
      _popoutCardFor: function(owner: var): var { return root.popoutCardFor(owner) },
      _targetBelongsToWindow: function(target: var, window: var): var { return root.targetBelongsToWindow(target, window) },
      _moduleWidgets: function(requestedId: var): var {
        return String(requestedId || "") === String(moduleName || "")
          ? root.moduleWidgets(moduleName) : []
      },
      _run: function(command: var): var { root.run(command) },
      _setCenterHoverRevealSuppressed: function(value: var): var {
        root.centerHoverRevealSuppressed = !!value
      }
    })
    if (!api) return null
    root.bindPluginBarApi(api)

    pluginBarApis = BarModel.withValue(pluginBarApis, pluginId, api)
    return api
  }

  function pluginBarApiUsed(pluginId: var): bool {
    for (let i = 0; i < widgetHosts.length; i++) {
      let host = widgetHosts[i]
      if (host && host.pluginApiId === pluginId) return true
    }
    return false
  }

  function releasePluginObjects(pluginId: var): void {
    var owned = Array.from(pluginObjectOwners.values())
    for (let i = 0; i < owned.length; i++) {
      let record = owned[i]
      if (!record || record.pluginId !== pluginId) continue
      if (record.clickTarget) root.unregisterClickTarget(record.target)
      if (record.popout && root.activePopout === record.target) root.releasePopout(record.target)
      pluginObjectOwners.delete(record.target)
    }
  }

  function prunePluginBarApis(): var {
    var next = ({})
    for (let id in pluginBarApis) {
      let api = pluginBarApis[id]
      if (root.pluginBarApiUsed(id)) {
        next[id] = api
        continue
      }
      root.releasePluginObjects(id)
      if (api && typeof api.destroy === "function") api.destroy()
    }
    pluginBarApis = next
  }

  onActivePopoutChanged: schedulePluginBarApiSync()
  onClickTargetsChanged: schedulePluginBarApiSync()
  onLayoutConfigChanged: schedulePluginBarApiSync()
  // A layout written from elsewhere that moves widgets about mid-drag leaves
  // the drag's room in the wrong places, so the drag lets go and the layout
  // stands as written. A widget whose settings change keeps its key
  // (BarModel.layoutWidgets), so that alone leaves the drag be. Later, since
  // the change is still reaching the sections' models.
  onLayoutWidgetsChanged: if (barDragSource && JSON.stringify(layoutSections) !== barDragKeys) Qt.callLater(clearBarDrag)
  onWidgetHostsChanged: Qt.callLater(prunePluginBarApis)

  Component.onDestruction: {
    for (let id in pluginBarApis) {
      root.releasePluginObjects(id)
      if (pluginBarApis[id] && typeof pluginBarApis[id].destroy === "function")
        pluginBarApis[id].destroy()
    }
    pluginBarApis = ({})
  }

  function registerClickTarget(target: var): void {
    if (!target || clickTargets.indexOf(target) !== -1) return
    var next = clickTargets.slice()
    next.push(target)
    clickTargets = next
  }

  function unregisterClickTarget(target: var): void {
    var next = clickTargets.filter(function(item: var): var { return item !== target })
    clickTargets = next
  }

  function registerModuleSlot(slot: var): void {
    if (!slot || moduleSlots.indexOf(slot) !== -1) return
    moduleSlots = Array.from(moduleSlots).concat([slot])
  }

  function unregisterModuleSlot(slot: var): void {
    var next = moduleSlots.filter(function(item: var): var { return item !== slot })
    moduleSlots = next
  }

  function registerWidgetHost(host: var): void {
    if (!host || widgetHosts.indexOf(host) !== -1) return
    widgetHosts = Array.from(widgetHosts).concat([host])
  }

  function unregisterWidgetHost(host: var): void {
    widgetHosts = widgetHosts.filter(function(item: var): var { return item !== host })
  }

  function registerCenterBox(box: var): void {
    if (!box || centerBoxes.indexOf(box) !== -1) return
    centerBoxes = Array.from(centerBoxes).concat([box])
  }

  function unregisterCenterBox(box: var): void {
    centerBoxes = centerBoxes.filter(function(item: var): var { return item !== box })
  }

  // The center box drawn on a bar surface. Each surface declares one in the
  // middle of the bar and one beside the right section, and draws one of them.
  function centerBoxFor(window: var): var {
    for (let i = 0; i < centerBoxes.length; i++) {
      let box = centerBoxes[i]
      if (box && box.active && root.sameWindow(box.window, window)) return box
    }
    return null
  }

  // Where a drop lands in the box, in scene coordinates. During a drag it
  // takes in any room the box has opened for the dragged widget, so a drop
  // that lands in the box keeps landing there until the pointer leaves that
  // room, and it reaches the bar's thickness at least, so an empty box,
  // which takes no room, can still be hit.
  function centerBoxDropRect(box: CenterBox): var {
    return BarModel.centerBoxDropRect(box, root.vertical)
  }

  function debugBarGeometry(): var {
    return BarModel.debugBarGeometry(moduleSlots)
  }

  // Attached properties resolve only in QML scope, so BarModel's helpers call
  // back into this function to read an item's QsWindow.
  function targetWindow(target: var): var {
    var item = target as Item
    return item && item.QsWindow ? item.QsWindow.window : null
  }

  function targetBelongsToWindow(target: var, window: var): bool {
    return !!target && !!window && targetWindow(target) === window
  }

  function slotWindow(slot: var): var {
    return BarModel.slotWindow(slot)
  }

  function sameScreen(left: var, right: var): bool {
    return BarModel.sameScreen(left, right)
  }

  function sameWindow(left: var, right: var): bool {
    return BarModel.sameWindow(left, right)
  }

  function targetTooltipHovered(target: var): bool {
    return BarModel.targetTooltipHovered(target)
  }

  function clearTooltip(): var {
    tooltipTimer.stop()
    if (tooltipShown) tooltipWarmTimer.restart()
    pendingTooltipTarget = null
    pendingTooltipText = ""
    tooltipTarget = null
    tooltipText = ""
    tooltipShown = false
  }

  function clearBarDrag(): var {
    barDragSource = null
    barDragWindow = null
    barDragScreen = null
    barDragImageUrl = ""
    barDragTarget = null
    barDragRoom = null
    barDragExtent = 0
    barDragKeys = ""
    barDragRemoveArmed = false
    barDragRegrab.stop()
    barSettle = null
    barSettleAnimation.stop()
    // The room closes at once: a drop now fills it, and anything else is
    // already back in place.
    barDragShares = {}
    barDragHome = ""
    roomFader.stop()
    barDragSceneX = 0
    barDragSceneY = 0
    barDragScreenX = 0
    barDragScreenY = 0
    barDragOffsetX = 0
    barDragOffsetY = 0
  }

  function windowScreenPoint(scenePoint: var, window: var): var {
    return BarModel.windowScreenPoint(scenePoint, window, root.position)
  }

  function barDragScreenPoint(scenePoint: var): var {
    return windowScreenPoint(scenePoint, barDragWindow)
  }

  // Split the screen along its diagonals (in normalized space, so widescreens
  // don't bias toward left/right): whichever triangle holds the cursor names
  // the candidate edge.
  function nearestScreenEdge(point: var, screen: var): string {
    return BarModel.nearestScreenEdge(point, screen)
  }

  function beginBarMove(window: var): void {
    BarModel.beginBarMove(root, window)
  }

  function updateBarMove(screenPoint: var): var {
    if (!barMoveActive || !barMoveScreen) return
    barMoveCandidate = nearestScreenEdge(screenPoint, barMoveScreen)
  }

  function clearBarMove(): var {
    barMoveActive = false
    barMoveCandidate = ""
    barMoveWindow = null
    barMoveScreen = null
  }

  function finishBarMove(): var {
    var edge = barMoveCandidate
    if (!barMoveActive || !edge || edge === position) {
      clearBarMove()
      return
    }

    clearBarMove()
    setBarPosition(edge)
  }

  function setBarPosition(value: var): void {
    var next = normalizePosition(value)
    if (!BarModel.setShellBarPosition(root.shell, next)) root.position = next
  }

  // A copy of the widget for its ghost and its room to show. A widget that
  // changes size mid-drag is copied again, keeping the last copy until then.
  function captureBarDragGhost(slot: var): var {
    var item = slot && slot.activeItem ? slot.activeItem : null
    if (!item || typeof item.grabToImage !== "function") return

    var grabWidth = Math.max(1, Math.ceil(slot.widgetWidth))
    var grabHeight = Math.max(1, Math.ceil(slot.widgetHeight))
    item.grabToImage(function(result: var): void {
      var url = BarModel.grabbedImageUrl(result)
      if (root.barDragSource !== slot || !url) return
      root.barDragImageUrl = url
    }, Qt.size(grabWidth, grabHeight))
  }

  function requestPopout(owner: var): void {
    if (activePopout === owner) return
    if (activePopout) {
      if ("closeForPopoutSwitch" in activePopout) activePopout.closeForPopoutSwitch()
      else if ("close" in activePopout) activePopout.close()
    }
    activePopout = owner
  }

  function releasePopout(owner: var): void {
    if (activePopout === owner) activePopout = null
  }

  readonly property bool vertical: position === "left" || position === "right"
  readonly property int barSize: vertical ? Style.bar.sizeVertical : Style.bar.sizeHorizontal

  // Display cutouts (a camera notch) the platform's own package describes in
  // the fixed platform root, which no environment variable moves. Most machines
  // have none. It is read as the shell starts (blockLoading), so a bar surface
  // knows before it maps whether its screen may have one. See
  // BarModel.parseCutouts.
  // Read synchronously at startup (the FileView blocks loading, so the bar
  // knows before it maps whether its screen may have a cutout), then kept
  // current by its load handlers below. Binding this to the missing flag
  // the handlers write — as it was — loops on every shell start.
  property var displayCutouts: BarModel.parseCutouts(displayCutoutsFile.text())
  FileView {
    id: displayCutoutsFile

    // A file that went away describes nothing, whatever text() still holds.
    property bool missing: false

    path: "/usr/share/nomarchy-platform/display-cutouts.json"
    blockLoading: true
    watchChanges: true
    printErrors: false
    onLoaded: {
      missing = false
      root.displayCutouts = BarModel.parseCutouts(text())
    }
    onLoadFailed: {
      missing = true
      root.displayCutouts = []
    }
    onFileChanged: reload()
  }

  // The physical mode Hyprland reports for a screen, as hyprctl monitors does.
  // Qt's whole-number devicePixelRatio can't rebuild it at a fractional scale.
  function panelModeFor(screen: var): var {
    var monitor = screen ? Hyprland.monitorFor(screen) : null
    return monitor ? ({
      width: monitor.width,
      height: monitor.height,
      transform: monitor.lastIpcObject ? monitor.lastIpcObject.transform : 0
    }) : null
  }

  // How thick the bar is on a screen. A top bar shorter than a panel's camera
  // cutout leaves a sliver of every window peeking out beside the camera, so
  // the cutout is this panel's minimum sensible top-bar height. An
  // intentionally taller bar still wins.
  function thicknessFor(screen: var): real {
    return BarModel.thicknessFor(root, screen, Style.bar.notchHeight)
  }

  // Each screen's bar thickness, by screen name: barSize, or more where a notch
  // floor raises a top bar. Toasts and plugins clear the bar by it; barSize
  // stays the configured size the widgets are drawn at.
  readonly property var screenBarSizes: {
    var sizes = ({})
    var screens = Quickshell.screens
    for (let i = 0; i < screens.length; i++) sizes[screens[i].name] = root.thicknessFor(screens[i])
    return sizes
  }

  function barSizeFor(screenName: var): real {
    return BarModel.barSizeFor(root.screenBarSizes, screenName, root.barSize)
  }

  function normalizePosition(value: var): string {
    return BarModel.normalizePosition(value)
  }

  // The shared layout normalization, so the bar host and scriptable config
  // helpers can't drift on entry shape.
  function normalizeLayout(layout: var): var {
    return BarModel.normalizeLayout(layout, fallbackBarConfig, Util)
  }

  function applyBarConfig(): void {
    var config = BarModel.configObject(barConfig, fallbackBarConfig)

    position = normalizePosition(BarModel.configPosition(config))
    // opaque, glassy or none; a config from before background says
    // transparent instead.
    var look = BarModel.configBackground(config)
    setRequestedTransparency(look === "none")
    // A bar going clear waits for its text color before dropping its
    // background, so a glassy one stays glassy until then rather than
    // flashing opaque. Once clear, transparent wins over a stale glassy.
    if (look !== "none") glassy = look === "glassy"
    if (look !== glassSyncedLook) {
      glassSyncedLook = look
      Util.execDetached("nomarchy-bar sync-glass")
    }

    // Each widget keeps its key while it stays in the layout, wherever it
    // moves and whatever its settings, so a config write builds just the
    // widgets it adds (layoutWidgets).
    layoutConfig = normalizeLayout(BarModel.configLayout(config))
    barConfigSerial++
  }

  // Every widget on the bar, each under a key it keeps wherever it moves
  // (BarModel.layoutWidgets): the keys each section shows, in order, and each
  // key's entry. Every bar surface keeps one widget per key in its pool and
  // hands it to the slot of whichever section shows it (WidgetPool).
  property var widgetMemo: ({})
  readonly property var layoutWidgets: BarModel.layoutWidgets(layoutConfig, widgetMemo)
  readonly property var layoutSections: BarModel.layoutSections(layoutWidgets)

  readonly property var leftLayoutKeys: BarModel.layoutSection(BarModel.layoutSections(layoutWidgets), "left")
  readonly property var rightLayoutKeys: BarModel.layoutSection(BarModel.layoutSections(layoutWidgets), "right")
  readonly property var centerBeginLayoutKeys: BarModel.layoutSection(BarModel.layoutSections(layoutWidgets), "centerBegin")
  readonly property var centerEndLayoutKeys: BarModel.layoutSection(BarModel.layoutSections(layoutWidgets), "centerEnd")
  readonly property var centerLayoutKeys: BarModel.layoutSection(BarModel.layoutSections(layoutWidgets), "center")
  readonly property var trayLayoutKeys: BarModel.layoutSection(BarModel.layoutSections(layoutWidgets), "tray")

  onBarConfigChanged: applyBarConfig()

  function layoutEntries(region: var): var {
    var serial = barConfigSerial
    var entries = layoutConfig ? layoutConfig[region] : null
    return Array.isArray(entries) ? entries : []
  }

  // Tab order for the panels in one bar region, with the three center
  // sections taken as one. Scoped to a single bar surface so tabbing walks the
  // bar the open panel belongs to instead of hopping the panel to another
  // monitor's copy of the same widget.
  function panelNavigationSlots(region: var, window: var): var {
    return BarModel.panelNavigationSlots(root, region, window)
  }

  // The Nth panel in a bar region, counted the way the bar reads: layout order,
  // and only the panels actually on screen. A widget with no panel (the tray)
  // and one that is hiding itself are passed over, so the number lands on the
  // Nth panel icon the user can see rather than the Nth layout entry.
  // One-based, because it exists for hotkeys; anything else lands on no slot.
  //
  // Counting any bar surface is enough: every monitor lays its bar out from the
  // one layout, and summoning the id routes through pickPanelSlot, which opens
  // the focused monitor's copy whichever surface was counted.
  function panelWidgetIdAt(region: var, index: var): string {
    var slots = panelNavigationSlots(String(region || ""), null)
    var slot = slots[Math.round(Number(index)) - 1]
    return slot ? String(slot.moduleName || "") : ""
  }

  function switchPanelFrom(owner: var, direction: var): bool {
    return BarModel.switchPanelFrom(root, owner, direction)
  }

  // Every live instance of a widget id. A bar surface is built per monitor, so
  // a widget that appears once in the layout is still live once per screen.
  function moduleWidgets(pluginId: var): var {
    var id = String(pluginId || "")
    var items = []
    if (!id) return items
    for (let i = 0; i < widgetHosts.length; i++) {
      let host = widgetHosts[i]
      if (!host || !host.activeItem || host.moduleName !== id) continue
      items.push(host.activeItem)
    }
    return items
  }

  function slotScreenName(slot: var): string {
    return BarModel.slotScreenName(slot)
  }

  // The output Hyprland has focused, which is where a keyboard-summoned panel
  // belongs. Empty until Hyprland reports one, which leaves panel routing on
  // its per-monitor fallback rather than guessing at an output.
  function focusedScreenName(): string {
    var monitor = Hyprland.focusedMonitor as HyprlandMonitor
    return monitor ? String(monitor.name || "") : ""
  }

  // Resolve the live bar-widget instance for a plugin id (e.g. "nomarchy.bluetooth").
  // Only widgets that expose popup open/close methods count; plain indicators
  // (clock, workspaces, tray) return null. Used by shell.summon/toggle so
  // panel hotkeys route through the bar instead of a per-target IPC handler
  // that only reaches whichever per-monitor instance claimed the target.
  function findPanelWidget(pluginId: var): var {
    return BarModel.findPanelWidget(root, pluginId)
  }

  function summonBarWidget(pluginId: var): bool {
    return BarModel.panelAction(root, pluginId, "open")
  }

  function hideBarWidget(pluginId: var): bool {
    return BarModel.panelAction(root, pluginId, "close")
  }

  function isBarWidgetOpen(pluginId: var): bool {
    return BarModel.panelAction(root, pluginId, "isOpen")
  }

  function entrySettings(entry: var): var {
    return BarModel.entrySettings(entry)
  }

  function entryId(entry: var): var {
    return BarModel.entryId(entry)
  }

  function moduleString(entry: var, key: var, fallback: var): var {
    return BarModel.moduleString(entry, key, fallback)
  }

  function canonicalWidgetId(name: var): string {
    return Util.canonicalWidgetId(name)
  }

  function expandPath(path: var): string {
    return BarModel.expandPath(path, home)
  }

  function customModuleSafeName(name: var): bool {
    return BarModel.customModuleSafeName(name)
  }

  function customModuleType(entry: var): var {
    return BarModel.customModuleType(entry)
  }

  function customModuleSource(entry: var): var {
    var source = BarModel.customModulePath(entry, home, nomarchyConfigDir)
    return source ? Util.fileUrl(source) : ""
  }

  Component.onCompleted: {
    BarModel.setWindowResolver(root.targetWindow)
    applyBarConfig()
  }

  // The indicator peek opens as the pointer comes onto the bar and holds until
  // it leaves, or crosses onto the clock at the start of the center box
  // (BarModel.peeksAt). Revealing the indicators widens their section, which
  // can slide a widget under a stationary pointer, so nothing narrower than the
  // stretch of bar up to that edge, held still while the peek is open
  // (BarModel.nextPeekEdge), can hold it without opening and closing it in a
  // loop.
  function setBarHovered(hovered: var): void {
    barHoverCount = Math.max(0, barHoverCount + (hovered ? 1 : -1))
    if (barHoverCount > 0) {
      centerSectionRevealTimer.stop()
      centerSectionRevealHeld = true
    } else {
      centerSectionRevealTimer.restart()
    }
  }

  function setCenterHoverRevealSuppressed(value: var): void {
    centerHoverRevealSuppressed = !!value
  }

  Timer {
    id: centerSectionRevealTimer
    interval: 120
    // A pointer that dips off the bar and straight back leaves the peek open.
    onTriggered: if (!root.barHovered) root.centerSectionRevealHeld = false
  }

  function run(command: var): void {
    if (!command) return

    Util.execDetached(command)
  }

  // Steps the bar background from clear to glassy to opaque and around. Through
  // nomarchy-bar, which keeps Hyprland's blur behind a glassy bar in step.
  function cycleBackground(): var {
    Util.execDetached("nomarchy-bar background cycle")
  }

  function moduleDropAtScene(scenePoint: var, sourceSlot: var): var {
    var sourceWindow = root.slotWindow(sourceSlot) || root.barDragWindow
    // A drop lands only over the bar strip. The window spans its whole
    // screen, so its own bounds are not the bar's.
    if (moduleRemoveDistance(windowScreenPoint(scenePoint, sourceWindow)) > 0) return null

    // The tray cannot go into its own drawer.
    var intoTraySection = !BarModel.moduleHostsTraySection(sourceSlot)
    var traySlot = null
    // Each widget's own room; spacers are not widgets. The dragged widget
    // counts too: over its own room it would land back there, and folded
    // away, it still answers at the point it left, which the section's layout
    // keeps placing.
    var candidates = []
    for (let i = 0; i < moduleSlots.length; i++) {
      let slot = moduleSlots[i]
      if (!slot || !slot.visible || slot.widgetWidth <= 0 || slot.widgetHeight <= 0) continue
      if (sourceWindow && !root.sameWindow(root.slotWindow(slot), sourceWindow)) continue
      if (slot.region === "tray" && !intoTraySection) continue
      if (intoTraySection && BarModel.moduleHostsTraySection(slot)) traySlot = slot

      let slotPoint = { x: slot.x, y: slot.y }
      slotPoint = BarModel.mapToItemSafely(slot, 0, 0) || slotPoint

      candidates.push({
        slot: slot,
        region: slot.region,
        x: slotPoint.x,
        y: slotPoint.y,
        width: slot.width,
        height: slot.height
      })
    }

    // The tray's drawer section works as the center box does: over it, a
    // drop lands among the widgets in it, or in it, and off it they are out
    // of reach.
    var drawer = BarModel.traySectionDropTarget(candidates, root.traySectionDropRect(traySlot, sourceWindow), scenePoint, root.vertical, sourceSlot)
    if (drawer) return drawer
    var onBar = BarModel.dropNonTrayCandidates(candidates)
    var box = sourceWindow ? root.centerBoxFor(sourceWindow) : null
    return BarModel.centerDropTarget(onBar, root.centerBoxDropRect(box), scenePoint, root.vertical, sourceSlot)
  }

  // Where a drop lands in the tray's drawer section on a bar surface, in
  // scene coordinates: the section, any room a drag has opened there
  // included, reaching past it by half the bar's thickness either way, short
  // of the tray's own ends (BarModel.sectionDropZone).
  function traySectionDropRect(slot: ModuleSlot, window: PanelWindow): var {
    return BarModel.traySectionDropRectForSlot(slot, window, root, vertical)
  }

  // Lifts a widget off the bar by the point it was pressed at. Its room is the
  // length the section's layout gives it, which is whole pixels. Its panel
  // closes: placed when it opened, it wouldn't follow the widget anywhere.
  function beginBarDrag(sourceSlot: ModuleSlot, pressX: real, pressY: real): void {
    BarModel.beginBarDrag(root, sourceSlot, pressX, pressY)
  }

  // A dragged widget that changes size, as a clock ticking over or the
  // indicator peek does, takes its room and its ghost with it. The ghost's
  // copy of it is taken again once the size settles, rather than on every
  // frame of a widget animating its size.
  function resizeBarDrag(): var {
    var slot = barDragSource
    if (!slot) return
    var extent = Math.ceil(vertical ? slot.widgetHeight : slot.widgetWidth)
    if (extent === barDragExtent) return
    barDragExtent = extent
    barDragRegrab.restart()
  }

  Timer {
    id: barDragRegrab
    interval: 120
    onTriggered: root.captureBarDragGhost(root.barDragSource)
  }

  Connections {
    target: root.barDragSource
    function onWidgetWidthChanged(): var { root.resizeBarDrag() }
    function onWidgetHeightChanged(): var { root.resizeBarDrag() }
  }

  // The room opens where the dragged widget is, which keeps all of it until
  // the room moves away.
  function startDragRoom(sourceSlot: ModuleSlot): void {
    BarModel.startDragRoom(root, sourceSlot)
  }

  // Moves the room for the dragged widget to where a drop would land. The
  // place it leaves hands its room over to the new one (fadeDragRoom).
  function moveDragRoom(drop: var): void {
    if (!BarModel.moveDragRoom(root, drop)) return
    fadeDragRoom(0)
    roomFader.start()
  }

  // The keys of the widgets a bar surface draws, as they are now.
  function drawnKeys(window: var): var {
    return BarModel.drawnKeys(moduleSlots, window)
  }

  function dragShareKey(room: var): string {
    return BarModel.dragShareKey(room)
  }

  // A frame of the room moving, at an even pace: a place hands over the
  // whole room in 120ms.
  // Armed for removal, there is no target: every place gives its room up.
  function fadeDragRoom(seconds: var): var {
    var duration = Style.duration(120)
    var step = duration > 0 ? seconds * 1000 / duration : 1
    var target = barDragRemoveArmed ? "" : dragShareKey(barDragRoom)
    barDragShares = BarModel.fadeShares(barDragShares, target, step)
    if (target ? barDragShares[target] >= 1 : Object.keys(barDragShares).length === 0) roomFader.stop()
  }

  FrameAnimation {
    id: roomFader
    onTriggered: root.fadeDragRoom(frameTime)
  }

  // Where a section's list on a bar surface opens room for the dragged
  // widget, while it is dragged on that surface: each place holding some of
  // the room but the dragged widget's own, which keeps its room in its slot.
  function sectionSpacers(region: var, window: var): var {
    if (!barDragSource || !barDragPlaces || !window || !sameWindow(barDragWindow, window)) return []
    var places = []
    var held = barDragPlaces.split(",")
    for (let i = 0; i < held.length; i++) {
      let split = held[i].lastIndexOf(":")
      if (held[i] !== barDragHome && held[i].slice(0, split) === region) places.push(Number(held[i].slice(split + 1)))
    }
    return places
  }

  function registerDragSpacer(spacer: var): var {
    dragSpacers = Array.from(dragSpacers).concat([spacer])
  }

  function unregisterDragSpacer(spacer: var): var {
    dragSpacers = dragSpacers.filter(function(item: var): var { return item !== spacer })
  }

  // Where a released widget lands: the room its drop opened, or its own room
  // when it goes back where it was.
  function dropLandingItem(sourceSlot: ModuleSlot, room: var): var {
    return BarModel.dropLandingItem(root, sourceSlot, room)
  }

  // Where letting go of the dragged widget now would move its entry
  // (BarModel.moveEntry): to before the widget the room is before, or the end
  // of the section. Null when it would go back where it was.
  function dragMove(): var {
    return BarModel.dragMove(barDragRoom, barDragSource, layoutSections, barDragKeys)
  }

  // Lets go of a dragged widget: its ghost glides from the pointer into where
  // it lands, and the move is written once it gets there, so the widget takes
  // its place from where it was let go rather than sliding in from the side.
  function settleBarDrag(sourceSlot: var): var {
    var move = dragMove()
    if (Style.duration(180) === 0) {
      landBarDrag(move)
      return
    }
    barSettle = { source: sourceSlot, move: move, room: move ? barDragRoom : null, fromX: barDragScreenX, fromY: barDragScreenY }
    barSettleProgress = 0
    barSettleAnimation.restart()
  }

  // The ghost follows the landing as it moves, so it arrives where the room
  // ends up even while the room is still moving there. Until the room
  // reaches the landing place, which has no spacer yet, it holds still.
  onBarSettleProgressChanged: BarModel.updateBarSettle(root)

  NumberAnimation {
    id: barSettleAnimation
    target: root
    property: "barSettleProgress"
    from: 0
    to: 1
    duration: Style.duration(180)
    easing.type: Easing.OutCubic
    onFinished: root.finishBarSettle()
  }

  // Lands a settling widget now: when its ghost arrives, or when a new press
  // can't wait for it.
  function finishBarSettle(): void {
    BarModel.finishBarSettle(root)
  }

  // Writes where a dragged widget landed, unless widgets have moved about
  // since the drag started: a write from elsewhere that the drag hasn't let
  // go for yet (onLayoutWidgetsChanged) would put it in the wrong place. Every
  // widget keeps its own instance through the move, the dragged one too,
  // whatever else shares its id (BarModel.layoutWidgets).
  function landBarDrag(move: var): var {
    clearBarDrag()
    if (!move || JSON.stringify(layoutSections) !== move.keys) return
    var expected = JSON.parse(move.keys)
    var into = expected[move.to.region]
    var before = move.to.index >= 0 ? into[move.to.index] : null
    expected[move.from.region].splice(move.from.index, 1)
    into.splice(before ? into.indexOf(before) : into.length, 0, move.key)
    writeLayout(expected, function(config: var): var {
      BarModel.moveEntry(config, move, function(entry: var): var { return Util.normalizeLayoutEntry(entry) })
    })
  }

  // Writes a layout edit to shell.json. Widgets keep their instances through
  // the write as long as the sections come out as `expected`.
  function writeLayout(expected: var, edit: var): void {
    BarModel.writeLayout(root.shell, widgetMemo, expected, edit)
  }

  // How far past the bar the drag point sits, in screen coordinates: past
  // the strip its screen's bar surface draws, thickness deep along its edge.
  // The strip, not the window, is the boundary: the window spans the whole
  // screen (BarPanel).
  function moduleRemoveDistance(screenPoint: var): real {
    if (!barDragScreen) return 0
    return BarModel.moduleRemoveDistance(screenPoint, barDragScreen, thicknessFor(barDragScreen), vertical, position)
  }

  // Arming closes the dragged widget's room, and disarming opens it again
  // where a drop would land, as a move of the room does (moveDragRoom).
  function setBarDragRemoveArmed(armed: bool): void {
    if (barDragRemoveArmed === armed) return
    barDragRemoveArmed = armed
    fadeDragRoom(0)
    roomFader.start()
  }

  // Lets go of a widget pulled off the bar. It vanishes in a poof where it
  // was let go, its slot closing at once (ModuleSlot.removalPending), and
  // its entry leaves the layout once the poof has played.
  function removeBarDrag(sourceSlot: ModuleSlot): void {
    BarModel.removeBarDrag(root, sourceSlot)
  }

  // Writes a removed widget out of the layout. Every other widget keeps its
  // instance through the write (BarModel.layoutWidgets), as with a move.
  function commitBarRemoval(): void {
    BarModel.commitBarRemoval(root, Util)
  }

  // Bursts out of the ghost where it was let go, so it runs before
  // clearBarDrag wipes the drag. With motion reduced there is nothing to play.
  function playPoof(): var {
    if (Style.duration(620) === 0) return
    barPoof = {
      screen: barDragScreen,
      x: barDragScreenX - barDragOffsetX + barDragGhostWidth / 2,
      y: barDragScreenY - barDragOffsetY + barDragGhostHeight / 2,
      width: barDragGhostWidth,
      height: barDragGhostHeight,
      image: barDragImageUrl,
      seed: Math.random()
    }
    poofTimer.restart()
  }

  // Outlives the poof's animation a little so its last frames aren't cut
  // off by the ghost's surface unmapping, and only then writes the removal:
  // persisting shell.json stalls the render loop for long enough to swallow
  // a poof still playing.
  Timer {
    id: poofTimer
    interval: Style.duration(620)
    onTriggered: {
      root.barPoof = null
      root.commitBarRemoval()
    }
  }

  function isPendingRemoval(key: var): bool {
    return BarModel.isPendingRemoval(barRemoval, key)
  }

  function moduleTargetClickable(target: var): bool {
    return BarModel.moduleTargetClickable(target)
  }

  function moduleClickTargetAt(slot: var, localX: var, localY: var): var {
    return BarModel.moduleClickTargetAt(clickTargets, slot, localX, localY, Util)
  }

  function pressModuleClickTarget(slot: var, button: var, localX: var, localY: var): var {
    var target = moduleClickTargetAt(slot, localX, localY)
    if (!target) return false

    target.triggerPress(button)
    return true
  }

  function colorHex(colorValue: color): string {
    return BarModel.colorHex(colorValue)
  }

  function setRequestedTransparency(value: var): void {
    var nextTransparent = value === true
    requestedTransparent = nextTransparent
    if (!nextTransparent) {
      foregroundAnimationEnabled = false
      useTransparentForeground = false
      transparent = false
      transparentForeground = themeForeground
      restoreForegroundAnimation()
      return
    }
    scheduleTransparentForegroundRefresh()
  }

  function restoreForegroundAnimation(): var {
    Qt.callLater(function(): var {
      Qt.callLater(function(): var { root.foregroundAnimationEnabled = true })
    })
  }

  function scheduleTransparentForegroundRefresh(): var {
    if (!requestedTransparent) {
      transparentForeground = themeForeground
      return
    }
    transparentForegroundTimer.restart()
  }

  function refreshTransparentForeground(): var {
    if (!requestedTransparent || transparentForegroundProc.running) return

    transparentForegroundProc.command = [
      "nomarchy-bar-text-color",
      root.position,
      String(root.barSize),
      colorHex(root.themeForeground),
      colorHex(root.themeContrastForeground)
    ]
    transparentForegroundProc.running = true
  }

  onRequestedTransparentChanged: scheduleTransparentForegroundRefresh()
  onPositionChanged: scheduleTransparentForegroundRefresh()
  onThemeForegroundChanged: scheduleTransparentForegroundRefresh()
  onThemeContrastForegroundChanged: scheduleTransparentForegroundRefresh()

  Timer {
    id: transparentForegroundTimer
    interval: 120
    repeat: false
    onTriggered: root.refreshTransparentForeground()
  }

  Process {
    id: transparentForegroundProc
    stdout: SplitParser {
      onRead: function(line: string): var {
        var value = String(line || "").trim()
        if (!/^#[0-9A-Fa-f]{6}$/.test(value)) return

        root.foregroundAnimationEnabled = false
        root.transparentForeground = value
        if (root.requestedTransparent) {
          root.useTransparentForeground = true
          root.transparent = true
        }
        root.restoreForegroundAnimation()
      }
    }
  }

  // FileView also fires for any change in its path's parent directory, so watch
  // a path inside current/: every plugin writes to ~/.local/state/nomarchy.
  FileView {
    path: root.stateHome + "/nomarchy/current/theme"
    watchChanges: true
    printErrors: false
    onFileChanged: root.scheduleTransparentForegroundRefresh()
  }

  function runProcess(process: Process): void {
    if (!process.running) process.running = true
  }

  function showTooltip(target: var, text: var): void {
    BarModel.showTooltip(root, target, text, Qt.callLater)
  }

  function hideTooltip(target: var): var {
    if (tooltipTarget !== target && pendingTooltipTarget !== target) return

    tooltipRequest += 1
    clearTooltip()
  }

  Timer {
    id: tooltipTimer
    interval: 400
    onTriggered: {
      if (root.targetTooltipHovered(root.tooltipTarget)) root.tooltipShown = true
      else root.clearTooltip()
    }
  }

  // How long after a tooltip hides the next one still skips the delay. Long
  // enough to cross the gap between two icons, short enough that coming back
  // to the bar later waits again.
  Timer {
    id: tooltipWarmTimer
    interval: 400
  }

  Timer {
    interval: 100
    running: root.tooltipShown
    repeat: true
    onTriggered: if (!root.targetTooltipHovered(root.tooltipTarget)) root.hideTooltip(root.tooltipTarget)
  }

  // Presence of the `bar-off` flag = bar hidden. Watching the parent toggles
  // directory because FileView can't observe a file that doesn't exist yet,
  // and the flag is created/removed by `nomarchy-toggle-bar`.
  Process {
    id: barHiddenProbe
    running: true
    command: ["C:/Program Files/Git/usr/bin/bash.exe", "-c", "[[ -f $HOME/.local/state/nomarchy/toggles/bar-off ]] && echo yes || echo no"]
    stdout: SplitParser { onRead: function(line: string): var { root.barHidden = String(line).trim() === "yes" } }
  }
  FileView {
    path: root.home + "/.local/state/nomarchy/toggles"
    watchChanges: true
    printErrors: false
    onFileChanged: barHiddenProbe.running = true
  }

  // The directory watch can permanently stop delivering events after flag
  // changes land in quick succession, stranding the bar off screen until the
  // shell restarts. `nomarchy-toggle-bar` nudges this after flipping the flag
  // so the probe re-reads it even when the watch has gone quiet.
  Commons.ShellIpc {
    target: "nomarchy.bar"

    // Start rather than restart: a probe already in flight was launched by the
    // directory watch after the flag flipped, so its answer is current, and
    // killing it here can swallow the result entirely.
    function syncHidden(): void {
      barHiddenProbe.running = true
    }
  }

  // Hyprland's window list does not follow fullscreen on its own, and each
  // BarPanel reads it to drop its input under a fullscreen window.
  Connections {
    target: Hyprland
    function onRawEvent(event: var): void {
      if (BarModel.isFullscreenEvent(event)) Hyprland.refreshToplevels()
    }
  }

  Variants {
    model: Quickshell.screens

    delegate: Component {
      BarPanel {
        required property var modelData

        screen: modelData
      }
    }
  }

  Variants {
    model: Quickshell.screens

    delegate: Component {
      DragGhostPanel {
        required property var modelData

        screen: modelData
        ghostScreen: modelData
      }
    }
  }

  Variants {
    model: Quickshell.screens

    delegate: Component {
      BarMoveGhostPanel {
        required property var modelData

        screen: modelData
        ghostScreen: modelData
      }
    }
  }

  component BarPanel: PanelWindow {
    id: barWindow

    // Hiding parks the bar just past its screen edge instead of unmapping it.
    // Unmapping frees the layer surface and the whole scene graph, so every
    // reveal has to rebuild them — new surface, re-shaped glyphs, re-uploaded
    // textures — which measures ~150ms against ~20ms to tear down. Parking
    // keeps the surface alive, so showing is only a margin change.
    //
    // A top bar that can't tell its notch floor yet waits for Hyprland's mode
    // before it maps (see BarModel.cutoutPending), so it maps at its floor
    // instead of growing once the windows are laid out. The wait ends once, for
    // good: when the mode settles it, or after two seconds without one.
    visible: cutoutWaitOver || !cutoutPending
    // An explicit zone instead of Auto: the reserved area stays the strip's
    // thickness though the window spans its screen.
    exclusionMode: root.barHidden ? ExclusionMode.Ignore : ExclusionMode.Normal
    exclusiveZone: thickness

    // While this window's widget or bar-move drag is live, the whole surface
    // takes input (mask below), so the pointer never leaves the bar surface
    // however far the drag goes. That is what keeps the gesture alive: while
    // nothing on the workspace holds keyboard focus (an empty workspace),
    // Hyprland picks a pointer target again on a surface commit, and a
    // pointer that has strayed onto another surface is pulled off the bar
    // mid-drag, ending the gesture with a synthesized release.
    // sameWindow, not identity: the drag records the QsWindow interface of
    // the slot's window, which is not this PanelWindow object itself.
    readonly property bool dragActive: (root.barDragSource !== null && root.sameWindow(root.barDragWindow, barWindow)) ||
      (root.barMoveActive && root.sameWindow(root.barMoveWindow, barWindow))

    // Parked by the whole surface, which spans its screen, so none of it
    // stays on screen: not the strip, however thick a notch floor makes it,
    // nor the clear rest that a drag takes input on.
    readonly property real parkDistance: root.vertical ? implicitWidth : implicitHeight
    margins {
      top: root.barHidden && root.position === "top" ? -barWindow.parkDistance : 0
      bottom: root.barHidden && root.position === "bottom" ? -barWindow.parkDistance : 0
      left: root.barHidden && root.position === "left" ? -barWindow.parkDistance : 0
      right: root.barHidden && root.position === "right" ? -barWindow.parkDistance : 0
    }

    anchors {
      top: root.position === "top" || root.vertical
      bottom: root.position === "bottom" || root.vertical
      left: root.position === "left" || !root.vertical
      right: root.position === "right" || !root.vertical
    }

    readonly property var panelMode: root.panelModeFor(screen)

    readonly property bool centerBesideRight: BarModel.centerBesideRight(root.displayCutouts, root.position, screen.name, screen.width, screen.height, screen.devicePixelRatio, panelMode)

    readonly property bool cutoutPending: BarModel.cutoutPending(root.displayCutouts, root.position, screen.name, screen.width, screen.height, screen.devicePixelRatio, panelMode)
    property bool cutoutWaitOver: false
    onCutoutPendingChanged: if (!cutoutPending) cutoutWaitOver = true
    Component.onCompleted: if (!cutoutPending) cutoutWaitOver = true

    Timer {
      interval: 2000
      running: barWindow.cutoutPending && !barWindow.cutoutWaitOver
      onTriggered: barWindow.cutoutWaitOver = true
    }

    // The same thickness the bar publishes for its screen (screenBarSizes).
    readonly property int thickness: root.thicknessFor(screen)
    // Where the center box starts along the bar, set by the drawn center
    // sections. Hovering past it, over the clock, its trailing widgets and the
    // right section, leaves the indicator peek shut.
    property real peekEdge: 0

    // The surface spans its screen at all times, transparent past the strip
    // it paints; a drag toggles only its input region. Growing the surface
    // for a drag instead flashes the strip's stale buffer stretched across
    // the new size until the next frame lands, and the size can't come from
    // anchoring all four edges either, which would void the exclusive zone
    // (layer-shell reserves space from the one anchored edge) and drop tiled
    // windows behind the bar. Glassy blur stays on the strip: Hyprland's
    // ignore_alpha leaves the clear rest of the surface unblurred.
    implicitWidth: root.vertical ? (screen ? screen.width : thickness) : 0
    implicitHeight: root.vertical ? 0 : (screen ? screen.height : thickness)
    color: "transparent"
    surfaceFormat.opaque: false
    WlrLayershell.namespace: "nomarchy-bar"
    WlrLayershell.layer: WlrLayer.Top

    // Whether the active workspace on this screen holds a real fullscreen
    // window, which fades the bar out.
    readonly property bool underFullscreen: {
      var monitor = Hyprland.monitorFor(screen)
      var workspace = monitor ? monitor.activeWorkspace : null
      return !!workspace && BarModel.fullscreenOn(Hyprland.toplevels.values, workspace.id)
    }

    // Idle, only the strip takes input, so the clear expanse passes clicks
    // through to the windows and desktop below. Under a fullscreen window
    // nothing does: Hyprland 0.56 passes the pointer through a faded top
    // layer only while it holds the layer below fullscreen, and it lifts
    // every layer on the monitor back above whenever a window on any other
    // workspace leaves fullscreen, or the layer remaps. The invisible strip
    // would then take the clicks meant for the top of the fullscreen window.
    mask: dragActive ? null : (underFullscreen ? noInputRegion : stripInputRegion)

    Region {
      id: stripInputRegion
      item: barStrip
    }

    Region {
      id: noInputRegion
    }

    // The bar itself, along its screen edge.
    Item {
      id: barStrip

      x: root.position === "right" ? parent.width - barWindow.thickness : 0
      y: root.position === "bottom" ? parent.height - barWindow.thickness : 0
      width: root.vertical ? barWindow.thickness : parent.width
      height: root.vertical ? parent.height : barWindow.thickness

      Rectangle {
        anchors.fill: parent
        color: root.transparent ? "transparent" : (root.glassy ? root.glassBackground : root.background)
      }

      Loader {
        anchors.fill: parent
        sourceComponent: root.vertical ? verticalBar : horizontalBar

        // A child of the loader, not a sibling of the sections: an ancestor stays
        // hovered while the pointer is over a widget, where a sibling would lose
        // hover to the section the pointer entered.
        HoverHandler {
          readonly property bool peeking: hovered && BarModel.peeksAt(point.position, barWindow.peekEdge, root.vertical)
          onPeekingChanged: root.setBarHovered(peeking)
          // Unplugging a monitor destroys its bar without a leave event, which
          // would strand this surface's tally and hold the peek open for good.
          Component.onDestruction: if (peeking) root.setBarHovered(false)
        }
      }
    }

    PopupWindow {
      id: tooltipWindow

      visible: root.tooltipShown && root.tooltipTarget !== null && root.tooltipText !== "" && root.targetBelongsToWindow(root.tooltipTarget, barWindow)
      color: "transparent"
      implicitWidth: Math.ceil(tooltipBubble.implicitWidth)
      implicitHeight: Math.ceil(tooltipBubble.implicitHeight)
      // The base sizes from contentItem.childrenRect, which loops while the bubble resizes the window.
      contentWidth: implicitWidth
      contentHeight: implicitHeight

      // Each show maps a fresh surface at a whole-number scale before Qt receives
      // the output's fractional one. Keep the bubble transparent until it matches the bar.
      readonly property bool scaleReady: visible && Math.round(devicePixelRatio * 120) === Math.round(barWindow.devicePixelRatio * 120)
      property bool revealed: false

      // Only hiding resets it: at a whole-number scale the ratio dips to 1 after the first frame.
      onVisibleChanged: if (!visible) revealed = false
      onScaleReadyChanged: if (scaleReady) Qt.callLater(function(): var {
        if (tooltipWindow.scaleReady) tooltipWindow.revealed = true
      })


      anchor {
        item: root.tooltipTarget
      }

      BorderSurface {
        id: tooltipBubble
        opacity: tooltipWindow.revealed ? 1 : 0
        implicitWidth: tooltipLabel.implicitWidth + 20
        implicitHeight: tooltipLabel.implicitHeight + 14
        color: Commons.Color.tooltip.background
        borderSpec: Border.surfaceSpec("tooltip", "border", Commons.Color.tooltip.border, 1)
        radius: Style.cornerRadius

        Text {
          id: tooltipLabel
          textFormat: Text.PlainText
          anchors.centerIn: parent
          text: root.tooltipText
          color: Commons.Color.tooltip.text
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
        }
      }
    }

    Component {
      id: horizontalBar

      Item {
        anchors.fill: parent

        WidgetPool { id: horizontalPool }

        CenterModules {
          anchors.fill: parent
          window: barWindow
          pool: horizontalPool
          drawn: !barWindow.centerBesideRight
        }

        LeftModules {
          window: barWindow
          pool: horizontalPool
          anchors.left: parent.left
          anchors.leftMargin: Style.space(8)
          anchors.verticalCenter: parent.verticalCenter
        }

        RightModules {
          window: barWindow
          pool: horizontalPool
          id: rightModules
          anchors.right: parent.right
          anchors.rightMargin: Style.space(8)
          anchors.verticalCenter: parent.verticalCenter
        }

        // Where a display notch covers the middle of the bar, the center
        // sections run on just left of the right one. They keep their regions,
        // so settings pushes, drag and drop, and panel routing still address
        // them. The gap lets a drop at the seam land in the section the pointer
        // is nearer to.
        CenterSections {
          window: barWindow
          pool: horizontalPool
          active: barWindow.centerBesideRight
          besideRight: true
          anchors.right: rightModules.left
          anchors.rightMargin: Style.space(4)
          anchors.top: parent.top
          anchors.bottom: parent.bottom
        }
      }
    }

    Component {
      id: verticalBar

      Item {
        anchors.fill: parent

        WidgetPool { id: verticalPool }

        CenterModules {
          anchors.fill: parent
          window: barWindow
          pool: verticalPool
        }

        LeftModules {
          window: barWindow
          pool: verticalPool
          anchors.top: parent.top
          anchors.topMargin: Style.space(8)
          anchors.horizontalCenter: parent.horizontalCenter
        }

        RightModules {
          window: barWindow
          pool: verticalPool
          anchors.bottom: parent.bottom
          anchors.bottomMargin: Style.space(8)
          anchors.horizontalCenter: parent.horizontalCenter
        }
      }
    }
  }

  Component { id: emptyModuleComponent; Item { implicitWidth: 0; implicitHeight: 0; visible: false } }

  component DragGhostPanel: PanelWindow {
    id: ghostWindow

    required property var ghostScreen
    readonly property bool active: !!root.barDragSource && root.sameScreen(root.barDragScreen, ghostScreen)
    readonly property var sourceItem: BarModel.dragSourceItem(root.barDragSource)
    readonly property bool poofShown: BarModel.poofShown(root.barPoof, ghostScreen)

    visible: (active && sourceItem !== null) || poofShown
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "nomarchy-bar-drag-ghost"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }

    // Visual-only drag feedback. Keep the input region empty so the ghost can
    // sit under the cursor without stealing the MouseArea's active pointer grab.
    mask: Region {}

    // The widget at its size in the bar, outlined like the room it leaves
    // and the room it would land in (DragSpacer).
    Item {
      visible: ghostWindow.active && ghostWindow.sourceItem !== null
      x: Math.round(root.barDragScreenX - root.barDragOffsetX)
      y: Math.round(root.barDragScreenY - root.barDragOffsetY)
      width: root.barDragGhostWidth
      height: root.barDragGhostHeight
      // Pulled past the removal threshold, the ghost shrinks and dims: let
      // go now and the widget poofs away instead of moving.
      scale: root.barDragRemoveArmed ? 0.82 : 1
      opacity: root.barDragRemoveArmed ? 0.55 : 1

      Behavior on scale { NumberAnimation { duration: Style.duration(140); easing.type: Easing.OutCubic } }
      Behavior on opacity { NumberAnimation { duration: Style.duration(140); easing.type: Easing.OutCubic } }

      RoomOutline { opacity: root.transparent ? 0.45 : 0.94 }

      Image {
        anchors.fill: parent
        source: root.barDragImageUrl
        fillMode: Image.Stretch
        smooth: true
        opacity: 0.84
      }
    }

    // The puff of smoke a widget pulled off the bar vanishes in. Its ghost
    // pops, swelling as it fades, while a cloud billows out of the space it
    // filled and thins away, throwing off a few specks. The cloud takes the
    // widget's own footprint, so a wide widget leaves a wide cloud, and is
    // laid out afresh for each poof so no two look alike.
    Item {
      id: poof

      // 0 to 1 through the poof. Each part runs on its own stretch of it.
      property real progress: 1
      // The poof playing here, kept through its last frames.
      property var spec: ({ x: 0, y: 0, width: 0, height: 0, image: "", seed: 0 })

      readonly property real spanX: BarModel.poofSpanX(poof.spec, Style.spaceReal(16))
      readonly property real spanY: BarModel.poofSpanY(poof.spec, Style.spaceReal(16))
      readonly property real puffSize: BarModel.poofSize(poof.spec, Style.spaceReal(16), Style.spaceReal(34))
      // Room around the puffs at their furthest, so the blur isn't clipped.
      readonly property real margin: puffSize * 1.4 + Style.spaceReal(16)

      // A steady pseudo-random 0 to 1 for part n of this poof.
      function noise(n: var): var {
        return BarModel.poofNoise(n, poof.spec)
      }
      // How far along a part starting `from` and ending `to` is.
      function phase(from: var, to: var): var {
        return Util.clamp((progress - from) / (to - from), 0, 1)
      }
      function outCubic(t: var): var { return 1 - Math.pow(1 - t, 3) }
      function outBack(t: var): var { return 1 + 2.4 * Math.pow(t - 1, 3) + 1.4 * Math.pow(t - 1, 2) }

      visible: ghostWindow.poofShown
      x: BarModel.poofX(poof.spec)
      y: BarModel.poofY(poof.spec)

      Connections {
        target: root
        function onBarPoofChanged(): var {
          if (!BarModel.poofShown(root.barPoof, ghostWindow.ghostScreen)) return
          poof.spec = root.barPoof
          poofAnimation.restart()
        }
      }

      NumberAnimation {
        id: poofAnimation
        target: poof
        property: "progress"
        from: 0
        to: 1
        duration: Style.duration(560)
      }

      // The ghost, picking up as the drag left it.
      Image {
        readonly property real t: poof.outCubic(poof.phase(0, 0.3))

        width: BarModel.poofWidth(poof.spec)
        height: BarModel.poofHeight(poof.spec)
        x: -width / 2
        y: -height / 2
        source: BarModel.poofImage(poof.spec)
        fillMode: Image.Stretch
        smooth: true
        scale: 0.82 + 0.45 * t
        opacity: 0.84 * 0.55 * (1 - t)
      }

      // Overlapping puffs blurred into one soft cloud, ringed faintly in the
      // bar's background so it reads over light windows and dark alike.
      Item {
        id: cloud

        width: (poof.spanX + poof.margin) * 2
        height: (poof.spanY + poof.margin) * 2
        x: -width / 2
        y: -height / 2
        // Built with the ghost's surface rather than at the release, which
        // would cost the poof its first frames while the effect sets up.
        // Until the poof plays the cloud holds nothing to draw.
        layer.enabled: ghostWindow.visible
        layer.effect: MultiEffect {
          blurEnabled: true
          blur: 0.6
          blurMax: 20
          shadowEnabled: true
          shadowColor: root.background
          shadowBlur: 0.9
          shadowOpacity: 0.7
          shadowHorizontalOffset: 0
          shadowVerticalOffset: 0
        }

        Repeater {
          model: 14

          Rectangle {
            required property int index
            // The first sits in the middle; the rest ring it unevenly.
            readonly property real angle: Math.PI * 2 * (index + poof.noise(index) * 0.7) / 13
            readonly property real reach: index === 0 ? 0 : 0.3 + 0.7 * poof.noise(index + 20)
            readonly property real begin: index === 0 ? 0 : 0.1 * poof.noise(index + 40)
            readonly property real end: 0.82 + 0.18 * poof.noise(index + 60)
            readonly property real t: poof.phase(begin, end)
            // Billows out fast, overshooting a touch, then drifts, rises and
            // swells as it thins, the way smoke spreads.
            readonly property real grow: poof.outBack(Math.min(1, t / 0.4))
            readonly property real size: poof.puffSize * (index === 0 ? 1.25 : 0.6 + 0.55 * poof.noise(index + 80)) * (0.3 + 0.8 * grow + 0.4 * t)
            readonly property real drift: 0.55 + 0.55 * poof.outCubic(t)

            width: size
            height: size
            radius: size / 2
            x: cloud.width / 2 + Math.cos(angle) * poof.spanX * reach * drift - size / 2
            y: cloud.height / 2 + Math.sin(angle) * poof.spanY * reach * drift - Style.spaceReal(10) * poof.outCubic(t) - size / 2
            color: root.barForeground
            // In at once, holding while it billows, thinning away after.
            opacity: Math.min(1, t / 0.08) * (1 - Math.pow(Math.max(0, t - 0.3) / 0.7, 1.4)) * 0.9
          }
        }
      }

      Repeater {
        model: 7

        Rectangle {
          required property int index
          readonly property real angle: Math.PI * 2 * (index + 0.5 + poof.noise(index + 100) * 0.6) / 7
          readonly property real reach: 1.15 + 0.6 * poof.noise(index + 120)
          readonly property real t: poof.phase(0.04, 0.7 + 0.2 * poof.noise(index + 140))
          readonly property real fly: poof.outCubic(t)
          readonly property real size: Style.spaceReal(2) + Style.spaceReal(1.5) * poof.noise(index + 160)

          width: size
          height: size
          radius: size / 2
          x: Math.cos(angle) * (poof.spanX + poof.puffSize * 0.6) * reach * fly - size / 2
          y: Math.sin(angle) * (poof.spanY + poof.puffSize * 0.6) * reach * fly - size / 2
          color: root.barForeground
          opacity: (t > 0 ? 1 : 0) * (1 - t) * 0.9
        }
      }
    }
  }

  component BarMoveGhostPanel: PanelWindow {
    id: moveGhostWindow

    required property var ghostScreen
    visible: root.barMoveActive && root.sameScreen(root.barMoveScreen, ghostScreen)
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "nomarchy-bar-move-ghost"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }

    // Visual-only preview of the candidate edge. Keep the input region empty
    // so the overlay never steals the gesture area's active pointer grab.
    mask: Region {}

    // One fixed-geometry slab per edge, crossfaded on candidate changes.
    // Resizing a single slab between edges repaints mid-transition and
    // flickers; fading between static ones does not.
    Repeater {
      model: ["top", "bottom", "left", "right"]

      BorderSurface {
        id: edgeSlab

        required property string modelData
        readonly property bool edgeVertical: modelData === "left" || modelData === "right"
        readonly property int edgeSize: edgeVertical ? Style.bar.sizeVertical : Style.bar.sizeHorizontal

        x: modelData === "right" ? parent.width - edgeSize : 0
        y: modelData === "bottom" ? parent.height - edgeSize : 0
        width: edgeVertical ? edgeSize : parent.width
        height: edgeVertical ? parent.height : edgeSize
        color: root.transparent ? "transparent" : root.background
        borderSpec: Border.flat(root.barForeground, 1)
        visible: opacity > 0
        opacity: root.barMoveCandidate === modelData ? (root.transparent ? 0.45 : 0.7) : 0

        Behavior on opacity {
          NumberAnimation { duration: Style.duration(140); easing.type: Easing.OutCubic }
        }
      }
    }
  }

  component LeftModules: ModuleList {
    keys: root.leftLayoutKeys
    region: "left"
    fixedEdge: "start"
  }

  component RightModules: ModuleList {
    keys: root.rightLayoutKeys
    region: "right"
    fixedEdge: "end"
  }

  // The gesture area under the whole bar, with the center sections drawn over
  // it in the middle of it.
  component CenterModules: Item {
    id: centerRoot

    property var window: null
    property var pool: null
    // False where a display notch has moved the center sections beside the
    // right one.
    property bool drawn: true

    CenterGestureArea { anchors.fill: parent }

    CenterSections {
      anchors.fill: parent
      window: centerRoot.window
      pool: centerRoot.pool
      active: centerRoot.drawn
    }
  }

  // The center box and the two sections hanging off its edges. In the middle
  // of the bar the box is centered, and centerBegin and centerEnd grow away
  // from it. Beside the right section the three run on as one, growing toward
  // the start of the bar. Placed by hand rather than by a Row or Column, which
  // cannot center one child and hang the others off it.
  component CenterSections: Item {
    id: sections

    property var window: null
    property var pool: null
    // Only one set of center sections per bar surface is active; the other
    // shows nothing.
    property bool active: true
    property bool besideRight: false

    implicitWidth: root.vertical ? root.barSize : beginList.width + centerBox.width + endList.width
    implicitHeight: root.vertical ? beginList.height + centerBox.height + endList.height : root.barSize

    // Both placements sit at the bar surface's origin or anchor off its edge,
    // so the box's start in the sections is its start on the surface.
    readonly property real boxStart: root.vertical ? y + centerBox.y : x + centerBox.x
    onBoxStartChanged: syncPeekEdge()
    onActiveChanged: syncPeekEdge()
    onWindowChanged: syncPeekEdge()
    Component.onCompleted: syncPeekEdge()

    function syncPeekEdge(): var {
      if (active && window) BarModel.syncPeekEdge(window, boxStart, root.centerSectionRevealHeld)
    }

    Connections {
      target: root
      function onCenterSectionRevealHeldChanged(): var { sections.syncPeekEdge() }
    }

    ModuleList {
      id: beginList
      keys: sections.active ? root.centerBeginLayoutKeys : []
      window: sections.active ? sections.window : null
      pool: sections.pool
      region: "centerBegin"
      fixedEdge: "end"
      x: root.vertical ? Math.round((sections.width - width) / 2) : centerBox.x - width
      y: root.vertical ? centerBox.y - height : Math.round((sections.height - height) / 2)
    }

    ModuleList {
      id: endList
      keys: sections.active ? root.centerEndLayoutKeys : []
      window: sections.active ? sections.window : null
      pool: sections.pool
      region: "centerEnd"
      fixedEdge: sections.besideRight ? "end" : "start"
      x: root.vertical ? Math.round((sections.width - width) / 2) : centerBox.x + centerBox.width
      y: root.vertical ? centerBox.y + centerBox.height : Math.round((sections.height - height) / 2)
    }

    CenterBox {
      id: centerBox
      window: sections.window
      pool: sections.pool
      active: sections.active
      fixedEdge: sections.besideRight ? "end" : "center"
      crossSize: root.vertical ? sections.width : sections.height
      x: root.vertical ? 0 : (sections.besideRight ? beginList.width : Math.round((sections.width - width) / 2))
      y: root.vertical ? Math.round((sections.height - height) / 2) : 0
    }
  }

  // The middle of the bar: the center section's widgets, centered as one
  // group. Empty, it takes no room and the sections beside it meet in the
  // middle of the bar. During a drag on its bar it is outlined like the
  // widgets, around what it holds, a spacer for the dragged widget included,
  // and empty it shows as a line across the bar. A drop lands in it anywhere
  // within the bar's thickness of its middle (BarModel.centerDropZone).
  component CenterBox: Item {
    id: box

    property var window: null
    property var pool: null
    property bool active: true
    property string fixedEdge: "center"
    // The bar's thickness: the least length along the bar a drop into the
    // box reaches.
    property real crossSize: 0
    readonly property bool dragHere: active && !!root.barDragSource && root.sameWindow(root.barDragWindow, window)
    readonly property bool dropInto: dragHere && root.barDragRegion === "center"
    readonly property real extent: root.vertical ? boxList.height : boxList.width

    width: root.vertical ? crossSize : extent
    height: root.vertical ? extent : crossSize

    Component.onCompleted: root.registerCenterBox(box)
    Component.onDestruction: root.unregisterCenterBox(box)

    ModuleList {
      id: boxList
      keys: box.active ? root.centerLayoutKeys : []
      window: box.active ? box.window : null
      pool: box.pool
      region: "center"
      fixedEdge: box.fixedEdge
      firstEdge: box.fixedEdge === "center" ? "end" : ""
      lastEdge: box.fixedEdge === "center" ? "start" : ""
      x: Math.round((box.width - width) / 2)
      y: Math.round((box.height - height) / 2)
    }

    DropOutline {
      visible: box.dragHere
      length: box.extent
      dropInto: box.dropInto
      x: root.vertical ? Math.round((box.width - across) / 2) : 0
      y: root.vertical ? 0 : Math.round((box.height - across) / 2)
    }
  }

  // The outline of a dragged widget's room, inset from its edges: on the
  // ghost, on the room it leaves, and on the room it would land in.
  component RoomOutline: BorderSurface {
    anchors.fill: parent
    anchors.margins: Style.space(1)
    color: root.transparent ? "transparent" : root.background
    borderSpec: Border.flat(root.barForeground, 1)
    radius: Math.min(Style.cornerRadius, Math.min(width, height) / 2)
    opacity: root.transparent ? 0.22 : 0.32
  }

  // The outline of a section a drop can go into, the center box or the tray
  // section, during a drag: as wide across the bar as the dragged widget's
  // outline, and `length` along it, or a line where that is nothing.
  component DropOutline: BorderSurface {
    property real length: 0
    property bool dropInto: false
    readonly property real across: Math.max(1, (root.vertical ? root.barDragGhostWidth : root.barDragGhostHeight) - Style.space(1) * 2)

    width: root.vertical ? across : Math.max(1, length)
    height: root.vertical ? Math.max(1, length) : across
    color: "transparent"
    borderSpec: Border.flat(dropInto ? Commons.Color.accent : root.barForeground, 1)
    radius: Math.min(Style.cornerRadius, Math.min(width, height) / 2)
    opacity: dropInto ? 1 : 0.5
  }

  // A section's share of the room a drag has opened at one place, with a
  // faint copy of the dragged widget in it. It lives in the section's model
  // only while the room covers its place, and its length follows the room.
  component DragSpacer: Item {
    id: spacer

    required property var modelData
    property string region: ""
    property var window: null
    readonly property int place: BarModel.rowPlace(modelData)
    readonly property var dragged: root.barDragSource
    // How much of the room is open here, along the bar.
    readonly property real length: BarModel.draggedLength(dragged, root.barDragLengths, region, place)

    clip: true
    implicitWidth: root.vertical ? BarModel.draggedWidgetWidth(dragged) : length
    implicitHeight: root.vertical ? length : BarModel.draggedWidgetHeight(dragged)
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    Layout.alignment: Qt.AlignLeft | Qt.AlignTop

    Component.onCompleted: root.registerDragSpacer(spacer)
    Component.onDestruction: root.unregisterDragSpacer(spacer)

    RoomOutline {}

    Image {
      anchors.centerIn: parent
      width: BarModel.draggedWidgetWidth(spacer.dragged)
      height: BarModel.draggedWidgetHeight(spacer.dragged)
      source: root.barDragImageUrl
      fillMode: Image.Stretch
      smooth: true
      opacity: 0.22
    }
  }

  component CenterGestureArea: MouseArea {
    id: gestureArea

    property bool dragging: false
    property bool suppressClick: false
    property real pressedX: 0
    property real pressedY: 0
    readonly property real dragThreshold: Style.space(4)

    acceptedButtons: Qt.LeftButton
    cursorShape: dragging ? Qt.ClosedHandCursor : Qt.ArrowCursor
    pressAndHoldInterval: 200

    function startDrag(x: var, y: var): var {
      if (dragging) return
      dragging = true
      root.beginBarMove(root.targetWindow(gestureArea))
      var scenePoint = gestureArea.mapToItem(null, x, y)
      root.updateBarMove(root.windowScreenPoint(scenePoint, root.barMoveWindow))
    }

    onPressed: function(mouse: MouseEvent): var {
      dragging = false
      suppressClick = false
      pressedX = mouse.x
      pressedY = mouse.y
    }

    onPressAndHold: function(mouse: MouseEvent): var {
      // A widget above us propagates its composed press-and-hold down here without
      // ever handing over the grab, so we'd get no release or cancel to end the move.
      if (!gestureArea.pressed) return
      startDrag(mouse.x, mouse.y)
    }

    onPositionChanged: function(mouse: MouseEvent): var {
      if (!(mouse.buttons & Qt.LeftButton)) return

      if (!dragging) {
        let distance = Math.abs(mouse.x - pressedX) + Math.abs(mouse.y - pressedY)
        if (distance < dragThreshold) return
        startDrag(mouse.x, mouse.y)
        return
      }

      var scenePoint = gestureArea.mapToItem(null, mouse.x, mouse.y)
      root.updateBarMove(root.windowScreenPoint(scenePoint, root.barMoveWindow))
    }

    onReleased: function(mouse: MouseEvent): var {
      if (!dragging) return
      dragging = false
      suppressClick = true
      root.finishBarMove()
      mouse.accepted = true
    }

    onCanceled: {
      dragging = false
      suppressClick = false
      root.clearBarMove()
    }

    onClicked: function(mouse: MouseEvent): var {
      if (suppressClick) {
        suppressClick = false
        mouse.accepted = true
      }
    }

    onDoubleClicked: function(mouse: MouseEvent): var {
      if (suppressClick) {
        suppressClick = false
        return
      }
      if (mouse.button === Qt.LeftButton) {
        root.cycleBackground()
        mouse.accepted = true
      }
    }
  }

  // A layout rather than a Row or Column: sizes drive it, so spacers and a
  // folding dragged widget move their neighbours as they grow and shrink,
  // and it keeps placing a widget folded to nothing where it left.
  component ModuleList: GridLayout {
    id: moduleListRoot

    // The widgets the list shows, by their keys (root.layoutWidgets).
    property var keys: []
    property string region: ""
    // The edge of each module that stays put when the module grows: the side
    // this list is anchored by. The centered box grows both ways.
    property string fixedEdge: "center"
    // The edges the first and last of several modules grow from instead, if
    // not the list's own: the centered box's outer modules grow away from the
    // middle of the bar, as centerBegin's and centerEnd's do
    // (BarModel.slotEdge).
    property string firstEdge: ""
    property string lastEdge: ""
    // The bar surface the list is drawn on, where a drag opens room in it.
    // Null for a list that isn't drawn.
    property var window: null
    // The bar surface's widgets, which the list's slots show (WidgetPool).
    property var pool: null
    // Kept between updates, so a row stays the same object for as long as it
    // is shown (BarModel.sectionRows).
    property var rowMemo: ({})
    readonly property var listRows: BarModel.sectionRows(keys, root.sectionSpacers(region, window), rowMemo)

    visible: BarModel.listHasRows(listRows)
    flow: root.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
    rowSpacing: 0
    columnSpacing: 0

    Repeater {
      // Keyed rows, so a config change or a drag only adds, moves and removes
      // the slots and spacers that changed. A list makes no slots while it is
      // hidden, where they would hold their widgets out of sight, or before it
      // has the pool its slots take their widgets from, as the tray's drawer
      // section until its slot hands it one.
      model: ScriptModel {
        objectProp: "key"
        values: moduleListRoot.visible && moduleListRoot.pool ? moduleListRoot.listRows : []
      }

      delegate: DelegateChooser {
        role: "kind"

        DelegateChoice {
          roleValue: "spacer"

          DragSpacer {
            region: moduleListRoot.region
            window: moduleListRoot.window
          }
        }

        DelegateChoice {
          ModuleSlot {
            required property var modelData
            widgetKey: BarModel.rowKey(modelData)
            region: moduleListRoot.region
            fixedEdge: BarModel.slotEdge(BarModel.keyCount(moduleListRoot.keys), BarModel.keyIndex(moduleListRoot.keys, BarModel.rowKey(modelData)), moduleListRoot.fixedEdge, moduleListRoot.firstEdge, moduleListRoot.lastEdge)
            pool: moduleListRoot.pool
            window: moduleListRoot.window
          }
        }
      }
    }
  }

  // The tray section's list, which the tray's slot draws inside the tray's
  // drawer and hands its bar surface's pool and window.
  Component {
    id: traySectionComponent

    ModuleList {
      keys: root.trayLayoutKeys
      region: "tray"
    }
  }

  // A bar surface's widgets: one for each entry in the layout, under the key
  // it keeps wherever it moves (root.layoutWidgets), and lent to the slot
  // that shows it in whichever section that is. A widget moved to another
  // section goes from the slot it leaves to the one made for it there,
  // rather than being built again. Between the two, as one section's list
  // lets go of it and the other's takes it up, it waits here, out of sight
  // and out of the pointer's way. It goes when its entry leaves the layout,
  // and with its bar surface.
  component WidgetPool: Item {
    id: widgetPool

    // Key -> its WidgetHost, and the ModuleSlot showing it.
    property var hosts: ({})
    property var slots: ({})

    width: 0
    height: 0
    clip: true

    // A slot for a key takes its widget, from the pool or from the slot that
    // had it, whichever of the two lists changes first.
    function claim(slot: ModuleSlot): void {
      BarModel.claimWidgetSlot(slots, hosts, slot)
    }

    function release(slot: ModuleSlot): void {
      BarModel.releaseWidgetSlot(slots, hosts, slot)
    }

    function addHost(host: WidgetHost): void {
      BarModel.addWidgetHost(hosts, slots, host)
    }

    function removeHost(host: WidgetHost): void {
      BarModel.removeWidgetHost(hosts, slots, host)
    }

    // Keys alone, in a fixed order: a widget's row never moves or changes,
    // and is added and removed with its entry.
    Instantiator {
      model: ScriptModel { values: BarModel.layoutWidgetKeys(root.layoutWidgets) }
      delegate: WidgetHost { pool: widgetPool }
    }
  }

  // One widget on a bar surface, loaded from its entry, and drawn in the slot
  // that holds it (WidgetPool). It hands the widget its settings, the bar,
  // and the edge its slot's section grows from.
  component WidgetHost: Item {
    id: host

    required property string modelData
    property var pool: null
    readonly property string key: modelData
    final readonly property var entry: BarModel.layoutEntry(root.layoutWidgets, key)
    // The slot showing it, set by the pool; null while it waits there.
    property var owner: null
    // Whether a slot has held it yet. The widget is loaded only then, so it
    // knows the edge its section grows from before it has a bar.
    property bool placed: false
    readonly property bool dragSource: BarModel.hostDragSource(owner)
    // The edge it grows from, as the slot that last held it says.
    property string fixedEdge: "center"
    final readonly property string moduleName: root.entryId(entry)
    readonly property var moduleSettings: root.entrySettings(entry)
    readonly property string customType: root.customModuleType(entry)
    readonly property var registryMetadata: root.barWidgetRegistry.metadataFor(root.canonicalWidgetId(moduleName))
    readonly property bool firstParty: BarModel.metadataFirstParty(registryMetadata)
    readonly property string pluginApiId: registered ? root.canonicalWidgetId(moduleName) : "bar-entry:" + moduleName
    // Re-evaluate when the registry mutates (Component reference changes,
    // plugin enabled/disabled, etc.). Its revision signal supplies the QML
    // binding dependency while the model reads the dynamic widget map.
    readonly property var registryComponent: {
      var revision = root.barWidgetRegistryRevision
      if (customType) return null
      var registryName = root.canonicalWidgetId(moduleName)
      return BarModel.registryComponent(root.barWidgetRegistry, registryName)
    }
    readonly property bool qmlCustom: customType === "qml"
    readonly property bool commandCustom: customType === "command"
    readonly property bool registered: registryComponent !== null
    final readonly property var activeItem: {
      if (registered) return registryLoader.item
      if (qmlCustom) return qmlLoader.item
      return componentLoader.item
    }
    final readonly property real widgetWidth: BarModel.widgetWidth(activeItem, root.vertical, root.barSize)
    final readonly property real widgetHeight: BarModel.widgetHeight(activeItem)

    parent: BarModel.widgetParent(owner, pool)
    width: widgetWidth
    height: widgetHeight

    Component.onCompleted: {
      if (pool) pool.addHost(host)
      root.registerWidgetHost(host)
    }
    Component.onDestruction: {
      if (pool) pool.removeHost(host)
      root.unregisterWidgetHost(host)
    }

    // Waiting in the pool, it keeps the edge it had, so a widget handed from
    // one section to another hears only of the edge it lands with.
    onOwnerChanged: {
      if (!owner) {
        unplaced.restart()
        return
      }
      fixedEdge = BarModel.ownerFixedEdge(owner)
      placed = true
    }
    // One no slot takes up again by the time the update is over, as one in
    // the tray's drawer while the tray is off the bar, is unloaded rather
    // than left running where nothing shows it, and loaded again when a slot
    // holds it.
    Timer {
      id: unplaced
      interval: 0
      onTriggered: if (!host.owner) host.placed = false
    }
    Connections {
      target: host.owner
      function onFixedEdgeChanged(): void { host.fixedEdge = BarModel.ownerFixedEdge(host.owner) }
    }

    Loader {
      id: componentLoader
      active: host.placed && !host.qmlCustom && !host.registered
      sourceComponent: host.commandCustom ? customCommandModuleComponent : emptyModuleComponent
      width: host.widgetWidth
      height: host.widgetHeight
      opacity: host.dragSource ? 0.22 : 1.0
      onLoaded: {
        host.injectProps()
        Qt.callLater(host.injectProps)
      }
    }

    Loader {
      id: registryLoader
      active: host.placed && host.registered
      sourceComponent: host.registered ? host.registryComponent : null
      width: host.widgetWidth
      height: host.widgetHeight
      opacity: host.dragSource ? 0.22 : 1.0
      onLoaded: {
        host.injectProps()
        Qt.callLater(host.injectProps)
      }
    }

    Loader {
      id: qmlLoader
      active: host.placed && host.qmlCustom
      source: host.qmlCustom ? root.customModuleSource(host.entry) : ""
      width: host.widgetWidth
      height: host.widgetHeight
      opacity: host.dragSource ? 0.22 : 1.0
      onLoaded: {
        host.injectProps()
        Qt.callLater(host.injectProps)
      }
    }

    onActiveItemChanged: Qt.callLater(injectProps)
    onModuleSettingsChanged: injectProps()
    onFixedEdgeChanged: injectProps()

    function injectProps(): void {
      var target = activeItem
      if (!target) return
      BarModel.setProperty(target, "fixedEdge", fixedEdge)
      if (BarModel.hasProperty(target, "bar"))
        BarModel.setProperty(target, "bar", firstParty ? root : root.pluginBarApiFor(pluginApiId, moduleName, registered))
      BarModel.setProperty(target, "moduleName", moduleName)
      BarModel.setProperty(target, "settings", moduleSettings)
    }

    Component {
      id: customCommandModuleComponent
      CustomCommandModule { entry: host.entry }
    }
  }

  // A widget's place in its section. It shows the widget its bar surface
  // keeps under its key, lent by the pool (WidgetPool), is sized by it, and
  // takes the pointer: clicks, the open-panel mark, and drags.
  component ModuleSlot: Item {
    id: slot

    property string widgetKey: ""
    property string region: ""
    property string fixedEdge: "center"
    property var pool: null
    // The bar surface its section is drawn on.
    property var window: null
    // The widget, while the slot holds it (WidgetPool.claim).
    property WidgetHost host: null
    readonly property var entry: host ? host.entry : null
    readonly property string moduleName: host ? host.moduleName : ""
    readonly property var activeItem: host ? host.activeItem : null
    readonly property bool hovered: moduleHover.hovered
    readonly property bool dragSource: root.barDragSource === slot
    // A widget let go of past the removal threshold leaves the bar the
    // moment its poof starts, though its entry stays in the layout until
    // the poof has played.
    readonly property bool removalPending: root.isPendingRemoval(widgetKey)
    readonly property bool panelOpen: root.activePopout === slot.activeItem
    // Modules bigger than the mark they want (a text label in a padded slot,
    // a multi-line stack on a vertical bar) can say how long the open-panel
    // dot should be along the bar, so it tracks what the module paints
    // instead of a fraction of whatever slot it happens to fill.
    readonly property real panelIndicatorExtent: {
      var mark = panelIndicatorItem
      if (mark) return Math.max(Style.space(10), Math.round((root.vertical ? mark.height : mark.width) * 0.55))
      var key = root.vertical ? "openPanelIndicatorHeight" : "openPanelIndicatorWidth"
      var hint = activeItem && key in activeItem ? activeItem[key] : undefined
      if (hint !== undefined && hint !== null && hint > 0) return Math.round(hint)
      return Math.max(Style.space(10), Math.round((root.vertical ? slot.widgetHeight : slot.widgetWidth) * 0.55))
    }
    // A module holding several things a panel can open from (the tray's
    // icons) names the one whose panel is open, and the mark sits under it
    // rather than under the middle of the module.
    readonly property Item panelIndicatorItem: BarModel.field(activeItem, "openPanelIndicatorItem") || null
    readonly property real panelIndicatorCenter: {
      var mark = panelIndicatorItem
      if (!mark) return (root.vertical ? widgetArea.height : widgetArea.width) / 2
      // A menu opened while the drawer is still sliding open moves with it;
      // mapToItem alone would not re-run as the item moves.
      var reveal = BarModel.field(activeItem, "revealProgress") || 0
      return BarModel.mappedCenter(mark, widgetArea, root.vertical)
    }
    // The tray, or a clone of it, hosts the tray section in its drawer; one
    // inside the drawer does not, so the section never holds itself.
    readonly property bool hostsTraySection: region !== "tray" && !!activeItem && "sectionHost" in activeItem
    // Its drawer section is outlined while a widget that could go in it is
    // dragged on this bar, as the center box is.
    readonly property bool traySectionShown: hostsTraySection && root.traySectionDragActive && root.sameWindow(root.barDragWindow, window)
    // A drop now would land in its drawer section, so the whole tray lights up.
    readonly property bool trayDropInto: traySectionShown && root.barDragRegion === "tray"
    // The part of the section the drawer shows, in the slot's widget area,
    // or null while the drawer hides all of it (the tray's sectionShown).
    readonly property var traySectionGeometry: BarModel.traySectionGeometry(hostsTraySection, activeItem, holder)
    // Where the section is now, for a drop: as traySectionGeometry, or for a
    // tray cloned before trays said how much of it shows, the whole section.
    function traySectionNow(): var {
      return BarModel.traySectionNow(hostsTraySection, activeItem, traySectionGeometry, widgetArea)
    }

    function traySectionContains(x: real, y: real): bool {
      return BarModel.slotTraySectionContains(slot, x, y)
    }
    final readonly property real widgetWidth: BarModel.widgetWidthFromHost(host)
    final readonly property real widgetHeight: BarModel.widgetHeightFromHost(host)
    // Its length along the bar. The dragged widget keeps its place's share
    // of the room: all of it until the room moves away.
    readonly property real alongLength: removalPending ? 0 : dragSource
      ? (root.barDragLengths[root.barDragHome] || 0)
      : (root.vertical ? widgetHeight : widgetWidth)

    // Where the dragged widget lands when it goes back where it was.
    readonly property Item widgetRoom: widgetArea
    // Where the pool puts the widget.
    readonly property Item widgetHolder: holder
    // The section's layout sizes the slot by these, and lines slots up at
    // their start across the bar rather than centering them.
    // Handed to it as preferred sizes, since a layout left to read a size
    // that drops from a fraction of a pixel to nothing keeps the old size,
    // leaving a hole where a widget hid itself.
    implicitWidth: root.vertical ? widgetWidth : alongLength
    implicitHeight: root.vertical ? alongLength : widgetHeight
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    Layout.alignment: Qt.AlignLeft | Qt.AlignTop
    z: modulePointer.dragging ? 100 : 0

    Component.onCompleted: {
      if (pool) pool.claim(slot)
      root.registerModuleSlot(slot)
    }
    Component.onDestruction: {
      // Later, since a slot goes while its section's model is being changed,
      // which the drag's room feeds.
      if (root.barDragSource === slot) Qt.callLater(root.clearBarDrag)
      if (pool) pool.release(slot)
      root.unregisterModuleSlot(slot)
    }

    HoverHandler { id: moduleHover }

    // The widget at its own size. Lifted out by a drag, it folds away with
    // its room.
    Item {
      id: widgetArea

      width: root.vertical ? slot.widgetWidth : slot.alongLength
      height: root.vertical ? slot.alongLength : slot.widgetHeight
      clip: slot.dragSource || slot.removalPending

      RoomOutline { visible: slot.dragSource }

      // The whole tray, lit while a drop would land in its drawer section and
      // dark again the moment the pointer takes the widget out, so in and out
      // of the tray read at a glance. Under the icons, so they stay crisp.
      DropOutline {
        visible: slot.trayDropInto
        length: root.vertical ? parent.height : parent.width
        dropInto: true
        color: Util.alpha(Commons.Color.accent, 0.15)
        x: root.vertical ? Math.round((parent.width - across) / 2) : 0
        y: root.vertical ? 0 : Math.round((parent.height - across) / 2)
      }

      // Folding away under a drag, the slot keeps the widget centred, like
      // the copy in the room it opens (DragSpacer).
      Item {
        id: holder
        anchors.centerIn: parent
        width: slot.widgetWidth
        height: slot.widgetHeight
      }

      // The tray section's outline, as the center box's: around what it
      // holds, the room for the dragged widget included, or a line where it
      // holds nothing. Drawn over the tray rather than in its drawer, whose
      // clip would hide an empty section's line. Faint until a drop would
      // land in it; then the whole tray's highlight takes over.
      DropOutline {
            readonly property var section: BarModel.rectOrEmpty(slot.traySectionGeometry)

        visible: slot.traySectionShown && !slot.trayDropInto && !!slot.traySectionGeometry
        length: BarModel.rectLength(section, root.vertical)
        x: root.vertical ? Math.round((parent.width - across) / 2) : BarModel.rectX(section)
        y: root.vertical ? BarModel.rectY(section) : Math.round((parent.height - across) / 2)
        z: 40
      }

      Rectangle {
        id: openPanelIndicator

        readonly property int inset: Style.space(2)

        visible: opacity > 0
        opacity: slot.panelOpen && !slot.dragSource ? 0.9 : 0
        color: Commons.Color.accent
        radius: Math.min(width, height) / 2
        width: root.vertical ? Style.space(2) : slot.panelIndicatorExtent
        height: root.vertical ? slot.panelIndicatorExtent : Style.space(2)
        // The mark sits on the module's inner edge — the one facing the
        // desktop — so it underlines a top bar, overlines a bottom one, and
        // points inward from a left or right one. It reads as pointing at the
        // panel that opens on that side.
        // Snap toward the start of the slot, matching native glyph rendering.
        x: root.vertical
          ? (root.position === "left" ? parent.width - width - inset : inset)
          : Math.floor(slot.panelIndicatorCenter - width / 2)
        y: root.vertical
          ? Math.floor(slot.panelIndicatorCenter - height / 2)
          : (root.position === "top" ? parent.height - height - inset : inset)
        z: 50

        Behavior on opacity {
          NumberAnimation { duration: Style.duration(120); easing.type: Easing.OutCubic }
        }
      }
    }

    // The tray section's widgets, drawn inside the tray's drawer. They are
    // ordinary module slots of their own region, so they open panels, drag
    // and keep settings the way widgets on the bar do.
    // Built through a Component outside ModuleSlot: a module list holds
    // module slots, so one declared in here would make the types a cycle.
    Loader {
      id: traySectionLoader
      readonly property Item host: slot.hostsTraySection ? BarModel.field(slot.activeItem, "sectionHost") : null
      parent: host || slot
      active: !!host
      sourceComponent: traySectionComponent
    }
    Binding { target: traySectionLoader.item; property: "window"; value: slot.window }
    Binding { target: traySectionLoader.item; property: "pool"; value: slot.pool }
    // Its widgets grow from the edge the tray anchors the section by.
    Binding { target: traySectionLoader.item; property: "fixedEdge"; value: slot.hostsTraySection && BarModel.field(slot.activeItem, "sectionEdge") || "center" }

    MouseArea {
      id: modulePointer

      property bool dragging: false
      property bool suppressClick: false
      // This area sits over the slot's widget and takes its press, so the
      // widget never sees itself held; it's told, for its press feedback.
      property var heldTarget: null
      property real pressedX: 0
      property real pressedY: 0
      readonly property bool canReorder: BarModel.canReorder(root.shell)
      readonly property real dragThreshold: Style.space(4)

      anchors.fill: parent
      acceptedButtons: Qt.LeftButton
      // Sized by the widget, not the slot, which a drag can shrink to nothing
      // under the pointer that holds it.
      enabled: slot.visible && slot.widgetWidth > 0 && slot.widgetHeight > 0
      propagateComposedEvents: true
      // Only the hovered slot needs the hit test; without the guard every
      // slot on every monitor re-ran it on each click target change.
      cursorShape: moduleHover.hovered && root.moduleClickTargetAt(slot, mouseX, mouseY) ? Qt.PointingHandCursor : Qt.ArrowCursor
      // Do not assign drag.target here: the section's layout places
      // ModuleSlot, and moving slot.x/slot.y by hand fights it. The ghost
      // follows the pointer instead.

      onPressed: function(mouse: MouseEvent): var {
        // A press on a widget in the tray's drawer belongs to that widget's
        // own slot, underneath this one, so it drags that widget, not the tray.
        if (slot.traySectionContains(mouse.x, mouse.y)) {
          mouse.accepted = false
          return
        }
        dragging = false
        suppressClick = false
        pressedX = mouse.x
        pressedY = mouse.y
        hold(root.moduleClickTargetAt(slot, mouse.x, mouse.y), mouse.button)
        root.finishBarSettle()
        root.clearBarDrag()
      }

      function hold(target: var, button: int): void {
        heldTarget = BarModel.holdTarget(heldTarget, target, button, Qt.NoButton)
      }

      onPositionChanged: function(mouse: MouseEvent): var {
        if (!canReorder || !(mouse.buttons & Qt.LeftButton)) return

        var distance = Math.abs(mouse.x - pressedX) + Math.abs(mouse.y - pressedY)
        if (distance >= dragThreshold) {
          if (!dragging) root.beginBarDrag(slot, pressedX, pressedY)
          dragging = true
          hold(null, Qt.NoButton)
          root.hideTooltip(slot.activeItem)
        }

        // A drag let go of from elsewhere (onLayoutWidgetsChanged) stays let
        // go of until the button comes up.
        if (dragging && root.barDragSource === slot) {
          let scenePoint = slot.mapToItem(null, mouse.x, mouse.y)
          let screenPoint = root.barDragScreenPoint(scenePoint)
          root.barDragSceneX = BarModel.pointX(scenePoint)
          root.barDragSceneY = BarModel.pointY(scenePoint)
          root.barDragScreenX = BarModel.pointX(screenPoint)
          root.barDragScreenY = BarModel.pointY(screenPoint)

          let drop = root.moduleDropAtScene(scenePoint, slot)
          root.barDragTarget = drop
          root.moveDragRoom(drop)
          root.setBarDragRemoveArmed(!drop && root.moduleRemoveDistance(screenPoint) >= root.barDragRemoveDistance)
        }
      }

      onReleased: function(mouse: MouseEvent): var {
        var wasDragging = dragging
        hold(null, Qt.NoButton)

        dragging = false

        if (wasDragging) {
          suppressClick = true
          if (root.barDragSource === slot && root.barDragRemoveArmed) root.removeBarDrag(slot)
          else if (root.barDragSource === slot) root.settleBarDrag(slot)
          mouse.accepted = true
        } else {
          root.clearBarDrag()
          mouse.accepted = false
        }
      }

      onCanceled: {
        dragging = false
        suppressClick = false
        hold(null, Qt.NoButton)
        root.clearBarDrag()
      }

      onClicked: function(mouse: MouseEvent): var {
        if (suppressClick) {
          suppressClick = false
          mouse.accepted = true
          return
        }

        if (!root.pressModuleClickTarget(slot, mouse.button, mouse.x, mouse.y)) mouse.accepted = false
      }
    }
  }

  component CustomCommandModule: WidgetButton {
    id: customRoot

    required property var entry
    // Writable, as on any widget: its host hands it the same values.
    property string moduleName: root.entryId(entry)
    property var settings: root.entrySettings(entry)
    property string outputText: ""
    property string outputTooltip: ""
    property bool outputActive: false

    function setting(name: var, fallback: var): var {
      var value = settings ? settings[name] : undefined
      return value === undefined || value === null ? fallback : value
    }

    function update(raw: var): void {
      BarModel.updateCommandModule(customRoot, raw, Util)
    }

    bar: root
    text: outputText || String(setting("text", ""))
    tooltipText: outputTooltip || String(setting("tooltip", ""))
    active: outputActive
    keepSpace: setting("keepSpace", false) === true
    horizontalMargin: Number(setting("horizontalMargin", 7.5))
    verticalPadding: Number(setting("verticalPadding", 6))
    fontSize: Number(setting("fontSize", 12))

    onPressed: function(button: int): var {
      var command = ""
      if (button === Qt.RightButton)
        command = String(setting("onRightClick", ""))
      else if (button === Qt.MiddleButton)
        command = String(setting("onMiddleClick", ""))
      else
        command = String(setting("onClick", ""))

      if (command) root.run(command)
    }

    Process {
      id: customProc
      command: ["C:/Program Files/Git/usr/bin/bash.exe", "-lc", String(customRoot.setting("exec", ""))]
      stdout: StdioCollector {
        waitForEnd: true
        onStreamFinished: customRoot.update(text)
      }
    }

    Timer {
      interval: Math.max(1, Number(customRoot.setting("interval", 5))) * 1000
      running: String(customRoot.setting("exec", "")) !== ""
      repeat: true
      triggeredOnStart: true
      onTriggered: root.runProcess(customProc)
    }
  }
}
