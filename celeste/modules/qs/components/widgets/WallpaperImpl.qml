import QtQuick
import Celeste
import Celeste.Config
import Celeste.Multimedia
import Celeste.Shaders
import Celeste.State
import waku.services as S
import "WallpaperImplHelpers.js" as WallpaperImplHelpers

Item {
    id: root

    readonly final property var shader: WallpaperImplHelpers.shader(Config.background, Shaders, CUtils)

    final property string source: S.Wallpapers.current
    final property ShaderEffectSource currentCapture: capture1
    final property real transitionProgress: 1

    onSourceChanged: {
        transitionAnim.stop();

        if (transitionProgress < 1) {
            currentCapture = currentCapture === capture1 ? capture2 : capture1;
            WallpaperImplHelpers.setSourceItem(currentCapture, transition);
        } else {
            WallpaperImplHelpers.setSourceItem(currentCapture, liveItem);
        }

        currentCapture.visible = true;
        WallpaperImplHelpers.scheduleUpdate(currentCapture);
    }

    Component.onCompleted: liveItem.source = source

    NumberAnimation on transitionProgress {
        id: transitionAnim

        running: false
        duration: WallpaperImplHelpers.duration(root.shader) * Tokens.anim.durations.scale
        easing: WallpaperImplHelpers.easing(root.shader)
        to: 1
    }

    ShaderEffectSource {
        id: capture1

        anchors.fill: parent
        live: false
        visible: false

        onScheduledUpdateCompleted: {
            visible = false;
            transition.from = this;
            root.transitionProgress = 0;
            liveItem.source = root.source;
            if (liveItem.ready)
                transitionAnim.start();
        }
    }

    ShaderEffectSource {
        id: capture2

        anchors.fill: parent
        live: false
        visible: false

        onScheduledUpdateCompleted: {
            visible = false;
            transition.from = this;
            root.transitionProgress = 0;
            liveItem.source = root.source;
            if (liveItem.ready)
                transitionAnim.start();
        }
    }

    Visual {
        id: liveItem

        anchors.fill: parent
        playing: PersistentState.wallpaperPlaying
        animate: false
        layer.enabled: true

        onReadyChanged: {
            if (ready && source === root.source)
                transitionAnim.start();
        }
    }

    ShaderEffect {
        id: transition

        final property Item from
        final property Item to: liveItem
        final property real progress: root.transitionProgress

        anchors.fill: parent
        visible: root.transitionProgress < 1
        fragmentShader: WallpaperImplHelpers.url(root.shader)
    }
}
