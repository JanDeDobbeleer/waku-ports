import QtQuick
import waku.services

// Port of celeste's C++ ImageAnalyser. `luminance` comes from waku's ColorScheme.luminance for
// a `source` file. waku gap: `sourceItem` (grabbing an item and analysing the pixels) is not
// supported and `dominantColour` stays a neutral grey.
QtObject {
    id: root

    final property string source
    final property Item sourceItem
    final property int rescaleSize: 128
    readonly final property color dominantColour: "#808080"
    final property real luminance: 0.5

    function requestUpdate(): void {
        if (!source) {
            luminance = 0.5;
            return;
        }
        const path = source.replace(/^file:\/\/\//, "").replace(/^file:\/\//, "");
        const l = ColorScheme.luminance(decodeURIComponent(path));
        luminance = l >= 0 ? l : 0.5;
    }

    onSourceChanged: requestUpdate()
    Component.onCompleted: requestUpdate()
}
