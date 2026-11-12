pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Celeste.Config
import Celeste.I18n
import qs.components
import qs.components.containers
import qs.components.controls
import qs.components.effects
import qs.services
import qs.utils
import "NotifDockHelpers.js" as NotifDockHelpers

Item {
    id: root

    required final property Props props
    required final property ScreenState screenState
    readonly final property int notifCount: NotifDockHelpers.count(Notifs.list)

    anchors.fill: parent
    anchors.margins: Tokens.padding.medium

    Component.onCompleted: NotifDockHelpers.disablePopups(Notifs.list)

    Item {
        id: title

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Tokens.padding.extraSmall

        implicitHeight: Math.max(count.implicitHeight, titleText.implicitHeight)

        StyledText {
            id: count

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: root.notifCount > 0 ? 0 : -width - titleText.anchors.leftMargin
            opacity: root.notifCount > 0 ? 1 : 0

            text: root.notifCount
            color: Colours.palette.m3outline
            font: Tokens.font.label.large

            Behavior on anchors.leftMargin {
                Anim {}
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        StyledText {
            id: titleText

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: count.right
            anchors.right: parent.right
            anchors.leftMargin: Tokens.spacing.extraSmall

            // TRANSLATORS: the count itself is rendered separately, immediately to the left
            text: root.notifCount > 0 ? Tr.trCtxN("notification", "notifications", root.notifCount, "notification count label, number shown separately") : Tr.tr("Notifications")
            color: Colours.palette.m3outline
            font: Tokens.font.label.large
            elide: Text.ElideRight
        }
    }

    ClipRect {
        id: clipRect

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: title.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: Tokens.spacing.medium

        radius: Tokens.rounding.medium
        color: "transparent"

        Loader {
            asynchronous: true
            anchors.centerIn: parent
            active: opacity > 0
            opacity: root.notifCount > 0 ? 0 : 1

            sourceComponent: ColumnLayout {
                spacing: Tokens.spacing.extraLarge

                Image {
                    asynchronous: true
                    source: "file:///" + Paths.absolutePath(Config.paths.noNotifsPic) // Port: Qt reads "D:/" as a URL scheme
                    fillMode: Image.PreserveAspectFit
                    // Port: decode at device pixels for sharpness, but lay out at 80% of the panel.
                    // Qt takes sourceSize as the logical size, so at a display scale above 1 the
                    // upstream line made the image wider than the panel and clipped it.
                    sourceSize.width: clipRect.width * 0.8 * ((QsWindow.window as QsWindow)?.devicePixelRatio ?? 1)
                    Layout.preferredWidth: clipRect.width * 0.8
                    Layout.preferredHeight: implicitWidth > 0 ? Layout.preferredWidth * implicitHeight / implicitWidth : 0

                    layer.enabled: true
                    layer.effect: Colouriser {
                        colorizationColor: Colours.palette.m3outlineVariant
                        brightness: 1
                    }
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Tr.tr("All up to date!")
                    color: Colours.palette.m3outlineVariant
                    font: Tokens.styled("headline", "small", { width: 90 })
                }
            }

            Behavior on opacity {
                Anim {
                    type: Anim.StandardExtraLarge
                }
            }
        }

        StyledFlickable {
            id: view

            anchors.fill: parent

            flickableDirection: Flickable.VerticalFlick
            contentWidth: width
            contentHeight: notifList.implicitHeight

            NotifDockList {
                id: notifList

                props: root.props
                screenState: root.screenState
                container: view
            }
        }

        // waku: the attached ScrollBar.vertical does not exist in pure QML; place the bar by hand.
        StyledScrollBar {
            flickable: view
            anchors.top: view.top
            anchors.bottom: view.bottom
            anchors.right: view.right
        }
    }

    Timer {
        id: clearTimer

        repeat: true
        triggeredOnStart: true
        interval: Math.max(15, Math.min(80, 69.8 - 12.3 * Math.log(Notifs.notClosed.length)))
        onTriggered: NotifDockHelpers.clearNext(Notifs.notClosed, clearTimer)
    }

    Loader {
        asynchronous: true
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Tokens.padding.medium

        scale: root.notifCount > 0 ? 1 : 0.5
        opacity: root.notifCount > 0 ? 1 : 0
        active: opacity > 0

        sourceComponent: IconButton {
            id: clearBtn

            icon: "clear_all"
            font: Tokens.font.icon.large
            onClicked: clearTimer.start()

            Elevation {
                anchors.fill: parent
                radius: clearBtn.radius
                z: -1
                level: clearBtn.hovered ? 4 : 3
            }
        }

        Behavior on scale {
            Anim {
                type: Anim.FastSpatial
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }
}
