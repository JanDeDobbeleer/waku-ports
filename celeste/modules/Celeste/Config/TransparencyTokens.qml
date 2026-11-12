import QtQuick
import "ScaleSizes.js" as SS

// Tokens.transparency: the transparency settings of GlobalConfig.appearance as typed properties.
QtObject {
    id: root

    required property var source

    readonly final property bool enabled: SS.get(root.source, "enabled")
    readonly final property real base: SS.get(root.source, "base")
    readonly final property real layers: SS.get(root.source, "layers")
}
