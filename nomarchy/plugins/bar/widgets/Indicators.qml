pragma ComponentBehavior: Bound
import QtQuick
import qs.Commons as Commons
import qs.Ui
import "IndicatorModel.js" as IndicatorModel

BarWidget {
  id: root
  moduleName: "nomarchy.indicators"

  readonly property list<var> defaultIndicatorEntries: [ "PasswordlessSudo", "ScreenRecording", "RemoteSession", "Reminder", "NightLight", "Dnd", "StayAwake" ]
  readonly property list<var> indicatorEntries: indicatorEntriesFromSettings(settings)
  property list<var> activeIndicatorIds: []
  property var indicatorActiveStates: ({})
  property bool indicatorAreaHovered: false
  property bool indicatorItemHovered: false
  readonly property bool alwaysShowIndicators: setting("alwaysShow", false) === true
  readonly property bool revealInactiveIndicators: alwaysShowIndicators || indicatorAreaHovered || indicatorItemHovered || (bar && BarValues.centerSectionRevealHeld(bar) === true && BarValues.centerHoverRevealSuppressed(bar) !== true)
  // The active block sits against the widget's fixed edge, and everything that
  // grows the widget (revealed inactive icons, newly active ones) goes on its
  // far side, so the icons already showing keep their click targets. A
  // centered widget grows both ways and keeps the end-fixed arrangement.
  readonly property bool fixedAtStart: fixedEdge === "start"

  signal refreshRequested()

  ListModel { id: activeIndicatorModel }

  // The inactive indicators in the order they show. Facing the other way, the
  // widget mirrors them along with its blocks, so they read outward from the
  // active block as they do from the other side. Turned around by moves, so no
  // indicator is built again.
  ListModel { id: inactiveIndicatorModel }
  property string inactiveIndicatorJson: ""
  property bool inactiveIndicatorsMirrored: false

  function entryId(entry: var): string { return IndicatorModel.entryId(entry) }
  function entrySettings(entry: var): var { return IndicatorModel.entrySettings(entry) }
  function indicatorEntriesFromSettings(settings: var): var {
    return IndicatorModel.entries(settings, defaultIndicatorEntries)
  }

  function setIndicatorAreaHovered(hovered: var): var {
    indicatorAreaHovered = hovered
    if (hovered) indicatorHideTimer.stop()
    else indicatorHideTimer.restart()
  }

  function setIndicatorItemHovered(hovered: var): var {
    if (hovered) {
      indicatorItemHovered = true
      indicatorHideTimer.stop()
    } else {
      indicatorHideTimer.restart()
    }
  }

  function hasIndicatorId(id: var): var {
    for (let i = 0; i < indicatorEntries.length; i++) {
      if (entryId(indicatorEntries[i]) === id) return true
    }
    return false
  }

  function entryForId(id: var): var {
    for (let i = 0; i < indicatorEntries.length; i++) {
      let entry = indicatorEntries[i]
      if (entryId(entry) === id) return entry
    }

    return { id: id }
  }

  function activeModelIndex(id: var): var {
    for (let i = 0; i < activeIndicatorModel.count; i++) {
      if (activeIndicatorModel.get(i).activeId === id) return i
    }
    return -1
  }

  function copyActiveStates(): var {
    var states = {}
    for (let id in indicatorActiveStates) {
      if (indicatorActiveStates[id] === true) states[id] = true
    }
    return states
  }

  function orderedActiveIds(states: var, preferredOrder: var): var {
    var ids = []

    for (let i = 0; i < preferredOrder.length; i++) {
      let id = preferredOrder[i]
      if (ids.indexOf(id) === -1 && hasIndicatorId(id) && states[id] === true) ids.push(id)
    }

    return ids
  }

  function syncActiveIndicatorModel(): var {
    for (let i = activeIndicatorModel.count - 1; i >= 0; i--) {
      if (activeIndicatorIds.indexOf(activeIndicatorModel.get(i).activeId) === -1)
        activeIndicatorModel.remove(i)
    }

    for (let j = 0; j < activeIndicatorIds.length; j++) {
      let id = activeIndicatorIds[j]
      let index = activeModelIndex(id)
      if (index === -1) activeIndicatorModel.insert(j, { activeId: id })
      else if (index !== j) activeIndicatorModel.move(index, j, 1)
    }
  }

  function setIndicatorActive(entry: var, active: var): var {
    var id = entryId(entry)
    if (id === "") return

    var states = copyActiveStates()
    if (active) states[id] = true
    else delete states[id]

    indicatorActiveStates = states

    var ids = orderedActiveIds(states, activeIndicatorIds)
    // Newcomers go on the side of the active block away from the fixed edge.
    // The other side would shove everything already showing sideways.
    if (active && ids.indexOf(id) === -1 && hasIndicatorId(id)) {
      if (fixedAtStart) ids.push(id)
      else ids.unshift(id)
    }
    activeIndicatorIds = ids
    syncActiveIndicatorModel()
  }

  function syncActiveIndicatorOrder(): var {
    activeIndicatorIds = orderedActiveIds(indicatorActiveStates, activeIndicatorIds)
    syncActiveIndicatorModel()
  }

  function syncInactiveIndicatorModel(): var {
    var json = JSON.stringify(indicatorEntries)
    if (json !== inactiveIndicatorJson) {
      inactiveIndicatorJson = json
      inactiveIndicatorModel.clear()
      inactiveIndicatorsMirrored = false
      for (let i = 0; i < indicatorEntries.length; i++)
        inactiveIndicatorModel.append({ entryJson: JSON.stringify(indicatorEntries[i]) })
    }
    if (inactiveIndicatorsMirrored === fixedAtStart) return
    for (let j = 1; j < inactiveIndicatorModel.count; j++) inactiveIndicatorModel.move(j, 0, 1)
    inactiveIndicatorsMirrored = fixedAtStart
  }

  function refresh(): var { root.refreshRequested() }

  onIndicatorEntriesChanged: {
    syncActiveIndicatorOrder()
    syncInactiveIndicatorModel()
  }
  onFixedAtStartChanged: syncInactiveIndicatorModel()

  // Only the tree for the current orientation exists (see orientationLoader
  // below); its wrapper keeps the stock sizing expressions, so the root's
  // implicit size still follows the blocks synchronously rather than waiting
  // on a positioner's polish.
  readonly property Item orientationItem: orientationLoader.item as Item
  implicitWidth: orientationItem ? orientationItem.implicitWidth : 0
  implicitHeight: orientationItem ? orientationItem.implicitHeight : 0

  Commons.ShellIpc {
    target: "nomarchy.indicators"

    function refresh(): void {
      root.broadcast("refresh")
    }
  }

  Timer {
    id: indicatorHideTimer
    interval: 120
    onTriggered: {
      if (!root.indicatorAreaHovered)
        root.indicatorItemHovered = false
    }
  }

  Component.onCompleted: {
    syncInactiveIndicatorModel()
    root.refreshRequested()
  }

  // Instantiating both orientation trees and toggling `visible` doubled every
  // indicator per bar (and every process an indicator spawns, once per
  // monitor). Load only the tree that matches the bar orientation instead.
  Loader {
    id: orientationLoader
    sourceComponent: root.vertical ? verticalIndicatorsTree : horizontalIndicatorsTree
  }

  // The two blocks are placed by hand rather than by a Row or Column: a
  // Column cannot reverse its order, and the inactive area has to go on
  // whichever side is away from the fixed edge.
  Component {
    id: horizontalIndicatorsTree

    Item {
      implicitWidth: activeHorizontalBlock.implicitWidth + inactiveHorizontalArea.implicitWidth
      implicitHeight: Math.max(activeHorizontalBlock.implicitHeight, inactiveHorizontalArea.implicitHeight)
      width: implicitWidth
      height: implicitHeight

      HoverHandler {
        onHoveredChanged: root.setIndicatorAreaHovered(hovered)
      }

      Item {
        id: inactiveHorizontalArea

        x: root.fixedAtStart ? activeHorizontalBlock.width : 0
        implicitWidth: root.revealInactiveIndicators ? inactiveHorizontalBlock.implicitWidth : 0
        implicitHeight: Math.max(inactiveHorizontalBlock.implicitHeight, root.barSize)
        width: implicitWidth
        height: implicitHeight
        clip: true

        IndicatorBlock {
          id: inactiveHorizontalBlock
          anchors.verticalCenter: parent.verticalCenter
          indicatorsModule: root
          indicatorModel: inactiveIndicatorModel
          indicatorBlock: "inactive"
          horizontal: true
          reportActiveState: !root.vertical
        }

        HoverHandler {
          onHoveredChanged: root.setIndicatorAreaHovered(hovered)
        }
      }

      ActiveIndicatorBlock {
        id: activeHorizontalBlock
        x: root.fixedAtStart ? 0 : inactiveHorizontalArea.width
        indicatorsModule: root
        indicatorModel: activeIndicatorModel
        horizontal: true
        reportActiveState: !root.vertical
      }
    }
  }

  Component {
    id: verticalIndicatorsTree

    Item {
      implicitWidth: Math.max(activeVerticalBlock.implicitWidth, inactiveVerticalArea.implicitWidth)
      implicitHeight: activeVerticalBlock.implicitHeight + inactiveVerticalArea.implicitHeight
      width: implicitWidth
      height: implicitHeight

      HoverHandler {
        onHoveredChanged: root.setIndicatorAreaHovered(hovered)
      }

      Item {
        id: inactiveVerticalArea

        y: root.fixedAtStart ? activeVerticalBlock.height : 0
        implicitWidth: Math.max(inactiveVerticalBlock.implicitWidth, root.barSize)
        implicitHeight: root.revealInactiveIndicators ? inactiveVerticalBlock.implicitHeight : 0
        width: implicitWidth
        height: implicitHeight
        clip: true

        IndicatorBlock {
          id: inactiveVerticalBlock
          anchors.horizontalCenter: parent.horizontalCenter
          indicatorsModule: root
          indicatorModel: inactiveIndicatorModel
          indicatorBlock: "inactive"
          horizontal: false
          reportActiveState: root.vertical
        }

        HoverHandler {
          onHoveredChanged: root.setIndicatorAreaHovered(hovered)
        }
      }

      ActiveIndicatorBlock {
        id: activeVerticalBlock
        y: root.fixedAtStart ? 0 : inactiveVerticalArea.height
        indicatorsModule: root
        indicatorModel: activeIndicatorModel
        horizontal: false
        reportActiveState: root.vertical
      }
    }
  }

  HoverHandler {
    onHoveredChanged: root.setIndicatorAreaHovered(hovered)
  }

  component ActiveIndicatorBlock: Item {
    id: activeIndicatorBlockRoot

    property var indicatorModel: null
    property var indicatorsModule: null
    property bool horizontal: true
    property bool reportActiveState: false

    readonly property Item blockItem: blockLoader.item as Item
    implicitWidth: blockItem ? blockItem.implicitWidth : 0
    implicitHeight: blockItem ? blockItem.implicitHeight : 0
    width: implicitWidth
    height: implicitHeight

    Loader {
      id: blockLoader

      anchors.centerIn: parent
      sourceComponent: activeIndicatorBlockRoot.horizontal ? horizontalActiveIndicatorBlock : verticalActiveIndicatorBlock
    }

    Component {
      id: horizontalActiveIndicatorBlock

      Row {
        spacing: 0

        Repeater {
          model: activeIndicatorBlockRoot.indicatorModel

          IndicatorLoader {
            required property string activeId
            indicatorsModule: activeIndicatorBlockRoot.indicatorsModule
            entry: activeIndicatorBlockRoot.indicatorsModule.entryForId(activeId)
            indicatorBlock: "active"
            reportActiveState: activeIndicatorBlockRoot.reportActiveState
          }
        }
      }
    }

    Component {
      id: verticalActiveIndicatorBlock

      Column {
        spacing: 0

        Repeater {
          model: activeIndicatorBlockRoot.indicatorModel

          IndicatorLoader {
            required property string activeId
            indicatorsModule: activeIndicatorBlockRoot.indicatorsModule
            entry: activeIndicatorBlockRoot.indicatorsModule.entryForId(activeId)
            indicatorBlock: "active"
            reportActiveState: activeIndicatorBlockRoot.reportActiveState
          }
        }
      }
    }
  }

  component IndicatorBlock: Item {
    id: indicatorBlockRoot

    property var indicatorModel: null
    property var indicatorsModule: null
    property string indicatorBlock: "active"
    property bool horizontal: true
    property bool reportActiveState: false

    readonly property Item blockItem: blockLoader.item as Item
    implicitWidth: blockItem ? blockItem.implicitWidth : 0
    implicitHeight: blockItem ? blockItem.implicitHeight : 0
    width: implicitWidth
    height: implicitHeight

    Loader {
      id: blockLoader

      anchors.centerIn: parent
      sourceComponent: indicatorBlockRoot.horizontal ? horizontalIndicatorBlock : verticalIndicatorBlock
    }

    Component {
      id: horizontalIndicatorBlock

      Row {
        spacing: 0

        Repeater {
          model: indicatorBlockRoot.indicatorModel

          IndicatorLoader {
            required property string entryJson
            indicatorsModule: indicatorBlockRoot.indicatorsModule
            entry: JSON.parse(entryJson)
            indicatorBlock: indicatorBlockRoot.indicatorBlock
            reportActiveState: indicatorBlockRoot.reportActiveState
          }
        }
      }
    }

    Component {
      id: verticalIndicatorBlock

      Column {
        spacing: 0

        Repeater {
          model: indicatorBlockRoot.indicatorModel

          IndicatorLoader {
            required property string entryJson
            indicatorsModule: indicatorBlockRoot.indicatorsModule
            entry: JSON.parse(entryJson)
            indicatorBlock: indicatorBlockRoot.indicatorBlock
            reportActiveState: indicatorBlockRoot.reportActiveState
          }
        }
      }
    }
  }

  component IndicatorLoader: Item {
    id: indicatorSlot

    required property var entry
    property var indicatorsModule: null
    required property string indicatorBlock
    property bool reportActiveState: false
    property bool activeStateObserved: false
    readonly property string indicatorId: root.entryId(entry)
    readonly property var indicatorSettings: root.entrySettings(entry)
    readonly property var barRef: root.bar

    readonly property Item indicatorItem: indicatorSource.item as Item
    implicitWidth: indicatorItem && indicatorItem.visible ? indicatorItem.implicitWidth : 0
    implicitHeight: indicatorItem && indicatorItem.visible ? indicatorItem.implicitHeight : 0
    width: implicitWidth
    height: implicitHeight
    onEntryChanged: {
      activeStateObserved = false
      injectProps()
      syncActiveState()
    }
    onIndicatorBlockChanged: injectProps()
    onIndicatorSettingsChanged: injectProps()
    onIndicatorsModuleChanged: {
      injectProps()
      syncActiveState()
    }
    onReportActiveStateChanged: syncActiveState()
    onBarRefChanged: injectProps()

    Loader {
      id: indicatorSource

      anchors.fill: parent
      source: indicatorSlot.indicatorId ? Qt.resolvedUrl("../indicators/" + indicatorSlot.indicatorId + ".qml") : ""
      onLoaded: {
        indicatorSlot.injectProps()
        indicatorSlot.syncActiveState()
      }
      onStatusChanged: if (status === Loader.Error) console.warn("Indicator loader error", indicatorSlot.indicatorId, source)
    }

    Connections {
      target: indicatorSource.item
      ignoreUnknownSignals: true
      function onActiveChanged(): var { indicatorSlot.syncActiveState() }
    }

    function injectProps(): void {
      IndicatorModel.injectProps(indicatorSource.item, root.bar, indicatorId, indicatorSettings, indicatorBlock, root)
    }

    function syncActiveState(): var {
      if (!reportActiveState || !indicatorsModule || !indicatorsModule.setIndicatorActive) return

      var active = IndicatorModel.isActive(indicatorSource.item)
      if (indicatorBlock === "active") {
        if (active) activeStateObserved = true
        else if (!activeStateObserved) return
      }

      indicatorsModule.setIndicatorActive(entry, active)
    }
  }
}
