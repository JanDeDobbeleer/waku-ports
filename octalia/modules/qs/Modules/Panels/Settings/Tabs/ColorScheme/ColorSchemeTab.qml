import QtQuick 6.10
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "."
import qs.Commons
import qs.Services.System
import qs.Services.Theming
import qs.Services.UI
import qs.Widgets

ColumnLayout {
  id: root
  spacing: 0

  // Time dropdown options (00:00 .. 23:30)
  ListModel {
    id: timeOptions
  }

  property var screen

  function populateTimeOptions() {
    var h, hh, key, m, mm;
    for (h = 0; h < 24; h++) {
      for (m = 0; m < 60; m += 30) {
        hh = ("0" + h).slice(-2);
        mm = ("0" + m).slice(-2);
        key = hh + ":" + mm;
        timeOptions.append({
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
        item.open();
        pendingOpen = false;
      }
    }

    onItemChanged: {
      if (item && pendingOpen) {
        item.open();
        pendingOpen = false;
      }
    }
  }

  NTabView {
    id: tabView
    currentIndex: 0

    ColorsSubTab {
      screen: root.screen
      timeOptions: timeOptions
      onOpenDownloadPopup: downloadPopupLoader.open()
    }
  }
}
