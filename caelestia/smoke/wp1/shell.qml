import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import Caelestia.State

// WP1 smoke shell: shows values of the Config/Tokens/Tr/Toaster singletons in a small panel.
ShellRoot {
    id: root

    Component.onCompleted: Toaster.toast("Smoke toast", "Toaster works", "info", Toast.Success, 20000)

    PanelWindow {
        anchors.top: true
        anchors.left: true
        margins.top: 80
        margins.left: 80
        implicitWidth: 560
        implicitHeight: 420
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: Tokens.rounding.large
            color: "#1e1e2e"
            border.color: "#89b4fa"
            border.width: 2

            Column {
                x: Tokens.padding.large
                y: Tokens.padding.large
                width: parent.width - Tokens.padding.large * 2
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.small

                Text {
                    color: "white"
                    font: Tokens.font.headline.small
                    text: Tr.tr("hello %1").arg("wabar")
                }
                Text {
                    color: "#cdd6f4"
                    font: Tokens.font.body.builders.large.weight(Font.Bold).build()
                    text: "rounding.large = " + Tokens.rounding.large + ", spacing.small = " + Tokens.spacing.small
                }
                Text {
                    color: "#cdd6f4"
                    font: Tokens.font.body.medium
                    text: "body.medium: " + font.family + " " + font.pointSize + "pt w" + font.weight + " axes " + JSON.stringify(font.variableAxes)
                }
                Text {
                    color: "#cdd6f4"
                    font: Tokens.font.mono.small
                    text: "mono.small: " + font.family + " " + font.pointSize + "pt"
                }
                Text {
                    color: "#cdd6f4"
                    font: Tokens.font.body.small
                    text: "bar.persistent = " + Config.bar.persistent + ", entries = " + Config.bar.entries.values.length + ", border = " + Config.border.thickness + "/" + Config.border.clampedThickness
                }
                Text {
                    color: "#cdd6f4"
                    font: Tokens.font.body.small
                    text: "durations.expressiveDefaultSpatial = " + Tokens.anim.durations.expressiveDefaultSpatial + " ms, sizes.bar.innerWidth = " + Tokens.sizes.bar.innerWidth
                }
                Text {
                    color: "#cdd6f4"
                    font: Tokens.font.body.small
                    text: "toasts = " + Toaster.toasts.length + (Toaster.toasts.length ? " first = " + Toaster.toasts[0].title + " (" + Toaster.toasts[0].icon + ")" : "")
                }
                Text {
                    color: "#cdd6f4"
                    font: Tokens.font.body.small
                    text: "gameMode = " + RuntimeState.gameMode + ", dnd = " + PersistentState.doNotDisturb
                }
                Text {
                    color: "#cdd6f4"
                    font: Tokens.font.label.small
                    text: Units.formatBytes(123456789) + ", " + Units.formatSensorTemp(41.6) + ", clamp " + CUtils.clamp(7, 0, 5)
                }

                Item {
                    width: parent.width
                    implicitHeight: Tokens.padding.extraLarge * 2

                    Rectangle {
                        id: mover

                        width: Tokens.rounding.extraLarge * 2
                        height: width
                        radius: Tokens.rounding.extraLarge
                        color: "#a6e3a1"

                        SequentialAnimation on x {
                            loops: Animation.Infinite
                            NumberAnimation {
                                to: 300
                                duration: Tokens.anim.durations.expressiveDefaultSpatial
                                easing: Tokens.anim.expressiveDefaultSpatial
                            }
                            NumberAnimation {
                                to: 0
                                duration: Tokens.anim.durations.expressiveFastSpatial
                                easing: Tokens.anim.standard
                            }
                        }
                    }
                }
            }
        }
    }
}
