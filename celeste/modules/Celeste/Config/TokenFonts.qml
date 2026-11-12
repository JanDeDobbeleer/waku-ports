import QtQuick
import "ScaleSizes.js" as SS

// Tokens.font: the font styles, and the clock and workspaces fonts.
QtObject {
    id: root

    property real fontScale: 1

    readonly final property TokenFontStyle headline: TokenFontStyle {
        cfg: SS.get(GlobalConfig.appearance, "font.headline")
        scale: root.fontScale
    }
    readonly final property TokenFontStyle title: TokenFontStyle {
        cfg: SS.get(GlobalConfig.appearance, "font.title")
        scale: root.fontScale
    }
    readonly final property TokenFontStyle body: TokenFontStyle {
        cfg: SS.get(GlobalConfig.appearance, "font.body")
        scale: root.fontScale
    }
    readonly final property TokenFontStyle label: TokenFontStyle {
        cfg: SS.get(GlobalConfig.appearance, "font.label")
        scale: root.fontScale
    }
    readonly final property TokenFontStyle mono: TokenFontStyle {
        cfg: SS.get(GlobalConfig.appearance, "font.mono")
        scale: root.fontScale
    }
    readonly final property TokenFontStyle icon: TokenFontStyle {
        cfg: SS.get(GlobalConfig.appearance, "font.icon")
        scale: root.fontScale
    }

    readonly final property string workspaces: SS.get(GlobalConfig.appearance, "font.workspaces")
}
