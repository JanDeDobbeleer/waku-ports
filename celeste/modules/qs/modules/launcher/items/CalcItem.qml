import QtQuick
import QtQuick.Layouts
import Quickshell
import Celeste
import Celeste.Config
import Celeste.I18n
import qs.components
import qs.services
import "CalcItemHelpers.js" as CalcItemHelpers

Item {
    id: root

    required final property var list
    readonly final property string math: CalcItemHelpers.expression(list, GlobalConfig.launcher.actionPrefix)

    function onClicked(): void {
        Quickshell.clipboardText = Qalculator.rawResult;
        CalcItemHelpers.closeLauncher(root.list);
    }

    onMathChanged: {
        if (math.length > 0)
            Qalculator.evalAsync(math);
    }

    implicitHeight: Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        objectName: "rowClick"

        radius: Tokens.rounding.large
        onClicked: root.onClicked()
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Tokens.padding.medium

        spacing: Tokens.spacing.medium

        MaterialIcon {
            text: "function"
            fontStyle: Tokens.font.icon.extraLarge
            Layout.alignment: Qt.AlignVCenter
        }

        StyledText {
            id: result

            color: {
                if (text.includes("error: ") || text.includes("warning: "))
                    return Colours.palette.m3error;
                if (!root.math)
                    return Colours.palette.m3onSurfaceVariant;
                return Colours.palette.m3onSurface;
            }

            text: root.math.length > 0 ? (Qalculator.result ? Tr.trMarked(Qalculator.result) : Tr.tr("Calculating...")) : Tr.tr("Type an expression to calculate")
            elide: Text.ElideLeft

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }

        StyledRect {
            color: Colours.palette.m3tertiary
            radius: Tokens.rounding.large
            clip: true

            implicitWidth: (stateLayer.containsMouse ? label.implicitWidth + label.anchors.rightMargin : 0) + icon.implicitWidth + Tokens.padding.medium * 2
            implicitHeight: Math.max(label.implicitHeight, icon.implicitHeight) + Tokens.padding.small

            Layout.alignment: Qt.AlignVCenter

            StateLayer {
                id: stateLayer

                // waku gap: there is no qalc terminal; the button copies the expression instead.
                onClicked: {
                    Quickshell.clipboardText = root.math;
                    CalcItemHelpers.closeLauncher(root.list);
                }

                color: Colours.palette.m3onTertiary
            }

            StyledText {
                id: label

                anchors.verticalCenter: parent.verticalCenter
                anchors.right: icon.left
                anchors.rightMargin: Tokens.spacing.small

                text: Tr.tr("Copy expression")
                color: Colours.palette.m3onTertiary
                font: Tokens.font.label.medium

                opacity: stateLayer.containsMouse ? 1 : 0

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }

            MaterialIcon {
                id: icon

                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: Tokens.padding.medium

                text: "content_copy"
                color: Colours.palette.m3onTertiary
                fontStyle: Tokens.font.icon.large
            }

            Behavior on implicitWidth {
                Anim {
                    type: Anim.Emphasized
                }
            }
        }
    }
}
