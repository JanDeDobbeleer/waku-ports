pragma ComponentBehavior: Bound

import QtQuick 6.10
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.Control

ColumnLayout {
  id: root
  enabled: Settings.data.hooks.enabled
  spacing: Style.marginL
  width: parent.width

  // Shared Edit Popup
  HookEditPopup {
    id: editPopup
    parent: Overlay.overlay
  }

  // Helper to open popup
  function openEdit(label, description, placeholder, value, onSave, onTest) {
    editPopup.hookLabel = label;
    editPopup.hookDescription = description;
    editPopup.hookPlaceholder = placeholder;
    editPopup.initialValue = value;

    // Disconnect previous signals
    try {
      editPopup.saved.disconnect(editPopup._savedSlot);
    } catch (e) {}
    try {
      editPopup.test.disconnect(editPopup._testSlot);
    } catch (e) {}

    // Define slots
    editPopup._savedSlot = onSave;
    editPopup._testSlot = onTest;

    // Connect new signals
    editPopup.saved.connect(editPopup._savedSlot);
    editPopup.test.connect(editPopup._testSlot);

    editPopup.open();
  }

  // Startup Hook
  HookRow {
    label: I18n.tr("panels.hooks.octalia-started-label")
    description: I18n.tr("panels.hooks.octalia-started-description")
    value: Settings.data.hooks.startup
    onEditClicked: root.openEdit(label, description, I18n.tr("panels.hooks.octalia-started-placeholder"), value, newValue => {
                              Settings.data.hooks.startup = newValue;
                              Settings.saveImmediate();
                            }, val => {
                              HooksService.executeStartupHook();
                            })
  }

  // Wallpaper Hook
  HookRow {
    label: I18n.tr("panels.hooks.wallpaper-changed-label")
    description: I18n.tr("panels.hooks.wallpaper-changed-description")
    value: Settings.data.hooks.wallpaperChange
    onEditClicked: root.openEdit(label, description, I18n.tr("panels.hooks.wallpaper-changed-placeholder"), value, newValue => {
                              Settings.data.hooks.wallpaperChange = newValue;
                              Settings.saveImmediate();
                            }, val => {
                              if (val)
                              Quickshell.execDetached(["cmd", "/c", val.replace("$1", "test_wallpaper_path").replace("$2", "test_screen").replace("$3", "dark")]);
                            })
  }

  // Theme Hook
  HookRow {
    label: I18n.tr("panels.hooks.theme-changed-label")
    description: I18n.tr("panels.hooks.theme-changed-description")
    value: Settings.data.hooks.darkModeChange
    onEditClicked: root.openEdit(label, description, I18n.tr("panels.hooks.theme-changed-placeholder"), value, newValue => {
                              Settings.data.hooks.darkModeChange = newValue;
                              Settings.saveImmediate();
                            }, val => {
                              if (val)
                              Quickshell.execDetached(["cmd", "/c", val.replace("$1", "true")]);
                            })
  }

  // Performance Mode Enabled Hook
  HookRow {
    label: I18n.tr("panels.hooks.performance-mode-enabled-label")
    description: I18n.tr("panels.hooks.performance-mode-enabled-description")
    value: Settings.data.hooks.performanceModeEnabled
    onEditClicked: root.openEdit(label, description, I18n.tr("panels.hooks.performance-mode-enabled-placeholder"), value, newValue => {
                              Settings.data.hooks.performanceModeEnabled = newValue;
                              Settings.saveImmediate();
                            }, val => {
                              if (val)
                              Quickshell.execDetached(["cmd", "/c", val]);
                            })
  }

  // Performance Mode Disabled Hook
  HookRow {
    label: I18n.tr("panels.hooks.performance-mode-disabled-label")
    description: I18n.tr("panels.hooks.performance-mode-disabled-description")
    value: Settings.data.hooks.performanceModeDisabled
    onEditClicked: root.openEdit(label, description, I18n.tr("panels.hooks.performance-mode-disabled-placeholder"), value, newValue => {
                              Settings.data.hooks.performanceModeDisabled = newValue;
                              Settings.saveImmediate();
                            }, val => {
                              if (val)
                              Quickshell.execDetached(["cmd", "/c", val]);
                            })
  }

  // Session Hook
  HookRow {
    label: I18n.tr("panels.hooks.session-label")
    description: I18n.tr("panels.hooks.session-description")
    value: Settings.data.hooks.session
    onEditClicked: root.openEdit(label, description, I18n.tr("panels.hooks.session-placeholder"), value, newValue => {
                              Settings.data.hooks.session = newValue;
                              Settings.saveImmediate();
                            }, val => {
                              if (val)
                              Quickshell.execDetached(["cmd", "/c", val + " test"]);
                            })
  }
}
