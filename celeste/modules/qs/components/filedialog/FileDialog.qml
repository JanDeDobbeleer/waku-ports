pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Celeste.I18n
import qs.components
import qs.services
import "FileDialogHelpers.js" as FileDialogHelpers

LazyLoader {
    id: loader

    final property list<string> cwd: ["Home"]
    final property string filterLabel: Tr.tr("All files")
    final property list<string> filters: ["*"]
    final property string title: Tr.tr("Select a file")

    signal accepted(path: string)
    signal rejected

    function open(): void {
        activeAsync = true;
    }

    function close(): void {
        rejected();
    }

    onAccepted: activeAsync = false
    onRejected: activeAsync = false

    FloatingWindow {
        id: root

        final property list<string> cwd: loader.cwd
        final property string filterLabel: loader.filterLabel
        final property list<string> filters: loader.filters

        readonly final property bool selectionValid: {
            return FileDialogHelpers.selectionValid(folderContents.currentItem?.modelData, filters);
        }

        function accepted(path: string): void {
            loader.accepted(path);
        }

        function rejected(): void {
            loader.rejected();
        }

        implicitWidth: 1000
        implicitHeight: 600
        minimumSize.width: 400
        minimumSize.height: 300
        color: Colours.tPalette.m3surface
        surfaceFormat.opaque: false
        title: loader.title

        // Port: the engine activates (brings to the front) a window only when it is shown after its
        // setup, not one that is visible from the start, which is what a LazyLoader gives. So it
        // starts hidden and is shown once it is loaded; otherwise it opens behind the active window.
        visible: false
        Component.onCompleted: FileDialogHelpers.showLater(root)

        onVisibleChanged: {
            if (!visible)
                rejected();
        }

        RowLayout {
            anchors.fill: parent

            spacing: 0

            Sidebar {
                Layout.fillHeight: true
                dialog: root
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true

                spacing: 0

                HeaderBar {
                    Layout.fillWidth: true
                    dialog: root
                }

                FolderContents {
                    id: folderContents

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    dialog: root
                }

                DialogButtons {
                    Layout.fillWidth: true
                    dialog: root
                    folder: folderContents
                }
            }
        }

        Behavior on color {
            CAnim {}
        }
    }
}
