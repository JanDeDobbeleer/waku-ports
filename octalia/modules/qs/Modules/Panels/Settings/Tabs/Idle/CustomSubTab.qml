import QtQuick 6.10
import QtQuick.Controls.Basic
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "../../SettingsValue.js" as SettingsValue
import "CustomSubTab.js" as CustomData

ColumnLayout {
  id: root
  spacing: Style.marginL
  Layout.fillWidth: true
  enabled: Settings.data.idle.enabled

  property bool _saving: false

  ListModel {
    id: entriesModel
  }

  function _loadToModel(): void {
    CustomData.loadToModel(root, entriesModel, Settings, Logger);
  }

  function _saveFromModel(): void {
    CustomData.saveFromModel(root, entriesModel, Settings);
  }

  function _removeEntry(index: int): void {
    entriesModel.remove(index, 1);
    _saveFromModel();
  }

  Component.onCompleted: Qt.callLater(_loadToModel)

  Connections {
    target: Settings.data.idle
    function onCustomCommandsChanged() {
      root._loadToModel();
    }
  }

  // Shared Edit Popup
  IdleCommandEditPopup {
    id: editPopup
    parent: Overlay.overlay
  }

  function openEdit(index: int, nameVal: string, timeoutVal: int, cmdVal: string, resumeCmdVal: string): void {
    editPopup.editIndex = index;
    editPopup.nameValue = nameVal;
    editPopup.timeoutValue = timeoutVal;
    editPopup.commandValue = cmdVal;
    editPopup.resumeCommandValue = resumeCmdVal;
    editPopup.showName = true;

    CustomData.connectSaved(editPopup, index, entriesModel, root);
    editPopup.open();
  }

  NLabel {
    label: I18n.tr("panels.idle.custom-label")
    description: I18n.tr("panels.idle.custom-description")
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginS
    Layout.bottomMargin: Style.marginS
  }

  Repeater {
    model: entriesModel

    delegate: RowLayout {
      id: entryDelegate
      required property int index
      required property string name
      required property int timeout
      required property string command
      required property string resumeCommand

      spacing: Style.marginM
      Layout.fillWidth: true

      NLabel {
        Layout.fillWidth: true
        label: entryDelegate.name || I18n.tr("panels.idle.custom-entry-unnamed")
        description: I18n.trp("common.second", entryDelegate.timeout)
        labelColor: (entryDelegate.command || entryDelegate.resumeCommand) ? Color.mPrimary : Color.mOnSurface
      }

      NIconButton {
        icon: "settings"
        onClicked: SettingsValue.invokeParent(entryDelegate, "openEdit", entryDelegate.index, entryDelegate.name, entryDelegate.timeout, entryDelegate.command, entryDelegate.resumeCommand)
      }

      NIconButton {
        icon: "trash"
        onClicked: SettingsValue.invokeParent(entryDelegate, "_removeEntry", entryDelegate.index)
      }
    }
  }

  NButton {
    text: I18n.tr("panels.idle.custom-add")
    icon: "add"
    enabled: Settings.data.idle.enabled
    onClicked: {
      root.openEdit(-1, "", 60, "", "");
    }
  }
}
