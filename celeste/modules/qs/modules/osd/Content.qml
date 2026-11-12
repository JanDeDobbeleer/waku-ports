pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Celeste
import Celeste.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import "OsdContentHelpers.js" as OsdContentHelpers

Item {
    id: root

    required final property Brightness.Monitor monitor
    required final property ScreenState screenState

    required final property real volume
    required final property bool muted
    required final property real sourceVolume
    required final property bool sourceMuted
    required final property real brightness

    implicitWidth: layout.implicitWidth + Tokens.padding.large + layout.anchors.horizontalCenterOffset * 2
    implicitHeight: layout.implicitHeight + Tokens.padding.large * 2

    ColumnLayout {
        id: layout

        anchors.centerIn: parent
        anchors.horizontalCenterOffset: CUtils.clamp(Tokens.padding.large - Config.border.thickness, 0, Tokens.padding.large) / 2
        spacing: Tokens.spacing.medium

        // Speaker volume
        CustomMouseArea {
            onWheel: event => {
                if (event.angleDelta.y > 0)
                    Audio.incrementVolume(0);
                else if (event.angleDelta.y < 0)
                    Audio.decrementVolume(0);
            }

            implicitWidth: Tokens.sizes.osd.sliderWidth
            implicitHeight: Tokens.sizes.osd.sliderHeight

            FilledSlider {
                anchors.fill: parent

                icon: Icons.getVolumeIcon(value, root.muted)
                value: root.volume
                to: GlobalConfig.services.maxVolume
                onMoved: Audio.setVolume(value)
            }
        }

        // Microphone volume
        WrappedLoader {
            shouldBeActive: Config.osd.enableMicrophone && (!Config.osd.enableBrightness || !root.screenState.session)

            sourceComponent: CustomMouseArea {
                onWheel: event => {
                    if (event.angleDelta.y > 0)
                        Audio.incrementSourceVolume(0);
                    else if (event.angleDelta.y < 0)
                        Audio.decrementSourceVolume(0);
                }

                implicitWidth: Tokens.sizes.osd.sliderWidth
                implicitHeight: Tokens.sizes.osd.sliderHeight

                FilledSlider {
                    anchors.fill: parent

                    icon: Icons.getMicVolumeIcon(value, root.sourceMuted)
                    value: root.sourceVolume
                    to: GlobalConfig.services.maxVolume
                    onMoved: Audio.setSourceVolume(value)
                }
            }
        }

        // Brightness
        WrappedLoader {
            shouldBeActive: Config.osd.enableBrightness

            sourceComponent: CustomMouseArea {
                onWheel: event => OsdContentHelpers.adjustBrightness(root.monitor, event.angleDelta.y, GlobalConfig.services.brightnessIncrement)

                implicitWidth: Tokens.sizes.osd.sliderWidth
                implicitHeight: Tokens.sizes.osd.sliderHeight

                FilledSlider {
                    anchors.fill: parent

                    icon: `brightness_${(Math.round(value * 6) + 1)}`
                    value: root.brightness
                    onMoved: OsdContentHelpers.setBrightness(root.monitor, value)
                }
            }
        }
    }

    component WrappedLoader: Loader {
        required final property bool shouldBeActive

        asynchronous: true
        Layout.preferredHeight: shouldBeActive ? Tokens.sizes.osd.sliderHeight : 0
        opacity: shouldBeActive ? 1 : 0
        active: opacity > 0
        visible: active

        Behavior on Layout.preferredHeight {
            Anim {
                type: Anim.Emphasized
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }
}
