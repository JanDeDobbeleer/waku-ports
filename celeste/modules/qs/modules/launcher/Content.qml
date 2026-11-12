pragma ComponentBehavior: Bound

import QtQuick
import Celeste
import Celeste.Config
import Celeste.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.launcher.services

Item {
    id: root

    required final property ScreenState screenState
    required final property var panels
    required final property real maxHeight

    readonly final property int padding: Tokens.padding.large
    readonly final property int rounding: Tokens.rounding.extraLarge

    implicitWidth: listWrapper.width + padding * 2
    implicitHeight: searchItem.height + listWrapper.height + padding + searchItem.anchors.bottomMargin

    Item {
        id: listWrapper

        implicitWidth: list.width
        implicitHeight: list.height + root.padding

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: searchItem.top
        anchors.bottomMargin: root.padding

        ContentList {
            id: list

            content: root
            screenState: root.screenState
            panels: root.panels
            maxHeight: root.maxHeight - searchItem.implicitHeight - root.padding * 3
            search: searchItem
            padding: root.padding
            rounding: root.rounding
        }
    }

    SearchBar {
        id: searchItem

        objectName: "launcherSearch"

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: root.padding
        anchors.bottomMargin: CUtils.clamp(root.padding - Config.border.thickness, 0, root.padding)

        topPadding: Math.round((Tokens.padding.medium + Tokens.padding.large) / 2)
        bottomPadding: Math.round((Tokens.padding.medium + Tokens.padding.large) / 2)

        placeholderText: Tr.tr("Type \"%1\" for commands").arg(GlobalConfig.launcher.actionPrefix)

        onAccepted: {
            const currentItem = list.currentList?.currentItem;
            if (currentItem) {
                if (list.showWallpapers) {
                    if (Colours.scheme === "dynamic" && currentItem.modelData.path !== WallpaperService.actualCurrent)
                        WallpaperService.previewColourLock = true;
                    WallpaperService.setWallpaper(currentItem.modelData.path);
                    root.screenState.launcher = false;
                } else if (text.startsWith(GlobalConfig.launcher.actionPrefix)) {
                    if (text.startsWith(`${GlobalConfig.launcher.actionPrefix}calc `))
                        currentItem.onClicked();
                    else
                        currentItem.modelData.onClicked(list.currentList);
                } else {
                    Apps.launch(currentItem.modelData);
                    root.screenState.launcher = false;
                }
            }
        }

        Keys.onUpPressed: list.currentList?.decrementCurrentIndex()
        Keys.onDownPressed: list.currentList?.incrementCurrentIndex()

        // Port: the wallpaper strip runs left to right, so the arrows step through it (Enter picks,
        // see onAccepted). Elsewhere they keep moving the text cursor.
        Keys.onLeftPressed: event => {
            if (list.showWallpapers)
                list.currentList?.decrementCurrentIndex();
            else
                event.accepted = false;
        }
        Keys.onRightPressed: event => {
            if (list.showWallpapers)
                list.currentList?.incrementCurrentIndex();
            else
                event.accepted = false;
        }

        Keys.onEscapePressed: root.screenState.launcher = false

        Keys.onPressed: event => {
            if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && (event.modifiers & Qt.ShiftModifier) && list.showWallpapers) {
                const entry = list.currentList?.currentItem?.modelData;
                if (entry) {
                    if (Colours.scheme === "dynamic" && entry.path !== WallpaperService.actualCurrent)
                        WallpaperService.previewColourLock = true;
                    if (WallpaperService.setWallpaperAllDesktops(entry.path))
                        root.screenState.launcher = false;
                }
                event.accepted = true;
                return;
            }

            // Port: Shift+Enter starts the selected app as a new window, Ctrl+Shift+Enter elevated.
            // Handled here and accepted, so the plain Enter path (onAccepted) never also runs.
            if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && (event.modifiers & Qt.ShiftModifier) && !list.showWallpapers && !text.startsWith(GlobalConfig.launcher.actionPrefix)) {
                const entry = list.currentList?.currentItem?.modelData;
                if (entry) {
                    let started = true;
                    if (event.modifiers & Qt.ControlModifier)
                        started = Apps.launchAdmin(entry);
                    else
                        Apps.launchNew(entry);
                    if (started)
                        root.screenState.launcher = false;
                }
                event.accepted = true;
                return;
            }

            if (!GlobalConfig.launcher.vimKeybinds)
                return;

            if (event.modifiers & Qt.ControlModifier) {
                if (event.key === Qt.Key_J || event.key === Qt.Key_N) {
                    list.currentList?.incrementCurrentIndex();
                    event.accepted = true;
                } else if (event.key === Qt.Key_K || event.key === Qt.Key_P) {
                    list.currentList?.decrementCurrentIndex();
                    event.accepted = true;
                }
            } else if (event.key === Qt.Key_Tab) {
                list.currentList?.incrementCurrentIndex();
                event.accepted = true;
            } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                list.currentList?.decrementCurrentIndex();
                event.accepted = true;
            }
        }

        Component.onCompleted: forceActiveFocus()

        Connections {
            function onLauncherChanged(): void {
                if (!root.screenState.launcher)
                    searchItem.text = "";
            }

            function onSessionChanged(): void {
                if (!root.screenState.session)
                    searchItem.forceActiveFocus();
            }

            target: root.screenState
        }
    }
}
