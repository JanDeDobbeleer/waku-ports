pragma ComponentBehavior: Bound

import QtQuick
import Celeste.Config
import Celeste.I18n
import qs.components
import qs.services
import qs.utils
import "ActiveWindowHelpers.js" as ActiveWindowHelpers

Item {
    id: root

    required final property var bar
    required final property Brightness.Monitor monitor
    final property color colour: Colours.palette.m3primary

    readonly final property string windowTitle: {
        const title = Hypr.activeToplevel?.title;
        if (!title)
            return Tr.trCtx("Desktop", "shown when no window is focused");
        if (Config.bar.activeWindow.compact) {
            // " - " (standard hyphen), " — " (em dash), " – " (en dash)
            const parts = title.split(/\s+[\-\u2013\u2014]\s+/);
            if (parts.length > 1)
                return parts[parts.length - 1].trim();
        }
        return title;
    }

    readonly final property int maxHeight: ActiveWindowHelpers.maxHeight(bar, root)
    final property Title current: text1

    clip: true
    implicitWidth: Math.max(icon.implicitWidth, root.current === text1 ? text1.implicitHeight : text2.implicitHeight)
    implicitHeight: icon.implicitHeight + (root.current === text1 ? text1.implicitWidth + text1.anchors.topMargin : text2.implicitWidth + text2.anchors.topMargin)

    Loader {
        asynchronous: true
        anchors.fill: parent
        active: !Config.bar.activeWindow.showOnHover

        sourceComponent: MouseArea {
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onPositionChanged: ActiveWindowHelpers.positionChanged(root.bar)
            onClicked: ActiveWindowHelpers.clicked(root, root.bar)
        }
    }

    MaterialIcon {
        id: icon

        anchors.horizontalCenter: parent.horizontalCenter

        animate: true
        text: Icons.getAppCategoryIcon(Hypr.activeToplevel?.appClass, "desktop_windows")
        color: root.colour
    }

    Title {
        id: text1
    }

    Title {
        id: text2
    }

    TextMetrics {
        id: metrics

        text: root.windowTitle
        font: Tokens.styled("body", "small", { letterSpacing: 1.4 })
        elide: Qt.ElideRight
        elideWidth: root.maxHeight - icon.height

        onTextChanged: {
            const next = root.current === text1 ? text2 : text1;
            next.text = elidedText;
            root.current = next;
        }
        onElideWidthChanged: {
            if (root.current === text1)
                text1.text = elidedText;
            else
                text2.text = elidedText;
        }
    }

    Behavior on implicitHeight {
        Anim {}
    }

    component Title: StyledText {
        id: text

        anchors.horizontalCenter: icon.horizontalCenter
        anchors.top: icon.bottom
        anchors.topMargin: Tokens.spacing.small

        font: metrics.font
        color: root.colour
        opacity: root.current === this ? 1 : 0
        horizontalAlignment: Text.AlignLeft

        transform: [
            Translate {
                x: Config.bar.activeWindow.inverted ? -text.implicitWidth + text.implicitHeight : 0
            },
            Rotation {
                angle: Config.bar.activeWindow.inverted ? 270 : 90
                origin.x: text.implicitHeight / 2
                origin.y: text.implicitHeight / 2
            }
        ]

        width: implicitHeight
        height: implicitWidth

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }
}
