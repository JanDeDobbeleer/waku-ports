import QtQuick
import QtQuick.Layouts
import Celeste.Config
import qs.components
import qs.services
import waku.services as S

// Port: the hint of the layout button below the workspace dots.
Item {
    id: root

    readonly final property string layoutName: S.Tiling.currentLayout

    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col

        anchors.centerIn: parent
        spacing: 0

        StyledText {
            text: {
                const words = root.layoutName.replace(/([a-z])([A-Z])/g, "$1 $2").toLowerCase();
                return words.charAt(0).toUpperCase() + words.slice(1);
            }
            font: Tokens.font.body.medium
        }

        StyledText {
            text: "click: next layout, scroll: change"
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.small
        }
    }
}
