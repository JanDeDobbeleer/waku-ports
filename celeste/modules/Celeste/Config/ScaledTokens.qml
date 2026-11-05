import QtQuick

// One size scale of upstream's AppearanceRounding/Spacing/Padding: each token times `scale`,
// truncated to an int like upstream's static_cast<int>. `full` only matters for rounding.
QtObject {
    required property var source
    property real scale: 1

    readonly property int extraSmall: Math.trunc(source.extraSmall * scale)
    readonly property int small: Math.trunc(source.small * scale)
    readonly property int medium: Math.trunc(source.medium * scale)
    readonly property int large: Math.trunc(source.large * scale)
    readonly property int largeIncreased: Math.trunc(source.largeIncreased * scale)
    readonly property int extraLarge: Math.trunc(source.extraLarge * scale)
    readonly property int extraLargeIncreased: Math.trunc(source.extraLargeIncreased * scale)
    readonly property int extraExtraLarge: Math.trunc(source.extraExtraLarge * scale)
    readonly property int full: source.full ?? 0
}
