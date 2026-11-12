import QtQuick 6.10
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import "../../SettingsValue.js" as SettingsValue

ColumnLayout {
  id: root
  spacing: 0

  // Helper functions to update arrays immutably
  function addMonitor(list: var, name: string): var { return SettingsValue.addUniqueValue(list, name); }
  function removeMonitor(list: var, name: string): var { return SettingsValue.removeValue(list, name); }

  // File pickers for sound sub-tab
  function openUnifiedSoundPicker() {
    unifiedSoundFilePicker.open();
  }
  function openLowSoundPicker() {
    lowSoundFilePicker.open();
  }
  function openNormalSoundPicker() {
    normalSoundFilePicker.open();
  }
  function openCriticalSoundPicker() {
    criticalSoundFilePicker.open();
  }

  NTabBar {
    id: subTabBar
    Layout.fillWidth: true
    Layout.bottomMargin: Style.marginM
    distributeEvenly: false // this is too cramped on this tab to split evenly
    currentIndex: tabView.currentIndex

    NTabButton {
      text: I18n.tr("common.appearance")
      tabIndex: 0
      checked: subTabBar.currentIndex === 0
    }
    NTabButton {
      text: I18n.tr("common.duration")
      tabIndex: 1
      checked: subTabBar.currentIndex === 1
    }
    NTabButton {
      text: I18n.tr("common.history")
      tabIndex: 2
      checked: subTabBar.currentIndex === 2
    }
    NTabButton {
      text: I18n.tr("common.sound")
      tabIndex: 3
      checked: subTabBar.currentIndex === 3
    }
    NTabButton {
      text: I18n.tr("common.toast")
      tabIndex: 4
      checked: subTabBar.currentIndex === 4
    }
    NTabButton {
      text: I18n.tr("panels.notifications.rules-tab")
      tabIndex: 5
      checked: subTabBar.currentIndex === 5
    }
  }

  Item {
    Layout.fillWidth: true
    Layout.preferredHeight: Style.marginL
  }

  NTabView {
    id: tabView
    currentIndex: subTabBar.currentIndex

    GeneralSubTab {
      addMonitor: root.addMonitor
      removeMonitor: root.removeMonitor
    }
    DurationSubTab {}
    HistorySubTab {}
    SoundSubTab {
      onOpenUnifiedPicker: root.openUnifiedSoundPicker()
      onOpenLowPicker: root.openLowSoundPicker()
      onOpenNormalPicker: root.openNormalSoundPicker()
      onOpenCriticalPicker: root.openCriticalSoundPicker()
    }
    ToastSubTab {}
    RulesSubTab {}
  }

  // File Pickers for Sound Files
  NFilePicker {
    id: unifiedSoundFilePicker
    title: I18n.tr("panels.notifications.sounds-files-unified-select-title")
    selectionMode: "files"
    initialPath: Quickshell.env("USERPROFILE") || Quickshell.env("HOME")
    nameFilters: ["*.wav", "*.mp3", "*.ogg", "*.flac", "*.m4a", "*.aac"]
    onAccepted: paths => SettingsValue.applySelectedPaths(paths, Settings.data.notifications.sounds, ["normalSoundFile", "lowSoundFile", "criticalSoundFile"])
  }

  NFilePicker {
    id: lowSoundFilePicker
    title: I18n.tr("panels.notifications.sounds-files-low-select-title")
    selectionMode: "files"
    initialPath: Quickshell.env("USERPROFILE") || Quickshell.env("HOME")
    nameFilters: ["*.wav", "*.mp3", "*.ogg", "*.flac", "*.m4a", "*.aac"]
    onAccepted: paths => SettingsValue.applySelectedPaths(paths, Settings.data.notifications.sounds, ["lowSoundFile"])
  }

  NFilePicker {
    id: normalSoundFilePicker
    title: I18n.tr("panels.notifications.sounds-files-normal-select-title")
    selectionMode: "files"
    initialPath: Quickshell.env("USERPROFILE") || Quickshell.env("HOME")
    nameFilters: ["*.wav", "*.mp3", "*.ogg", "*.flac", "*.m4a", "*.aac"]
    onAccepted: paths => SettingsValue.applySelectedPaths(paths, Settings.data.notifications.sounds, ["normalSoundFile"])
  }

  NFilePicker {
    id: criticalSoundFilePicker
    title: I18n.tr("panels.notifications.sounds-files-critical-select-title")
    selectionMode: "files"
    initialPath: Quickshell.env("USERPROFILE") || Quickshell.env("HOME")
    nameFilters: ["*.wav", "*.mp3", "*.ogg", "*.flac", "*.m4a", "*.aac"]
    onAccepted: paths => SettingsValue.applySelectedPaths(paths, Settings.data.notifications.sounds, ["criticalSoundFile"])
  }
}
