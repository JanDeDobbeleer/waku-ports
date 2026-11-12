import QtQuick
import qs.Commons
import qs.Ui
import "." as Local

BarWidget {
  id: root
  moduleName: "nomarchy.weather"

  readonly property Local.Panel loadedPanel: panelLoader.item as Local.Panel

  function injectPanel() {
    var target = root.loadedPanel
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
  }

  function refresh() {
    if (root.loadedPanel && root.loadedPanel.refresh) root.loadedPanel.refresh()
  }

  function togglePanel() {
    if (root.loadedPanel && root.loadedPanel.toggle) root.loadedPanel.toggle()
  }

  // Shape contract for shell.summon/hide/toggle routing (Bar.findPanelWidget
  // requires open/close/opened on the bar-widget root). Open maps to the
  // panel's hotkey path so summoning suppresses the center hover reveal,
  // matching what the old per-plugin IpcHandler did.
  readonly property bool opened: root.loadedPanel ? root.loadedPanel.opened === true : false

  function open() {
    if (root.loadedPanel && root.loadedPanel.openFromHotkey) root.loadedPanel.openFromHotkey()
  }

  function close() {
    if (root.loadedPanel && root.loadedPanel.close) root.loadedPanel.close()
  }

  // Forwarded so this widget can stand in for the panel as the bar's popout
  // identity: Bar.requestPopout prefers closeForPopoutSwitch over close, and
  // KeyboardPanel reads popoutSwitchClosing back off its owner.
  readonly property bool popoutSwitchClosing: root.loadedPanel ? root.loadedPanel.popoutSwitchClosing === true : false

  function closeForPopoutSwitch() {
    if (root.loadedPanel) root.loadedPanel.closeForPopoutSwitch()
  }

  visible: root.loadedPanel && root.loadedPanel.label !== ""
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
    text: root.loadedPanel ? root.loadedPanel.label : ""
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
