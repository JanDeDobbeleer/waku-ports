pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import M3Shapes
import Celeste.Components
import Celeste.Config
import qs.components
import qs.services
import qs.utils

Item {
    id: root

    required final property int modelData
    required final property int index
    required final property int activeWsId
    required final property int ws
    required final property HyprMonitor monitor

    required final property int displayType
    required final property bool showWindows
    required final property var iconRules
    final property string activeLabel
    final property string occupiedLabel
    final property string label

    readonly final property var toplevels: Hypr.toplevelsForWs(ws, GlobalConfig.bar.workspaces.ignoredTags)
    readonly final property bool isOccupied: Hypr.toplevelCount(ws) > 0
    readonly final property bool hasWindows: isOccupied && showWindows && Config.bar.workspaces.maxWindowIcons > 0
    readonly final property bool focused: activeWsId === ws
    final property real windowsHeight: 0

    final property color offMonitorColour: Colours.palette.m3outlineVariant
    readonly final property bool onOtherMonitor: {
        if (Config.bar.workspaces.perMonitor)
            return false;
        const mon = Hypr.workspaceById(ws)?.monitor;
        return !!(mon && mon !== monitor);
    }
    readonly final property color fgColour: {
        if (onOtherMonitor)
            return offMonitorColour;
        if (focused || isOccupied || Config.bar.workspaces.occupiedBg)
            return Colours.palette.m3onSurface;
        return Colours.layer(Colours.palette.m3outlineVariant, 2);
    }

    // Every indicator is round: the focused, occupied and empty desktops differ by size and colour.
    function updateShape(): void {
        const shape = indicator.item as MaterialShape;
        if (shape)
            shape.shape = MaterialShape.Circle;
    }

    anchors.horizontalCenter: parent?.horizontalCenter
    // Port: LazyListView's attached layout properties are plain properties here, and the list is
    // a ListView, so the delegate sets its own height. Adding and removing do not animate.
    readonly final property real preferredHeight: layout.implicitHeight + (hasWindows ? Tokens.padding.extraSmall : 0)
    final property real visibleHeight: preferredHeight
    readonly final property real layoutY: y

    width: ListView.view?.width ?? 0
    height: visibleHeight

    onFocusedChanged: updateShape()
    Component.onCompleted: updateShape()

    Behavior on visibleHeight {
        Anim {}
    }

    Behavior on y {
        Anim {}
    }

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }

    Component {
        id: shapeComponent

        MaterialShape {
            implicitSize: Tokens.sizes.bar.innerWidth - Tokens.padding.small

            color: root.fgColour
            scale: root.focused ? 2 / 3 : root.isOccupied ? 1 / 3 : 1 / 4

            animationEasing: Tokens.anim.expressiveDefaultSpatial
            animationDuration: Tokens.anim.durations.expressiveDefaultSpatial * Tokens.anim.durations.scale

            Behavior on color {
                CAnim {}
            }

            Behavior on scale {
                Anim {}
            }
        }
    }

    Component {
        id: textComponent

        StyledText {
            animate: true
            text: {
                if (root.focused) {
                    const label = root.activeLabel;
                    if (label)
                        return label;
                }

                if (root.focused || root.isOccupied) {
                    const label = root.occupiedLabel;
                    if (label)
                        return label;
                }

                const label = root.label;
                if (label)
                    return label;

                const ws = Hypr.workspaceById(root.ws);
                const wsName = !ws || ws.name == root.ws ? root.ws : Hypr.trimWsName(ws.name)[0];

                const capitalisation = Config.bar.workspaces.capitalisation;
                if (capitalisation === BarWorkspaceCapitalisation.Upper)
                    return String(wsName).toUpperCase();
                else if (capitalisation === BarWorkspaceCapitalisation.Lower)
                    return String(wsName).toLowerCase();
                return wsName;
            }
            color: root.fgColour
            verticalAlignment: Qt.AlignVCenter
            font.family: Tokens.font.workspaces
        }
    }

    Component {
        id: iconComponent

        MaterialIcon {
            fill: 1
            grade: 25
            text: iconCacher.icon
            color: root.fgColour
            verticalAlignment: Qt.AlignVCenter

            WsIconCacher {
                id: iconCacher
            }
        }
    }

    Component {
        id: iconLoaderComponent

        Loader {
            sourceComponent: loaderIconCacher.icon ? iconComponent : textComponent

            WsIconCacher {
                id: loaderIconCacher
            }
        }
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: 0

        Loader {
            id: indicator

            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
            Layout.preferredHeight: Tokens.sizes.bar.innerWidth - Tokens.padding.small
            sourceComponent: {
                if (root.displayType === BarWorkspaceDisplay.Icons)
                    return iconLoaderComponent;
                if (root.displayType === BarWorkspaceDisplay.Text)
                    return textComponent;
                return shapeComponent;
            }

            onItemChanged: root.updateShape()
        }

        Loader {
            id: windows

            asynchronous: true

            Layout.fillWidth: true
            Layout.topMargin: -Tokens.spacing.extraSmall / 2
            Layout.preferredHeight: root.hasWindows ? root.windowsHeight : 0

            visible: active
            active: root.showWindows && Config.bar.workspaces.maxWindowIcons > 0

            sourceComponent: LazyListView {
                spacing: 0
                implicitHeight: contentHeight
                removeDuration: Tokens.anim.durations.expressiveDefaultEffects

                Component.onCompleted: root.windowsHeight = layoutHeight
                onLayoutHeightChanged: root.windowsHeight = layoutHeight

                model: ScriptModel {
                    values: {
                        const windows = root.toplevels;
                        const maxIcons = Config.bar.workspaces.maxWindowIcons;
                        return maxIcons > 0 ? windows.slice(0, maxIcons) : windows;
                    }
                }

                // Port: the delegate is as wide as the list, so its icon sits on the same centre
                // line as the dot (a ListView does not size its delegates, and a bare icon sat at
                // x = 0). Upstream shows a Material category glyph; here a window's own icon or
                // its app's icon is shown, and the category glyph stays as the fallback.
                delegate: Item {
                    id: win

                    required final property HyprToplevel modelData
                    required final property int index // Needed, LazyListView will fail to set it if it doesn't exist

                    readonly final property bool hasImage: image.source.toString() !== "" && image.status !== Image.Error
                    readonly final property color tint: root.onOtherMonitor ? root.offMonitorColour : Colours.palette.m3onSurfaceVariant

                    width: ListView.view?.width ?? 0
                    height: glyph.implicitHeight

                    opacity: root.onOtherMonitor ? 0.5 : 1

                    Behavior on y {
                        Anim {}
                    }

                    MaterialIcon {
                        id: glyph

                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: !win.hasImage
                        grade: 0
                        text: Icons.getAppCategoryIcon(win.modelData.appClass, "desktop_windows")
                        color: win.tint
                    }

                    Image {
                        id: image

                        // A square the height of the glyph, centred.
                        anchors.centerIn: parent
                        width: Math.round(glyph.implicitHeight * 0.9)
                        height: width
                        visible: win.hasImage
                        source: win.modelData.icon
                        sourceSize: Qt.size(width * 2, height * 2)
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        smooth: true
                        mipmap: true
                    }
                }
            }
        }
    }

    component WsIconCacher: QtObject {
        id: cacher

        final property string name
        readonly final property string icon: Icons.matchIconRuleList(Hypr.trimWsName(name), root.iconRules)
        readonly final property HyprWorkspace wsObj: Hypr.workspaceById(root.ws)

        readonly final property Connections conn: Connections {
            function onNameChanged(): void {
                cacher.updateName();
            }

            target: cacher.wsObj
        }

        function updateName(): void {
            if (wsObj)
                name = wsObj.name;
        }

        onWsObjChanged: updateName()
        Component.onCompleted: updateName()
    }
}
