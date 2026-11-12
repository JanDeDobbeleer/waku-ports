pragma ComponentBehavior: Bound

import "NFilePickerUtils.js" as FilePickerUtils
import Qt.labs.folderlistmodel
import QtQuick 6.10
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

Popup {
  id: root

  // Properties
  property string title: I18n.tr("widget.file-picker.title")
  property string initialPath: Quickshell.env("HOME") || "/home"
  property string selectionMode: "files" // "files" or "folders"
  property var nameFilters: ["*"]
  property bool showDirs: true
  property bool showHiddenFiles: false
  property bool allowMultiSelection: false

  property var selectedPaths: []
  property string currentPath: initialPath
  property bool shouldResetSelection: false

  // Signals
  signal accepted(var paths)
  signal cancelled

  // Path <-> file URL, Windows-aware ("D:\a\b" <-> "file:///D:/a/b")
  function toFileUrl(path: var): string {
    const p = String(path || "").replace(/\\/g, "/");
    return /^[A-Za-z]:/.test(p) ? "file:///" + p : "file://" + p;
  }
  function fromFileUrl(url: var): string {
    return String(url).replace(/^file:\/\/\/([A-Za-z]:)/, "$1").replace(/^file:\/\//, "");
  }

  // Point the folder view at currentPath (the folder binding breaks after the first manual navigation)
  function syncFolder() {
    if (typeof folderModel !== "undefined")
      folderModel.folder = toFileUrl(root.currentPath);
  }

  onAboutToShow: {
    root.currentPath = root.initialPath;
    syncFolder();
  }

  function openFilePicker() {
    if (!root.currentPath)
      root.currentPath = root.initialPath;
    shouldResetSelection = true;
    open();
  }

  function getFileIcon(fileName: var): var {
    const ext = fileName.split('.').pop().toLowerCase();
    const iconMap = {
      "txt": 'filepicker-file-text',
      "md": 'filepicker-file-text',
      "log": 'filepicker-file-text',
      "jpg": 'filepicker-photo',
      "jpeg": 'filepicker-photo',
      "png": 'filepicker-photo',
      "gif": 'filepicker-photo',
      "bmp": 'filepicker-photo',
      "svg": 'filepicker-photo',
      "mp4": 'filepicker-video',
      "avi": 'filepicker-video',
      "mkv": 'filepicker-video',
      "mov": 'filepicker-video',
      "mp3": 'filepicker-music',
      "wav": 'filepicker-music',
      "flac": 'filepicker-music',
      "ogg": 'filepicker-music',
      "zip": 'filepicker-archive',
      "tar": 'filepicker-archive',
      "gz": 'filepicker-archive',
      "rar": 'filepicker-archive',
      "7z": 'filepicker-archive',
      "pdf": 'filepicker-text',
      "doc": 'filepicker-text',
      "docx": 'filepicker-text',
      "xls": 'filepicker-table',
      "xlsx": 'filepicker-table',
      "ppt": 'filepicker-presentation',
      "pptx": 'filepicker-presentation',
      "html": 'filepicker-code',
      "htm": 'filepicker-code',
      "css": 'filepicker-code',
      "js": 'filepicker-code',
      "json": 'filepicker-code',
      "xml": 'filepicker-code',
      "exe": 'filepicker-settings',
      "app": 'filepicker-settings',
      "deb": 'filepicker-settings',
      "rpm": 'filepicker-settings'
    };
    return iconMap[ext] || 'filepicker-file';
  }

  function formatFileSize(bytes: var): string {
    if (bytes === 0)
      return "0 B";
    const k = 1024, sizes = ["B", "KB", "MB", "GB", "TB"];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + " " + sizes[i];
  }

  function confirmSelection() {
    if (FilePickerUtils.selectionCount(filePickerPanel.currentSelection) === 0)
      return;
    root.selectedPaths = filePickerPanel.currentSelection;
    root.accepted(filePickerPanel.currentSelection);
    root.close();
  }

  function updateFilteredModel() {
    var i;
    filteredModel.clear();
    const searchText = filePickerPanel.filterText.toLowerCase();

    for (i = 0; i < folderModel.count; i++) {
      const fileName = folderModel.get(i, "fileName");
      const filePath = folderModel.get(i, "filePath");
      const fileIsDir = folderModel.get(i, "fileIsDir");
      const fileSize = folderModel.get(i, "fileSize");

      // Skip hidden items if showHiddenFiles is false
      // This additional check ensures hidden files are properly filtered
      if (!root.showHiddenFiles && fileName.startsWith(".")) {
        continue;
      }

      // In folder mode, hide files
      if (root.selectionMode === "folders" && !fileIsDir)
        continue;
      if (searchText === "" || fileName.toLowerCase().includes(searchText)) {
        filteredModel.append({
                               "fileName": fileName,
                               "filePath": filePath,
                               "fileIsDir": fileIsDir,
                               "fileSize": fileSize
                             });
      }
    }
  }

  width: 900
  height: 700
  modal: true
  closePolicy: Popup.CloseOnEscape
  anchors.centerIn: Overlay.overlay

  background: Rectangle {
    color: Color.mSurfaceVariant
    radius: Style.iRadiusL
    border.color: Color.mOutline
    border.width: Style.borderS
  }

  Rectangle {
    id: filePickerPanel
    anchors.fill: parent
    anchors.margins: Style.marginL
    color: "transparent"

    property string filterText: ""
    property var currentSelection: []
    property bool viewMode: true // true = grid, false = list
    property string searchText: ""
    property bool showSearchBar: false

    focus: true

    Keys.onPressed: event => {
                      if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_F) {
                        filePickerPanel.showSearchBar = !filePickerPanel.showSearchBar;
                        if (filePickerPanel.showSearchBar)
                        Qt.callLater(() => searchInput.forceActiveFocus());
                        event.accepted = true;
                      } else if (event.key === Qt.Key_Escape && filePickerPanel.showSearchBar) {
                        filePickerPanel.showSearchBar = false;
                        filePickerPanel.searchText = "";
                        filePickerPanel.filterText = "";
                        root.updateFilteredModel();
                        event.accepted = true;
                      }
                    }

    // Function when an item is clicked, either a folder or a file since both have the same functionality, reduces repetitive code
    function itemClicked(modifiers: var, path: var): void {
      var i, toggle;
      var list = currentSelection.slice();
      const index = list.indexOf(path);
      if (root.allowMultiSelection && (modifiers & Qt.ShiftModifier) && list.length > 0) {
        if (index > -1) {
          list.splice(index, 1);
          currentSelection = list;
        } else {
          i = 0;
          toggle = false;
          const firstItemPath = list[0];
          while (i < filteredModel.count) {
            const itemPath = filteredModel.get(i).filePath;

            // This should be called twice, when we get to the item selected and when we get to the starting item.
            if (itemPath === firstItemPath || itemPath === path) {
              toggle = !toggle;
            }

            // Add all files between the starting item and the item selected.
            if (toggle) {
              if (!list.includes(itemPath)) {
                list.push(itemPath);
              }
            }

            i++;
          }

          // Add the path selected as well since it's skipped in the while loop
          if (!list.includes(path)) {
            list.push(path);
          }
          currentSelection = list;
        }
      } else if (root.allowMultiSelection && (modifiers & Qt.ControlModifier)) {
        if (index > -1) {
          list.splice(index, 1);
          currentSelection = list;
        } else {
          list.push(path);
          currentSelection = list;
        }
      } else {
        currentSelection = [path];
      }
    }

    ColumnLayout {
      anchors.fill: parent
      spacing: Style.marginM

      // Header
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        NIcon {
          icon: "filepicker-folder"
          color: Color.mPrimary
          pointSize: Style.fontSizeXXL
        }
        NText {
          text: root.title
          pointSize: Style.fontSizeXL
          font.weight: Style.fontWeightBold
          color: Color.mPrimary
          Layout.fillWidth: true
        }

        // "Select Current" button only visible in folder selection mode
        NButton {
          text: I18n.tr("widgets.file-picker.select-current")
          icon: "filepicker-folder-current"
          visible: root.selectionMode === "folders"
          onClicked: {
            filePickerPanel.currentSelection = [root.currentPath];
            root.confirmSelection();
          }
        }

        NIconButton {
          icon: "filepicker-refresh"
          onClicked: {
            // Force a proper refresh by resetting the folder
            const currentFolder = folderModel.folder;
            folderModel.folder = "";
            folderModel.folder = currentFolder;
            Qt.callLater(root.updateFilteredModel);
          }
        }
        NIconButton {
          icon: "filepicker-close"
          onClicked: {
            root.cancelled();
            root.close();
          }
        }
      }

      NDivider {
        Layout.fillWidth: true
      }

      // Navigation toolbar
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 45
        color: Color.mSurfaceVariant
        radius: Style.iRadiusS
        border.color: Color.mOutline
        border.width: Style.borderS

        RowLayout {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          anchors.leftMargin: Style.marginS
          anchors.rightMargin: Style.marginS
          spacing: Style.marginS

          NIconButton {
            icon: "filepicker-arrow-up"
            baseSize: Style.baseWidgetSize * 0.8
            enabled: folderModel.folder.toString() !== "file:///"
            onClicked: {
              const parentPath = root.fromFileUrl(folderModel.parentFolder);
              folderModel.folder = root.toFileUrl(parentPath);
              root.currentPath = parentPath;
            }
          }

          NIconButton {
            icon: "filepicker-home"
            baseSize: Style.baseWidgetSize * 0.8
            onClicked: {
              const homePath = Quickshell.env("HOME") || "/home";
              folderModel.folder = root.toFileUrl(homePath);
              root.currentPath = homePath;
            }
          }

          NIconButton {
            icon: filePickerPanel.showSearchBar ? "filepicker-x" : "filepicker-search"
            baseSize: Style.baseWidgetSize * 0.8
            onClicked: {
              filePickerPanel.showSearchBar = !filePickerPanel.showSearchBar;
              if (!filePickerPanel.showSearchBar) {
                filePickerPanel.searchText = "";
                filePickerPanel.filterText = "";
                root.updateFilteredModel();
              }
            }
          }

          NTextInput {
            id: locationInput
            text: root.currentPath
            placeholderText: I18n.tr("placeholders.enter-path")
            Layout.fillWidth: true

            visible: !filePickerPanel.showSearchBar
            enabled: !filePickerPanel.showSearchBar

            onEditingFinished: {
              const newPath = text.trim();
              if (newPath !== "" && newPath !== root.currentPath) {
                folderModel.folder = root.toFileUrl(newPath);
                root.currentPath = newPath;
              } else {
                text = root.currentPath;
              }
            }
            Connections {
              target: root
              function onCurrentPathChanged() {
                if (!locationInput.activeFocus)
                  locationInput.text = root.currentPath;
              }
            }
          }

          // Search bar
          NTextInput {
            id: searchInput
            inputIconName: "search"
            placeholderText: I18n.tr("placeholders.search")
            Layout.fillWidth: true

            visible: filePickerPanel.showSearchBar
            enabled: filePickerPanel.showSearchBar

            text: filePickerPanel.searchText
            onTextChanged: {
              filePickerPanel.searchText = text;
              filePickerPanel.filterText = text;
              root.updateFilteredModel();
            }
            Keys.onEscapePressed: {
              filePickerPanel.showSearchBar = false;
              filePickerPanel.searchText = "";
              filePickerPanel.filterText = "";
              root.updateFilteredModel();
            }
          }

          NIconButton {
            icon: filePickerPanel.viewMode ? "filepicker-list" : "filepicker-layout-grid"
            baseSize: Style.baseWidgetSize * 0.8
            onClicked: filePickerPanel.viewMode = !filePickerPanel.viewMode
          }
          NIconButton {
            icon: root.showHiddenFiles ? "filepicker-eye-off" : "filepicker-eye"
            baseSize: Style.baseWidgetSize * 0.8
            onClicked: {
              root.showHiddenFiles = !root.showHiddenFiles;
              // Force model refresh by resetting the folder
              const currentFolder = folderModel.folder;
              folderModel.folder = "";
              folderModel.folder = currentFolder;
              Qt.callLater(root.updateFilteredModel);
            }
          }
        }
      }

      // File list area
      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: Color.mSurface
        radius: Style.iRadiusM
        border.color: Color.mOutline
        border.width: Style.borderS

        FolderListModel {
          id: folderModel
          folder: root.toFileUrl(root.currentPath)
          // Use wildcard filters including hidden files when showHiddenFiles is true
          nameFilters: root.showHiddenFiles ? ["*", ".*"] : root.nameFilters
          showDirs: root.showDirs
          showHidden: true // Always true, we'll filter in updateFilteredModel
          showDotAndDotDot: false
          sortField: FolderListModel.Name
          sortReversed: false

          onFolderChanged: {
            root.currentPath = root.fromFileUrl(folder);
            filePickerPanel.currentSelection = [];
            Qt.callLater(root.updateFilteredModel);
          }

          onStatusChanged: {
            if (status === FolderListModel.Ready) {
              root.updateFilteredModel();
            }
          }
        }

        // Update nameFilters when showHiddenFiles changes
        Connections {
          target: root
          function onShowHiddenFilesChanged() {
            folderModel.nameFilters = root.showHiddenFiles ? ["*", ".*"] : root.nameFilters;
          }
        }

        ListModel {
          id: filteredModel
        }

        // Grid view
        NGridView {
          id: gridView
          anchors.fill: parent
          anchors.margins: Style.marginM
          model: filteredModel
          visible: filePickerPanel.viewMode
          reuseItems: true
          gradientColor: Color.mSurface

          property int columns: Math.max(1, Math.floor(availableWidth / 120))
          property int itemSize: Math.floor((availableWidth - leftMargin - rightMargin - (columns * Style.marginS)) / columns)

          cellWidth: Math.floor((availableWidth - leftMargin - rightMargin) / columns)
          cellHeight: Math.floor(itemSize * 0.8) + Style.marginXS + Style.fontSizeS + Style.marginM

          leftMargin: Style.marginS
          rightMargin: Style.marginS
          topMargin: Style.marginS
          bottomMargin: Style.marginS

          delegate: Rectangle {
            id: gridItem
            required property string fileName
            required property string filePath
            required property bool fileIsDir
            width: gridView.itemSize
            height: gridView.cellHeight
            color: "transparent"
            radius: Style.iRadiusM

            property bool isSelected: filePickerPanel.currentSelection.includes(gridItem.filePath)

            Rectangle {
              anchors.fill: parent
              color: "transparent"
              radius: gridItem.radius
              border.color: gridItem.isSelected ? Color.mSecondary : Color.mSurface
              border.width: Style.borderL
              Behavior on color {
                ColorAnimation {
                  duration: Style.animationFast
                }
              }
            }

            Rectangle {
              anchors.fill: parent
              color: (mouseArea.containsMouse && !gridItem.isSelected) ? Color.mHover : "transparent"
              radius: gridItem.radius
              border.color: (mouseArea.containsMouse && !gridItem.isSelected) ? Color.mHover : "transparent"
              border.width: Style.borderS
              Behavior on color {
                ColorAnimation {
                  duration: Style.animationFast
                }
              }
              Behavior on border.color {
                ColorAnimation {
                  duration: Style.animationFast
                }
              }
            }

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: Style.marginS
              spacing: Style.marginXS

              Rectangle {
                id: iconContainer
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(gridView.itemSize * 0.67)
                color: "transparent"

                property bool isImage: {
                  if (gridItem.fileIsDir)
                    return false;
                  const ext = gridItem.fileName.split('.').pop().toLowerCase();
                  return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg', 'ico'].includes(ext);
                }

                Image {
                  id: thumbnail
                  anchors.fill: parent
                  anchors.margins: Style.marginXS
                  source: iconContainer.isImage ? root.toFileUrl(gridItem.filePath) : ""
                  fillMode: Image.PreserveAspectFit
                  visible: iconContainer.isImage && status === Image.Ready
                  smooth: false
                  cache: true
                  asynchronous: true
                  sourceSize.width: 120
                  sourceSize.height: 120
                  onStatusChanged: {
                    if (status === Image.Error)
                      visible = false;
                  }

                  Rectangle {
                    anchors.fill: parent
                    color: Color.mSurfaceVariant
                    radius: Style.iRadiusS
                    visible: thumbnail.status === Image.Loading
                    NIcon {
                      icon: "filepicker-photo"
                      pointSize: Style.fontSizeL
                      color: Color.mOnSurfaceVariant
                      anchors.centerIn: parent
                    }
                  }
                }

                NIcon {
                  icon: gridItem.fileIsDir ? "filepicker-folder" : root.getFileIcon(gridItem.fileName)
                  pointSize: Style.fontSizeXXL * 2
                  color: {
                    if (gridItem.isSelected)
                      return Color.mSecondary;
                    else if (mouseArea.containsMouse)
                      return Color.mOnHover;
                    else
                      return gridItem.fileIsDir ? Color.mPrimary : Color.mOnSurfaceVariant;
                  }
                  anchors.centerIn: parent
                  visible: !iconContainer.isImage || thumbnail.status !== Image.Ready
                }

                Rectangle {
                  anchors.top: parent.top
                  anchors.right: parent.right
                  anchors.margins: Style.marginS
                  width: 24
                  height: 24
                  radius: Math.min(Style.iRadiusL, width / 2)
                  color: Color.mSecondary
                  border.color: Color.mOutline
                  border.width: Style.borderS
                  visible: gridItem.isSelected
                  NIcon {
                    icon: "filepicker-check"
                    pointSize: Style.fontSizeS
                    color: Color.mOnSecondary
                    anchors.centerIn: parent
                  }
                }
              }

              NText {
                text: gridItem.fileName
                color: {
                  if (gridItem.isSelected)
                    return Color.mSecondary;
                  else if (mouseArea.containsMouse)
                    return Color.mOnHover;
                  else
                    return Color.mOnSurfaceVariant;
                }
                pointSize: Style.fontSizeS
                font.weight: gridItem.isSelected ? Style.fontWeightBold : Style.fontWeightRegular
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WrapAnywhere
                elide: Text.ElideRight
                maximumLineCount: 2
              }
            }

            MouseArea {
              id: mouseArea
              anchors.fill: parent
              hoverEnabled: true
              acceptedButtons: Qt.LeftButton | Qt.RightButton

              onClicked: mouse => {
                           if (mouse.button === Qt.LeftButton) {
                             if (gridItem.fileIsDir) {
                               // In folder mode, single click selects the folder
                               if (root.selectionMode === "folders") {
                                 filePickerPanel.itemClicked(mouse.modifiers, gridItem.filePath);
                               }
                               // In file mode, single click on folder does nothing (must double-click to enter)
                             } else {
                               // Single click on file selects it (only in file mode)
                               if (root.selectionMode === "files") {
                                 filePickerPanel.itemClicked(mouse.modifiers, gridItem.filePath);
                               }
                             }
                           }
                         }

              onDoubleClicked: mouse => {
                                 if (mouse.button === Qt.LeftButton) {
                                   if (gridItem.fileIsDir) {
                                     // Double-click on folder always navigates into it
                                     folderModel.folder = root.toFileUrl(gridItem.filePath);
                                     root.currentPath = gridItem.filePath;
                                   } else {
                                     // Double-click on file selects and confirms (only in file mode)
                                     if (root.selectionMode === "files") {
                                       filePickerPanel.currentSelection = [gridItem.filePath];
                                       root.confirmSelection();
                                     }
                                   }
                                 }
                               }
            }
          }
        }

        // List view
        NListView {
          id: listView
          anchors.fill: parent
          anchors.margins: Style.marginS
          model: filteredModel
          visible: !filePickerPanel.viewMode
          gradientColor: Color.mSurface

          delegate: Rectangle {
            id: listItem
            required property string fileName
            required property string filePath
            required property bool fileIsDir
            required property var fileSize
            width: listView.width
            height: 40
            color: {
              if (filePickerPanel.currentSelection.includes(listItem.filePath))
                return Color.mSecondary;
              if (listMouseArea.containsMouse)
                return Color.mHover;
              return "transparent";
            }
            radius: Style.iRadiusS
            Behavior on color {
              ColorAnimation {
                duration: Style.animationFast
              }
            }

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: Style.marginM
              anchors.rightMargin: Style.marginM
              spacing: Style.marginM

              NIcon {
                icon: listItem.fileIsDir ? "filepicker-folder" : root.getFileIcon(listItem.fileName)
                pointSize: Style.fontSizeL
                color: listItem.fileIsDir ? (filePickerPanel.currentSelection.includes(listItem.filePath) ? Color.mOnSecondary : Color.mPrimary) : Color.mOnSurfaceVariant
              }

              NText {
                text: listItem.fileName
                color: filePickerPanel.currentSelection.includes(listItem.filePath) ? Color.mOnSecondary : Color.mOnSurface
                pointSize: Style.fontSizeM
                font.weight: filePickerPanel.currentSelection.includes(listItem.filePath) ? Style.fontWeightBold : Style.fontWeightRegular
                Layout.fillWidth: true
                elide: Text.ElideRight
              }

              NText {
                text: listItem.fileIsDir ? "" : root.formatFileSize(listItem.fileSize)
                color: filePickerPanel.currentSelection.includes(listItem.filePath) ? Color.mOnSecondary : Color.mOnSurfaceVariant
                pointSize: Style.fontSizeS
                visible: !listItem.fileIsDir
                Layout.preferredWidth: implicitWidth
              }
            }

            MouseArea {
              id: listMouseArea
              anchors.fill: parent
              hoverEnabled: true
              acceptedButtons: Qt.LeftButton | Qt.RightButton

              onClicked: mouse => {
                           if (mouse.button === Qt.LeftButton) {
                             if (listItem.fileIsDir) {
                               // In folder mode, single click selects the folder
                               if (root.selectionMode === "folders") {
                                 filePickerPanel.itemClicked(mouse.modifiers, listItem.filePath);
                               }
                               // In file mode, single click on folder does nothing (must double-click to enter)
                             } else {
                               // Single click on file selects it (only in file mode)
                               if (root.selectionMode === "files") {
                                 filePickerPanel.itemClicked(mouse.modifiers, listItem.filePath);
                               }
                             }
                           }
                         }

              onDoubleClicked: mouse => {
                                 if (mouse.button === Qt.LeftButton) {
                                   if (listItem.fileIsDir) {
                                     // Double-click on folder always navigates into it
                                     folderModel.folder = root.toFileUrl(listItem.filePath);
                                     root.currentPath = listItem.filePath;
                                   } else {
                                     // Double-click on file selects and confirms (only in file mode)
                                     if (root.selectionMode === "files") {
                                       filePickerPanel.currentSelection = [listItem.filePath];
                                       root.confirmSelection();
                                     }
                                   }
                                 }
                               }
            }
          }
        }
      }

      // Footer
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        NText {
          text: {
            if (filePickerPanel.searchText.length > 0) {
              return "Searching for: \"" + filePickerPanel.searchText + "\" (" + filteredModel.count + " matches)";
            } else if (FilePickerUtils.selectionCount(filePickerPanel.currentSelection) > 0) {
              const selectedName = filePickerPanel.currentSelection[0].split('/').pop();
              return I18n.tr("widgets.file-picker.selected") + " " + selectedName;
            } else {
              return filteredModel.count + " " + (filteredModel.count === 1 ? I18n.tr("widgets.file-picker.item") : I18n.tr("widgets.file-picker.items"));
            }
          }
          color: filePickerPanel.searchText.length > 0 ? Color.mPrimary : Color.mOnSurfaceVariant
          pointSize: Style.fontSizeS
          Layout.fillWidth: true
        }

        NButton {
          text: I18n.tr("common.cancel")
          outlined: true
          onClicked: {
            root.cancelled();
            root.close();
          }
        }

        NButton {
          text: root.selectionMode === "folders" ? I18n.tr("widgets.file-picker.select-folder") : I18n.tr("widgets.file-picker.select-file")
          icon: "filepicker-check"
          enabled: FilePickerUtils.selectionCount(filePickerPanel.currentSelection) > 0
          onClicked: root.confirmSelection()
        }
      }
    }

    Connections {
      target: root
      function onShouldResetSelectionChanged() {
        if (root.shouldResetSelection) {
          filePickerPanel.currentSelection = [];
          root.shouldResetSelection = false;
        }
      }
    }

    Component.onCompleted: {
      if (!root.currentPath)
        root.currentPath = root.initialPath;
      folderModel.folder = root.toFileUrl(root.currentPath);
    }
  }
}
