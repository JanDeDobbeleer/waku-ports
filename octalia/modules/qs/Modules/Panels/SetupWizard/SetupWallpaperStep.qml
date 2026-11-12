pragma ComponentBehavior: Bound

import QtQuick 6.10
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell.Io
import qs.Commons
import qs.Services.UI
import qs.Widgets
import "SetupWallpaperStepUtils.js" as SetupWallpaperStepUtils

ColumnLayout {
  id: root

  property string selectedDirectory: ""
  property string selectedWallpaper: ""
  property string previewCachedPath: ""

  signal directoryChanged(string directory)
  signal wallpaperChanged(string wallpaper)

  onSelectedWallpaperChanged: {
    if (!selectedWallpaper) {
      previewCachedPath = "";
      return;
    }
    if (ImageCacheService.initialized) {
      ImageCacheService.getLarge(selectedWallpaper, Screen.width, Screen.height, function (path: string, success: bool) {
        if (root)
          root.previewCachedPath = success ? path : selectedWallpaper;
      });
    } else {
      previewCachedPath = selectedWallpaper;
    }
  }

  spacing: Style.marginL

  // Beautiful header with icon
  ColumnLayout {
    Layout.fillWidth: true
    Layout.bottomMargin: Style.marginL
    spacing: Style.marginM

    RowLayout {
      spacing: Style.marginM

      Rectangle {
        Layout.preferredWidth: 40
        Layout.preferredHeight: 40
        radius: Style.radiusL
        color: Color.mSurfaceVariant
        opacity: 0.6

        NIcon {
          icon: "image"
          pointSize: Style.fontSizeL
          color: Color.mPrimary
          anchors.centerIn: parent
        }
      }

      ColumnLayout {
        spacing: Style.marginXS

        NText {
          text: I18n.tr("setup.wallpaper.header")
          pointSize: Style.fontSizeXL
          font.weight: Style.fontWeightBold
          color: Color.mPrimary
        }

        NText {
          text: I18n.tr("setup.wallpaper.subheader")
          pointSize: Style.fontSizeM
          color: Color.mOnSurfaceVariant
        }
      }
    }
  }

  // Large preview area
  Rectangle {
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.minimumHeight: 180
    color: Color.mSurfaceVariant
    radius: Style.radiusL

    // Image with rounded corners
    NImageRounded {
      anchors.fill: parent
      visible: root.previewCachedPath !== ""
      imagePath: root.previewCachedPath
      radius: Style.radiusL
      borderColor: root.previewCachedPath !== "" ? Color.mPrimary : Color.mOutline
      borderWidth: root.previewCachedPath !== "" ? 2 : 1
      imageFillMode: Image.PreserveAspectCrop
    }

    ColumnLayout {
      anchors.centerIn: parent
      spacing: Style.marginL
      visible: root.selectedWallpaper === ""

      Rectangle {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: 64
        Layout.preferredHeight: 64
        radius: width / 2
        color: Color.mPrimary

        NIcon {
          icon: "sparkles"
          pointSize: Style.fontSizeXXL
          color: Color.mOnPrimary
          anchors.centerIn: parent
        }
      }

      NText {
        text: I18n.tr("setup.wallpaper.select-prompt")
        pointSize: Style.fontSizeL
        color: Color.mOnSurfaceVariant
        Layout.alignment: Qt.AlignHCenter
        font.weight: Style.fontWeightMedium
      }
    }

    Behavior on border.color {
      ColorAnimation {
        duration: Style.animationFast
      }
    }
  }

  // Wallpaper gallery strip
  Item {
    Layout.fillWidth: true
    Layout.preferredHeight: 92
    visible: root.filteredWallpapers.length > 0

    NScrollView {
      id: galleryScroll
      anchors.fill: parent
      horizontalPolicy: ScrollBar.AsNeeded
      verticalPolicy: ScrollBar.AlwaysOff
      showGradientMasks: false
      reserveScrollbarSpace: false

      // Enable vertical mouse wheel to scroll the horizontal strip by moving contentX
      WheelHandler {
        target: galleryScroll.contentItem
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
                   SetupWallpaperStepUtils.scrollHorizontally(galleryScroll.contentItem, event);
                 }
      }

      RowLayout {
        spacing: Style.marginM
        height: parent.height

        Repeater {
          model: root.filteredWallpapers
          delegate: Item {
            required property string modelData
            id: thumbDelegate
            readonly property int baseWidth: 120
            readonly property int baseHeight: 80
            readonly property int thumbRadius: Style.radiusM
            property string cachedPath: ""

            Layout.preferredWidth: baseWidth
            Layout.preferredHeight: baseHeight

            Component.onCompleted: {
              if (ImageCacheService.initialized) {
                ImageCacheService.getThumbnail(thumbDelegate.modelData, function (path: string, success: bool) {
                  if (thumbDelegate)
                    thumbDelegate.cachedPath = success ? path : thumbDelegate.modelData;
                });
              } else {
                cachedPath = thumbDelegate.modelData;
              }
            }

            // Rounded thumbnail using NImageRounded with caching
            NImageRounded {
              id: thumbImage
              anchors.fill: parent
              imagePath: thumbDelegate.cachedPath
              radius: thumbDelegate.thumbRadius
              borderColor: root.selectedWallpaper === thumbDelegate.modelData ? Color.mPrimary : Color.mOutline
              borderWidth: root.selectedWallpaper === thumbDelegate.modelData ? 2 : 1
              imageFillMode: Image.PreserveAspectCrop
            }

            // Loading/error state background
            Rectangle {
              anchors.fill: parent
              color: Color.mSurfaceVariant
              radius: thumbDelegate.thumbRadius
              visible: thumbImage.status === Image.Loading || thumbImage.status === Image.Error || thumbDelegate.cachedPath === ""

              NIcon {
                icon: "image"
                pointSize: Style.fontSizeL
                color: Color.mOnSurfaceVariant
                anchors.centerIn: parent
              }
            }

            NBusyIndicator {
              anchors.centerIn: parent
              visible: thumbImage.status === Image.Loading || thumbDelegate.cachedPath === ""
              running: visible
              size: 18
            }

            // Hover overlay
            Rectangle {
              anchors.fill: parent
              radius: thumbDelegate.thumbRadius
              color: Color.mPrimary
              opacity: hoverHandler.hovered ? 0.1 : 0
              Behavior on opacity {
                NumberAnimation {
                  duration: Style.animationFast
                }
              }
            }

            // Selection badge
            Rectangle {
              visible: root.selectedWallpaper === thumbDelegate.modelData
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              anchors.margins: 6
              width: 24
              height: 24
              radius: width / 2
              color: Color.mPrimary

              NIcon {
                icon: "check"
                pointSize: Style.fontSizeS
                color: Color.mOnPrimary
                anchors.centerIn: parent
              }
            }

            HoverHandler {
              id: hoverHandler
            }

            TapHandler {
              onTapped: {
                root.selectedWallpaper = thumbDelegate.modelData;
                root.wallpaperChanged(thumbDelegate.modelData);
              }
            }
          }
        }
      }
    }
  }

  // Helpful info card
  Rectangle {
    Layout.fillWidth: true
    Layout.preferredHeight: 80
    color: Color.mSurfaceVariant
    radius: Style.radiusM
    opacity: 0.4
    visible: root.filteredWallpapers.length === 0

    RowLayout {
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginM

      NIcon {
        icon: "folder-open"
        pointSize: Style.fontSizeL
        color: Color.mOnSurfaceVariant
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginXS
        NText {
          text: root.filteredWallpapers.length === 0 && root.selectedDirectory !== "" ? I18n.tr("setup.wallpaper.none-in-dir") : I18n.tr("setup.wallpaper.no-dir")
          pointSize: Style.fontSizeM
          font.weight: Style.fontWeightBold
          color: Color.mOnSurfaceVariant
        }
        NText {
          text: root.selectedDirectory !== "" ? I18n.trArgs("setup.wallpaper.no-valid", {
                                                     "dir": root.selectedDirectory
                                                   }) : I18n.tr("setup.wallpaper.choose-dir")
          pointSize: Style.fontSizeS
          color: Color.mOnSurfaceVariant
          wrapMode: Text.WordWrap
          Layout.fillWidth: true
          opacity: 0.8
        }
      }
    }
  }

  // Directory selection
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginM

    NTextInputButton {
      id: wallpaperPathInput
      label: I18n.tr("setup.wallpaper.dir-label")
      description: I18n.tr("setup.wallpaper.dir-description")
      text: root.selectedDirectory
      buttonIcon: "folder-open"
      Layout.fillWidth: true
      onInputTextChanged: text => {
                            root.selectedDirectory = text;
                            root.directoryChanged(text);
                          }
      onButtonClicked: directoryPicker.open()
    }
  }

  // Internal properties and functions
  property list<string> wallpapersList: []
  property list<string> filteredWallpapers: []

  function updateFilteredWallpapers() {
    filteredWallpapers = wallpapersList;
  }

  function refreshWallpapers() {
    var wallpapers;
    if (!selectedDirectory || selectedDirectory === "") {
      wallpapersList = [];
      filteredWallpapers = [];
      return;
    }
    if (typeof WallpaperService !== "undefined" && WallpaperService.getWallpapersList) {
      wallpapers = WallpaperService.getWallpapersList(Screen.name);
      wallpapersList = wallpapers;
      updateFilteredWallpapers();
      if (wallpapersList.length > 0 && selectedWallpaper === "") {
        selectedWallpaper = wallpapersList[0];
      }
    } else {
      readDirectoryImages(selectedDirectory);
    }
  }

  function readDirectoryImages(directoryPath: string): list<string> {
    var i;
    // Build find command args dynamically from ImageCacheService filters
    var filters = ImageCacheService.imageFilters;
    var findArgs = ["find", directoryPath, "-type", "f", "("];
    for (i = 0; i < SetupWallpaperStepUtils.arrayLength(filters); i++) {
      if (i > 0) {
        findArgs.push("-o");
      }
      findArgs.push("-iname");
      findArgs.push(filters[i]);
    }
    findArgs.push(")");
    directoryScanner.command = findArgs;
    directoryScanner.running = true;
    return [];
  }

  onSelectedDirectoryChanged: {
    if (typeof Settings !== "undefined" && Settings.data && Settings.data.wallpaper) {
      Settings.data.wallpaper.directory = selectedDirectory;
    }
    if (typeof WallpaperService !== "undefined" && WallpaperService.refreshWallpapersList) {
      WallpaperService.refreshWallpapersList();
    }
    Qt.callLater(refreshWallpapers);
  }

  Connections {
    target: WallpaperService
    enabled: typeof WallpaperService !== "undefined"
    function onWallpaperListChanged(screenName: string, count: int): void {
      if (screenName === Screen.name) {
        Qt.callLater(root.refreshWallpapers);
      }
    }
  }

  Timer {
    id: initialRefreshTimer
    interval: 1000
    running: false
    repeat: false
    onTriggered: root.refreshWallpapers()
  }

  Component.onCompleted: {
    if (typeof Settings !== "undefined" && Settings.data && Settings.data.wallpaper && Settings.data.wallpaper.directory) {
      selectedDirectory = Settings.data.wallpaper.directory;
    } else {
      selectedDirectory = Settings.defaultWallpapersDirectory;
    }
    if (typeof WallpaperService !== "undefined" && SetupWallpaperStepUtils.field(WallpaperService, "currentWallpaper")) {
      selectedWallpaper = SetupWallpaperStepUtils.field(WallpaperService, "currentWallpaper");
    }
    initialRefreshTimer.start();
  }

  NFilePicker {
    id: directoryPicker
    selectionMode: "folders"
    title: I18n.tr("setup.wallpaper.dir-select-title")
    initialPath: root.selectedDirectory || Settings.defaultWallpapersDirectory
    onAccepted: paths => {
                  if (SetupWallpaperStepUtils.arrayLength(paths) > 0) {
                    root.selectedDirectory = SetupWallpaperStepUtils.arrayAt(paths, 0);
                    root.directoryChanged(SetupWallpaperStepUtils.arrayAt(paths, 0));
                  }
                }
  }

  Process {
    id: directoryScanner
    command: []
    running: false
    stdout: StdioCollector {}
    stderr: StdioCollector {}
    onExited: function (exitCode: int): void {
      if (exitCode === 0) {
        root.wallpapersList = SetupWallpaperStepUtils.imageLines(directoryScanner);
        root.updateFilteredWallpapers();
        if (root.wallpapersList.length > 0 && root.selectedWallpaper === "") {
          root.selectedWallpaper = root.wallpapersList[0];
        }
      }
    }
  }
}
