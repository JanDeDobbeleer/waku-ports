import QtQuick
import Celeste.Config
import Celeste.Multimedia
import Celeste.State
import qs.components
import qs.components.effects
import qs.services
import "WallpaperItemHelpers.js" as WallpaperItemHelpers

Item {
    id: root

    required final property var modelData
    required final property ScreenState screenState

    scale: PathView.isCurrentItem ? 1 : PathView.onPath ? 0.8 : 0
    opacity: PathView.onPath ? 1 : 0
    z: WallpaperItemHelpers.pathZ(root.PathView)

    implicitWidth: image.width + Tokens.padding.medium * 2
    implicitHeight: image.height + label.height + Tokens.spacing.extraSmall + Tokens.padding.large + Tokens.padding.medium

    StateLayer {
        id: stateLayer

        objectName: "rowClick"

        radius: Tokens.rounding.large
        onClicked: {
            WallpaperItemHelpers.setWallpaper(WallpaperService, root.modelData);
            root.screenState.launcher = false;
        }
    }

    Elevation {
        anchors.fill: image
        radius: image.radius
        opacity: root.PathView.isCurrentItem ? 1 : 0
        level: 4

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    ClipRect {
        id: image

        anchors.horizontalCenter: parent.horizontalCenter
        y: Tokens.padding.large
        color: Colours.tPalette.m3surfaceContainer
        radius: Tokens.rounding.large

        implicitWidth: Tokens.sizes.launcher.wallpaperWidth
        implicitHeight: implicitWidth / 16 * 9

        MaterialIcon {
            anchors.centerIn: parent
            text: "image"
            color: Colours.tPalette.m3outline
            fontStyle: Tokens.styled("icon", "extraLarge", { scale: 2, weight: Font.DemiBold })
        }

        Visual {
            anchors.fill: parent
            source: WallpaperItemHelpers.path(root.modelData)
            thumbnail: true
            playing: (root.PathView.isCurrentItem && PersistentState.wallpaperPlaying) || stateLayer.containsMouse
        }
    }

    StyledText {
        id: label

        anchors.top: image.bottom
        anchors.topMargin: Tokens.spacing.extraSmall
        anchors.horizontalCenter: parent.horizontalCenter

        width: image.width - Tokens.padding.medium * 2
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        renderType: Text.QtRendering
        text: WallpaperItemHelpers.relativePath(root.modelData)
        font: Tokens.font.label.medium
    }

    Behavior on scale {
        Anim {}
    }

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }
}
