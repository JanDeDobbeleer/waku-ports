import QtQuick
import "ScaleSizes.js" as SS

// One size scale of upstream's AppearanceRounding/Spacing/Padding: each token times `scale`,
// truncated to an int like upstream's static_cast<int>. `full` only matters for rounding.
QtObject {
    required property var source
    property real scale: 1

    readonly final property int extraSmall: SS.truncScaled(source, "extraSmall", scale)
    readonly final property int small: SS.truncScaled(source, "small", scale)
    readonly final property int medium: SS.truncScaled(source, "medium", scale)
    readonly final property int large: SS.truncScaled(source, "large", scale)
    readonly final property int largeIncreased: SS.truncScaled(source, "largeIncreased", scale)
    readonly final property int extraLarge: SS.truncScaled(source, "extraLarge", scale)
    readonly final property int extraLargeIncreased: SS.truncScaled(source, "extraLargeIncreased", scale)
    readonly final property int extraExtraLarge: SS.truncScaled(source, "extraExtraLarge", scale)
    readonly final property int full: SS.get(source, "full") ?? 0
}
