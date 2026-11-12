import QtQuick 6.10
import QtQuick.Controls.Basic
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import qs.compat
import "SessionMenuTab.js" as SessionMenuData

ColumnLayout {
  id: root
  spacing: 0

  property var _activeDialog: null
  property list<var> entriesModel: []
  property list<var> entriesDefault: [
    {
      "id": "lock",
      "text": I18n.tr("common.lock"),
      "enabled": true,
      "required": false
    },
    {
      "id": "suspend",
      "text": I18n.tr("common.suspend"),
      "enabled": true,
      "required": false
    },
    {
      "id": "hibernate",
      "text": I18n.tr("common.hibernate"),
      "enabled": true,
      "required": false
    },
    {
      "id": "reboot",
      "text": I18n.tr("common.reboot"),
      "enabled": true,
      "required": false
    },
    {
      "id": "rebootToUefi",
      "text": I18n.tr("common.reboot-to-uefi"),
      "enabled": true,
      "required": false
    },
    {
      "id": "logout",
      "text": I18n.tr("common.logout"),
      "enabled": true,
      "required": false
    },
    {
      "id": "shutdown",
      "text": I18n.tr("common.shutdown"),
      "enabled": true,
      "required": false
    }
  ]

  function saveEntries(): void {
    const result = SessionMenuData.saveEntries(entriesModel);
    entriesModel = result.model;
    Settings.data.sessionMenu.powerOptions = result.settings;
  }

  function updateEntry(idx: int, properties: var): void {
    entriesModel = SessionMenuData.updateEntry(entriesModel, idx, properties);
    saveEntries();
  }

  function reorderEntries(fromIndex: int, toIndex: int): void {
    entriesModel = SessionMenuData.reorderEntries(entriesModel, fromIndex, toIndex);
    saveEntries();
  }

  Component.onDestruction: SessionMenuData.closeActiveDialog(root)

  function openEntrySettingsDialog(index: int): void {
    SessionMenuData.openEntrySettingsDialog(root, index, entriesModel, ShellUrl.dir, Overlay.overlay, Logger, Component.Ready, Component.Error);
  }

  Component.onCompleted: {
    entriesModel = SessionMenuData.initializeEntries(Settings.data.sessionMenu.powerOptions, entriesDefault);
    saveEntries();
  }

  NTabBar {
    id: subTabBar
    Layout.fillWidth: true
    Layout.bottomMargin: Style.marginM
    distributeEvenly: true
    currentIndex: tabView.currentIndex

    NTabButton {
      text: I18n.tr("common.general")
      tabIndex: 0
      checked: subTabBar.currentIndex === 0
    }
    NTabButton {
      text: I18n.tr("common.actions")
      tabIndex: 1
      checked: subTabBar.currentIndex === 1
    }
  }

  Item {
    Layout.fillWidth: true
    Layout.preferredHeight: Style.marginL
  }

  NTabView {
    id: tabView
    currentIndex: subTabBar.currentIndex

    GeneralSubTab {}
    ActionsSubTab {
      entriesModel: root.entriesModel
      updateEntry: root.updateEntry
      reorderEntries: root.reorderEntries
      openEntrySettingsDialog: root.openEntrySettingsDialog
    }
  }
}
