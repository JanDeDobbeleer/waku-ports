pragma ComponentBehavior: Bound

import QtQuick 6.10
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.Control
import "HooksListSubTab.js" as HooksListData

ColumnLayout {
  id: root
  enabled: Settings.data.hooks.enabled
  spacing: Style.marginL
  width: parent.width

  HookEditPopup {
    id: editPopup
    parent: Overlay.overlay
  }

  function openEdit(label: string, description: string, placeholder: string, value: string, onSave: var, onTest: var): void {
    editPopup.hookLabel = label;
    editPopup.hookDescription = description;
    editPopup.hookPlaceholder = placeholder;
    editPopup.initialValue = value;
    HooksListData.setPopupCallbacks(editPopup, onSave, onTest);
    editPopup.open();
  }

  function save_startup(newValue: string): void {
    Settings.data.hooks.startup = newValue;
    Settings.saveImmediate();
  }

  function test_startup(value: string): void {
    HooksService.executeStartupHook();
  }

  function save_wallpaperChange(newValue: string): void {
    Settings.data.hooks.wallpaperChange = newValue;
    Settings.saveImmediate();
  }

  function test_wallpaperChange(value: string): void {
    if (value) Quickshell.execDetached(["cmd", "/c", value.replace("$1", "test_wallpaper_path").replace("$2", "test_screen").replace("$3", "dark")]);
  }

  function save_darkModeChange(newValue: string): void {
    Settings.data.hooks.darkModeChange = newValue;
    Settings.saveImmediate();
  }

  function test_darkModeChange(value: string): void {
    if (value) Quickshell.execDetached(["cmd", "/c", value.replace("$1", "true")]);
  }

  function save_performanceModeEnabled(newValue: string): void {
    Settings.data.hooks.performanceModeEnabled = newValue;
    Settings.saveImmediate();
  }

  function test_performanceModeEnabled(value: string): void {
    if (value) Quickshell.execDetached(["cmd", "/c", value]);
  }

  function save_performanceModeDisabled(newValue: string): void {
    Settings.data.hooks.performanceModeDisabled = newValue;
    Settings.saveImmediate();
  }

  function test_performanceModeDisabled(value: string): void {
    if (value) Quickshell.execDetached(["cmd", "/c", value]);
  }

  function save_session(newValue: string): void {
    Settings.data.hooks.session = newValue;
    Settings.saveImmediate();
  }

  function test_session(value: string): void {
    if (value) Quickshell.execDetached(["cmd", "/c", value + " test"]);
  }

  HookRow {
    label: I18n.tr("panels.hooks.octalia-started-label")
    description: I18n.tr("panels.hooks.octalia-started-description")
    value: Settings.data.hooks.startup
    onEditClicked: root.openEdit(label, description, I18n.tr("panels.hooks.octalia-started-placeholder"), value, root.save_startup, root.test_startup)
  }

  HookRow {
    label: I18n.tr("panels.hooks.wallpaper-changed-label")
    description: I18n.tr("panels.hooks.wallpaper-changed-description")
    value: Settings.data.hooks.wallpaperChange
    onEditClicked: root.openEdit(label, description, I18n.tr("panels.hooks.wallpaper-changed-placeholder"), value, root.save_wallpaperChange, root.test_wallpaperChange)
  }

  HookRow {
    label: I18n.tr("panels.hooks.theme-changed-label")
    description: I18n.tr("panels.hooks.theme-changed-description")
    value: Settings.data.hooks.darkModeChange
    onEditClicked: root.openEdit(label, description, I18n.tr("panels.hooks.theme-changed-placeholder"), value, root.save_darkModeChange, root.test_darkModeChange)
  }

  HookRow {
    label: I18n.tr("panels.hooks.performance-mode-enabled-label")
    description: I18n.tr("panels.hooks.performance-mode-enabled-description")
    value: Settings.data.hooks.performanceModeEnabled
    onEditClicked: root.openEdit(label, description, I18n.tr("panels.hooks.performance-mode-enabled-placeholder"), value, root.save_performanceModeEnabled, root.test_performanceModeEnabled)
  }

  HookRow {
    label: I18n.tr("panels.hooks.performance-mode-disabled-label")
    description: I18n.tr("panels.hooks.performance-mode-disabled-description")
    value: Settings.data.hooks.performanceModeDisabled
    onEditClicked: root.openEdit(label, description, I18n.tr("panels.hooks.performance-mode-disabled-placeholder"), value, root.save_performanceModeDisabled, root.test_performanceModeDisabled)
  }

  HookRow {
    label: I18n.tr("panels.hooks.session-label")
    description: I18n.tr("panels.hooks.session-description")
    value: Settings.data.hooks.session
    onEditClicked: root.openEdit(label, description, I18n.tr("panels.hooks.session-placeholder"), value, root.save_session, root.test_session)
  }
}
