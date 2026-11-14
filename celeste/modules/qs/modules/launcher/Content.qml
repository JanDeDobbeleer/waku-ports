pragma ComponentBehavior: Bound

import QtQuick
import Celeste
import Celeste.Config
import Celeste.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.launcher.services
import "ContentHelpers.js" as ContentHelpers

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

        onAccepted: ContentHelpers.accepted(list.currentList, list.showWallpapers, text, GlobalConfig.launcher.actionPrefix, Colours.scheme, WallpaperService.actualCurrent, WallpaperService, Apps, root.screenState)

        Keys.onUpPressed: ContentHelpers.move(list.currentList, false)
        Keys.onDownPressed: ContentHelpers.move(list.currentList, true)

        // Port: the wallpaper strip runs left to right, so the arrows step through it (Enter picks,
        // see onAccepted). Elsewhere they keep moving the text cursor.
        Keys.onLeftPressed: event => ContentHelpers.horizontal(list.currentList, list.showWallpapers, event, false)
        Keys.onRightPressed: event => ContentHelpers.horizontal(list.currentList, list.showWallpapers, event, true)

        Keys.onEscapePressed: root.screenState.launcher = false

        Keys.onPressed: event => ContentHelpers.keyPressed(event, list.currentList, list.showWallpapers, text, GlobalConfig.launcher.actionPrefix, GlobalConfig.launcher.vimKeybinds, Colours.scheme, WallpaperService.actualCurrent, WallpaperService, Apps, root.screenState, Qt.Key_Return, Qt.Key_Enter, Qt.ShiftModifier, Qt.ControlModifier, Qt.Key_J, Qt.Key_N, Qt.Key_K, Qt.Key_P, Qt.Key_Tab, Qt.Key_Backtab)

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
