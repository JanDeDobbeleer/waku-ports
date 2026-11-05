import QtQuick

// One Segoe Fluent Icons glyph.
Text {
    property int size: 16
    color: Style.text
    font.family: Style.iconFont
    font.pixelSize: size
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering
}
