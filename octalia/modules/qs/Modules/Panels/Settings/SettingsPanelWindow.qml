import QtQuick 6.10
import Quickshell
import qs.Commons
import qs.Services.UI
import "SettingsPanelWindow.js" as SettingsPanelWindowData

FloatingWindow {
  id: root

  title: "Octalia"
  minimumSize: Qt.size(840 * Style.uiScaleRatio, 910 * Style.uiScaleRatio)
  implicitWidth: Math.round(840 * Style.uiScaleRatio)
  implicitHeight: Math.round(910 * Style.uiScaleRatio)
  color: "transparent"

  visible: false

  // Register with SettingsPanelService
  Component.onCompleted: {
    SettingsPanelService.settingsWindow = root;
  }

  property bool isInitialized: false
  property var settingsContentItem: settingsContent

  // Navigate to a specific tab and optional subtab.
  // Works whether the window is already visible or just becoming visible.
  function navigateTo(tab: var, subTab: var): void {
    SettingsPanelWindowData.navigateTo(root.settingsContentItem, root, tab, subTab);
  }

  function navigateToEntry(entry: var): void {
    SettingsPanelWindowData.navigateToEntry(root.settingsContentItem, entry, root);
  }

  // Sync visibility with service
  onVisibleChanged: {
    if (visible) {
      SettingsPanelService.isWindowOpen = true;
    } else {
      isInitialized = false;
      SettingsPanelService.isWindowOpen = false;
    }
  }

  // Keyboard shortcuts
  Shortcut {
    sequence: "Escape"
    enabled: !PanelService.isKeybindRecording
    onActivated: SettingsPanelService.closeWindow()
  }

  Shortcut {
    sequence: "Tab"
    enabled: !PanelService.isKeybindRecording
    onActivated: SettingsPanelWindowData.selectNextTab(root.settingsContentItem)
  }

  Shortcut {
    sequence: "Backtab"
    enabled: !PanelService.isKeybindRecording
    onActivated: SettingsPanelWindowData.selectPreviousTab(root.settingsContentItem)
  }

  Instantiator {
    model: SettingsPanelWindowData.keybindModel(Settings.data.general.keybinds.keyUp || [], root.settingsContentItem)
    Shortcut {
      required property string key
      required property var content
      sequence: key
      enabled: !PanelService.isKeybindRecording
      onActivated: SettingsPanelWindowData.moveSearchSelection(content, true)
    }
  }

  Instantiator {
    model: SettingsPanelWindowData.keybindModel(Settings.data.general.keybinds.keyDown || [], root.settingsContentItem)
    Shortcut {
      required property string key
      required property var content
      sequence: key
      enabled: !PanelService.isKeybindRecording
      onActivated: SettingsPanelWindowData.moveSearchSelection(content, false)
    }
  }

  // Main content
  Rectangle {
    anchors.fill: parent
    color: Qt.alpha(Color.mSurface, Settings.data.ui.panelBackgroundOpacity)
    radius: Style.radiusL

    SettingsContent {
      id: settingsContent
      anchors.fill: parent
      onCloseRequested: SettingsPanelService.closeWindow()
    }
  }
}
