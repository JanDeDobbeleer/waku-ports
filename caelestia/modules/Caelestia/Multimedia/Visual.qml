import QtQuick
import Caelestia.Config

// Shows an image, an animated image or (not yet) a video, picked by file suffix. Same properties
// as caelestia's Visual. The numeric values of VisualSource.FillMode equal Image.FillMode.
// wabar gap: video files (mp4, webm, mkv...) are not decoded; they show nothing and `type` is Live.
Item {
    id: root

    property string source
    property int fillMode: VisualSource.Stretch
    property bool playing: true
    readonly property int type: kind === "video" ? VisualSource.Live : source ? VisualSource.Still : VisualSource.Unknown
    property bool animate: true
    readonly property bool ready: kind === "animated" ? animated.status === Image.Ready : kind === "still" && still.status === Image.Ready

    readonly property string suffix: {
        const m = /\.([A-Za-z0-9]+)(?:[?#].*)?$/.exec(source);
        return m ? m[1].toLowerCase() : "";
    }
    readonly property string kind: {
        if (!source)
            return "none";
        if (["mp4", "webm", "mkv", "mov", "avi", "m4v"].includes(suffix))
            return "video";
        if (["gif", "apng", "mng"].includes(suffix))
            return "animated";
        return "still";
    }
    // A bare path (/x/y, C:\x\y) becomes a file URL; anything with a scheme stays.
    readonly property url resolvedSource: {
        if (!source)
            return "";
        if (/^[A-Za-z][A-Za-z0-9+.-]+:\/\//.test(source) || source.startsWith("qrc:") || source.startsWith("data:"))
            return source;
        return "file:///" + source.replace(/\\/g, "/").replace(/^\/+/, "");
    }

    opacity: !animate || ready ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: Tokens.anim.durations.expressiveDefaultEffects
            easing: Tokens.anim.expressiveDefaultEffects
        }
    }

    Image {
        id: still

        anchors.fill: parent
        visible: root.kind === "still"
        source: root.kind === "still" ? root.resolvedSource : ""
        sourceSize: Qt.size(root.width, root.height)
        asynchronous: true
        fillMode: root.fillMode
    }

    AnimatedImage {
        id: animated

        anchors.fill: parent
        visible: root.kind === "animated"
        source: root.kind === "animated" ? root.resolvedSource : ""
        playing: root.playing
        asynchronous: true
        fillMode: root.fillMode
    }
}
