pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.components
import qs.modules.bar.popouts // Need to import this module so the Wrapper type is the same as others

Item {
    id: root

    required final property ShellScreen screen
    required final property real borderThickness

    readonly final property Wrapper content: contentItem
    final property real offsetScale: x > 0 || contentItem.hasCurrent ? 0 : 1

    function close(): void {
        contentItem.close();
    }

    visible: width > 0 && height > 0
    clip: true

    implicitWidth: contentItem.implicitWidth * (1 - offsetScale)
    implicitHeight: contentItem.implicitHeight

    x: contentItem.isDetached ? (parent.width - contentItem.nonAnimWidth) / 2 : 0
    y: {
        if (contentItem.isDetached)
            return (parent.height - contentItem.nonAnimHeight) / 2;

        const off = contentItem.currentCenter - borderThickness - contentItem.nonAnimHeight / 2;
        const diff = parent.height - Math.floor(off + contentItem.nonAnimHeight);
        if (diff < 0)
            return off + diff;
        return Math.max(off, 0);
    }

    Behavior on offsetScale {
        Anim {}
    }

    Behavior on x {
        Anim {
            duration: contentItem.animLength
            easing: contentItem.animCurve
        }
    }

    Behavior on y {
        enabled: root.offsetScale < 1

        Anim {
            duration: contentItem.animLength
            easing: contentItem.animCurve
        }
    }

    Wrapper {
        id: contentItem

        screen: root.screen
        offsetScale: root.offsetScale

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: (-implicitWidth - 5) * root.offsetScale
    }
}
