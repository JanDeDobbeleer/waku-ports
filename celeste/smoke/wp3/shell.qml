import QtQuick
import QtQuick.Layouts
import Quickshell
import Celeste.Config
import Celeste.Components
import Celeste.Multimedia
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services

// WP3 smoke shell: a representative set of qs.components in a grid, in one bare PanelWindow.
ShellRoot {
    PanelWindow {
        id: win

        implicitWidth: 900
        implicitHeight: 600
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        StyledRect {
            anchors.fill: parent
            radius: Tokens.rounding.large
            color: Colours.palette.m3surface

            GridLayout {
                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                columns: 3
                rowSpacing: Tokens.spacing.medium
                columnSpacing: Tokens.spacing.medium

                // StyledRect + StyledText
                StyledRect {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Tokens.rounding.medium
                    color: Colours.palette.m3secondaryContainer

                    StyledText {
                        anchors.centerIn: parent
                        text: "StyledText on StyledRect"
                        color: Colours.palette.m3onSecondaryContainer
                        font: Tokens.font.title.medium
                    }
                }

                // StyledSlider (wavy) and one flat
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    StyledSlider {
                        Layout.fillWidth: true
                        wavy: true
                        animateWave: true
                        value: 0.6
                    }
                    StyledSlider {
                        Layout.fillWidth: true
                        value: 0.3
                    }
                }

                // CircularProgress (determinate, wavy) and CircularIndicator
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Tokens.spacing.large

                    CircularProgress {
                        implicitSize: 72
                        value: 0.65
                        wavy: true
                    }
                    CircularIndicator {
                        running: true
                    }
                }

                // ButtonRow of three TextButtons
                ButtonRow {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: Tokens.spacing.small

                    TextButton {
                        text: "One"
                        fillWidth: true
                    }
                    TextButton {
                        text: "Two"
                        type: TextButton.Tonal
                        fillWidth: true
                    }
                    TextButton {
                        text: "Three"
                        type: TextButton.Text
                        fillWidth: true
                    }
                }

                // StateLayer over a rect, with a MaterialIcon
                StyledRect {
                    Layout.preferredWidth: 160
                    Layout.preferredHeight: 64
                    radius: Tokens.rounding.large
                    color: Colours.palette.m3primaryContainer

                    StateLayer {
                        color: Colours.palette.m3onPrimaryContainer
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "home"
                        color: Colours.palette.m3onPrimaryContainer
                        fontStyle: Tokens.font.icon.extraLarge
                    }
                }

                // LoadingIndicator
                LoadingIndicator {
                    Layout.alignment: Qt.AlignHCenter
                }

                // Linear progress, indeterminate, and a switch
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.medium

                    StyledProgressBar {
                        Layout.fillWidth: true
                        indeterminate: true
                    }
                    StyledProgressBar {
                        Layout.fillWidth: true
                        value: 0.4
                        wavy: true
                    }
                    StyledSwitch {
                        checked: true
                    }
                }

                // An animated element
                Item {
                    Layout.preferredWidth: 96
                    Layout.preferredHeight: 96

                    StyledRect {
                        id: mover

                        width: 32
                        height: 32
                        radius: Tokens.rounding.small
                        color: Colours.palette.m3tertiary

                        SequentialAnimation on x {
                            loops: Animation.Infinite
                            Anim {
                                to: 64
                                type: Anim.StandardLarge
                            }
                            Anim {
                                to: 0
                                type: Anim.StandardLarge
                            }
                        }
                        NumberAnimation on rotation {
                            from: 0
                            to: 360
                            duration: 3000
                            loops: Animation.Infinite
                        }
                    }
                }

                // An image (Visual picks Image or AnimatedImage by suffix)
                Visual {
                    Layout.preferredWidth: 96
                    Layout.preferredHeight: 96
                    source: Qt.resolvedUrl("../../assets/dino.png")
                    fillMode: VisualSource.PreserveAspectFit
                }
            }
        }
    }
}
