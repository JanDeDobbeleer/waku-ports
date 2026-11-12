import QtQuick 6.10
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "."
import qs.Widgets
import "../../SettingsValue.js" as SettingsValue

ColumnLayout {
  id: root
  spacing: 0

  // Time dropdown options (00:00 .. 23:30)
  ListModel {
    id: timeOptionsModel
  }

  property var screen

  function populateTimeOptions() {
    var h, hh, key, m, mm;
    for (h = 0; h < 24; h++) {
      for (m = 0; m < 60; m += 30) {
        hh = ("0" + h).slice(-2);
        mm = ("0" + m).slice(-2);
        key = hh + ":" + mm;
        timeOptionsModel.append({
                             "key": key,
                             "name": key
                           });
      }
    }
  }

  Component.onCompleted: {
    Qt.callLater(populateTimeOptions);
  }

  // Download popup
  Loader {
    id: downloadPopupLoader
    active: false
    sourceComponent: SchemeDownloader {
      parent: Overlay.overlay
    }

    property bool pendingOpen: false

    function open() {
      pendingOpen = true;
      active = true;
      if (item) {
        SettingsValue.callIfPresent(item, "open");
        pendingOpen = false;
      }
    }

    onItemChanged: {
      if (item && pendingOpen) {
        SettingsValue.callIfPresent(item, "open");
        pendingOpen = false;
      }
    }
  }

  NTabView {
    id: tabView
    currentIndex: 0

    ColorsSubTab {
      screen: root.screen
      timeOptions: timeOptionsModel
      onOpenDownloadPopup: downloadPopupLoader.open()
    }
  }
}
