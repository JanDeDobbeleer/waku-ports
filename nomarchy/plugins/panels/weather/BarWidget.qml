import QtQuick
import qs.Commons
import qs.Ui
import "." as Local
import "Model.js" as Model

BarWidget {
  id: root
  moduleName: "nomarchy.weather"

  readonly property Local.Panel loadedPanel: panelLoader.item as Local.Panel

  function injectPanel() {
    var target = root.loadedPanel
    if (!target) return
    if ("bar" in target) Model.setField(target, "bar", root.bar)
    if ("settings" in target) Model.setField(target, "settings", root.settings)
    if ("anchorItem" in target) Model.setField(target, "anchorItem", button)
    if ("hostWidget" in target) Model.setField(target, "hostWidget", root)
  }

  function refresh() {
    if (Model.hasMethod(root.loadedPanel, "refresh")) Model.invoke(root.loadedPanel, "refresh")
  }

  function togglePanel() {
    if (Model.hasMethod(root.loadedPanel, "toggle")) Model.invoke(root.loadedPanel, "toggle")
  }

  // Shape contract for shell.summon/hide/toggle routing (Bar.findPanelWidget
  // requires open/close/opened on the bar-widget root). Open maps to the
  // panel's hotkey path so summoning suppresses the center hover reveal,
  // matching what the old per-plugin IpcHandler did.
  readonly property bool opened: root.loadedPanel ? Model.field(root.loadedPanel, "opened") === true : false

  function open() {
    if (Model.hasMethod(root.loadedPanel, "openFromHotkey")) Model.invoke(root.loadedPanel, "openFromHotkey")
  }

  function close() {
    if (Model.hasMethod(root.loadedPanel, "close")) Model.invoke(root.loadedPanel, "close")
  }

  // Forwarded so this widget can stand in for the panel as the bar's popout
  // identity: Bar.requestPopout prefers closeForPopoutSwitch over close, and
  // KeyboardPanel reads popoutSwitchClosing back off its owner.
  readonly property bool popoutSwitchClosing: root.loadedPanel ? Model.field(root.loadedPanel, "popoutSwitchClosing") === true : false

  function closeForPopoutSwitch() {
    if (root.loadedPanel) Model.invoke(root.loadedPanel, "closeForPopoutSwitch")
  }

  visible: root.loadedPanel && Model.field(root.loadedPanel, "label") !== ""
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  BarIconButton {
    id: button
    anchors.left: parent.left
    anchors.right: parent.right
    height: parent.height
    // Windows port: the cloud glyph is centred in its slot but the clock text beside it sits lower
    // (its baseline, not its box, is centred), so the icon read about 3 px high.
    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: Style.space(2)
    bar: root.bar
    text: root.loadedPanel ? Model.field(root.loadedPanel, "label") : ""
    slotSize: Style.bar.statusSlot
    // Tooltip suppressed because the panel is the detail view.
    tooltipText: ""

    onPressed: function(b) {
      if (!root.bar) return
      if (b === Qt.RightButton) BarValues.run(root.bar, "nomarchy-notification-send \"$(nomarchy-weather-status)\"")
      else if (b === Qt.MiddleButton) root.refresh()
      else root.togglePanel()
    }
  }
}
