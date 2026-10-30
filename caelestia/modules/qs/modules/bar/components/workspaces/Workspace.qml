pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import M3Shapes
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

Item {
    id: root

    required property int modelData
    required property int index
    required property int activeWsId
    required property int ws
    required property var monitor

    required property int displayType
    required property bool showWindows
    required property var iconRules
    property string activeLabel
    property string occupiedLabel
    property string label

    readonly property var toplevels: Hypr.toplevelsForWs(ws, GlobalConfig.bar.workspaces.ignoredTags)
    readonly property bool isOccupied: toplevels.length > 0
    readonly property bool hasWindows: isOccupied && showWindows && Config.bar.workspaces.maxWindowIcons > 0
    readonly property bool focused: activeWsId === ws
    // Port: the komorebi layout of this workspace, shown under the active dot as a glyph.
    readonly property string layoutName: Hypr.workspaces.values.find(w => w.id === ws && w.monitor === monitor)?.layoutName ?? ""
    readonly property bool hasLayout: focused && Hypr.komorebi && layoutName !== ""
    readonly property var layoutInfo: ({
            "BSP": {"icon": "view_quilt", "mirror": false},
            "Columns": {"icon": "view_column", "mirror": false},
            "Rows": {"icon": "table_rows", "mirror": false},
            "VerticalStack": {"icon": "view_sidebar", "mirror": false},
            "HorizontalStack": {"icon": "view_agenda", "mirror": false},
            "UltrawideVerticalStack": {"icon": "view_week", "mirror": false},
            "Grid": {"icon": "grid_view", "mirror": false},
            "RightMainVerticalStack": {"icon": "view_sidebar", "mirror": true}
        })
    readonly property string layoutGlyph: layoutInfo[layoutName]?.icon ?? "dashboard"
    readonly property real layoutHeight: layoutGlyphItem.implicitHeight
    readonly property real layoutTop: layoutGlyphItem.y + layout.y
    readonly property list<int> focusedShapeList: [MaterialShape.Slanted, MaterialShape.Oval, MaterialShape.Pill, MaterialShape.Triangle, MaterialShape.Arrow, MaterialShape.Diamond, MaterialShape.Pentagon, MaterialShape.Gem, MaterialShape.VerySunny, MaterialShape.Sunny, MaterialShape.Cookie4Sided, MaterialShape.Cookie6Sided, MaterialShape.Cookie7Sided, MaterialShape.Cookie9Sided, MaterialShape.Cookie12Sided, MaterialShape.Clover4Leaf, MaterialShape.SoftBurst, MaterialShape.Ghostish]

    property color offMonitorColour: Colours.palette.m3outlineVariant
    readonly property bool onOtherMonitor: {
        if (Config.bar.workspaces.perMonitor)
            return false;
        const mon = Hypr.workspaces.values.find(w => w.id === ws)?.monitor;
        return !!(mon && mon !== monitor);
    }
    readonly property color fgColour: {
        if (onOtherMonitor)
            return offMonitorColour;
        if (focused || isOccupied || Config.bar.workspaces.occupiedBg)
            return Colours.palette.m3onSurface;
        return Colours.layer(Colours.palette.m3outlineVariant, 2);
    }

    function updateShape(): void {
        const shape = indicator.item as MaterialShape;
        if (!shape)
            return;

        if (focused)
            shape.shape = focusedShapeList[Math.floor(Math.random() * focusedShapeList.length)];
        else
            shape.shape = Qt.binding(() => isOccupied ? MaterialShape.Square : MaterialShape.Circle);
    }

    anchors.horizontalCenter: parent?.horizontalCenter
    // Port: LazyListView's attached layout properties are plain properties here, and the list is
    // a ListView, so the delegate sets its own height. Adding and removing do not animate.
    readonly property real preferredHeight: layout.implicitHeight + (hasWindows ? Tokens.padding.extraSmall : 0)
    property real visibleHeight: preferredHeight
    readonly property real layoutY: y

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

                const ws = Hypr.workspaces.values.find(w => w.id === root.ws);
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

        // Port: the layout switcher. It sits in the active dot's pill, under the dot.
        MaterialIcon {
            id: layoutGlyphItem

            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
            Layout.preferredHeight: root.hasLayout ? implicitHeight : 0
            visible: root.hasLayout || opacity > 0
            opacity: root.hasLayout ? 1 : 0
            text: root.layoutGlyph
            fill: 1
            grade: 25
            color: root.fgColour
            transform: Scale {
                origin.x: layoutGlyphItem.width / 2
                xScale: root.layoutInfo[root.layoutName]?.mirror ? -1 : 1
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        Loader {
            id: windows

            asynchronous: true

            Layout.fillWidth: true
            Layout.topMargin: -Tokens.spacing.extraSmall / 2
            Layout.preferredHeight: root.hasWindows && item ? item.layoutHeight : 0

            visible: active
            active: root.showWindows && Config.bar.workspaces.maxWindowIcons > 0

            sourceComponent: LazyListView {
                spacing: 0
                implicitHeight: contentHeight
                removeDuration: Tokens.anim.durations.expressiveDefaultEffects

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

                    required property var modelData
                    required property int index // Needed, LazyListView will fail to set it if it doesn't exist

                    readonly property bool hasImage: image.source.toString() !== "" && image.status !== Image.Error
                    readonly property color tint: root.onOtherMonitor ? root.offMonitorColour : Colours.palette.m3onSurfaceVariant

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
                        text: Icons.getAppCategoryIcon(win.modelData.lastIpcObject.class, "desktop_windows")
                        color: win.tint
                    }

                    Image {
                        id: image

                        // A square the height of the glyph, centred.
                        anchors.centerIn: parent
                        width: Math.round(glyph.implicitHeight * 0.9)
                        height: width
                        visible: win.hasImage
                        source: win.modelData.icon ?? ""
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

        property string name
        readonly property string icon: Icons.matchIconRuleList(Hypr.trimWsName(name), root.iconRules)
        readonly property var wsObj: Hypr.workspaces.values.find(w => w.id === root.ws) ?? null

        readonly property Connections conn: Connections {
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
