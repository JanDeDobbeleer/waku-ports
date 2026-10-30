pragma Singleton

import QtQuick
import "FontBuilder.js" as FB

// Port of upstream Tokens, an attached type there (per-screen merged design tokens). Here it is
// one singleton: no per-screen overrides and no `Tokens.screen`. Upstream code that says
// `root.Tokens.x` must say `Tokens.x` (see tools/strip-attached.ps1).
QtObject {
    id: root

    function forScreen(screen: string): var {
        return TokenConfig;
    }

    readonly property QtObject rounding: ScaledTokens {
        source: TokenConfig.appearance.rounding
        scale: GlobalConfig.appearance.rounding.scale
    }
    readonly property QtObject spacing: ScaledTokens {
        source: TokenConfig.appearance.spacing
        scale: GlobalConfig.appearance.spacing.scale
    }
    readonly property QtObject padding: ScaledTokens {
        source: TokenConfig.appearance.padding
        scale: GlobalConfig.appearance.padding.scale
    }
    // Transparency is always global upstream too
    readonly property var transparency: GlobalConfig.appearance.transparency
    readonly property var sizes: TokenConfig.sizes
    readonly property QtObject anim: AnimTokens {}

    readonly property QtObject font: QtObject {
        readonly property real fontScale: GlobalConfig.appearance.font.scale

        readonly property QtObject headline: TokenFontStyle {
            cfg: GlobalConfig.appearance.font.headline
            scale: root.font.fontScale
        }
        readonly property QtObject title: TokenFontStyle {
            cfg: GlobalConfig.appearance.font.title
            scale: root.font.fontScale
        }
        readonly property QtObject body: TokenFontStyle {
            cfg: GlobalConfig.appearance.font.body
            scale: root.font.fontScale
        }
        readonly property QtObject label: TokenFontStyle {
            cfg: GlobalConfig.appearance.font.label
            scale: root.font.fontScale
        }
        readonly property QtObject mono: TokenFontStyle {
            cfg: GlobalConfig.appearance.font.mono
            scale: root.font.fontScale
        }
        readonly property QtObject icon: TokenFontStyle {
            cfg: GlobalConfig.appearance.font.icon
            scale: root.font.fontScale
        }
        // A FontBuilder with only the family set, like upstream's `QFont f; f.setFamily(...)`
        readonly property var clock: FB.make(GlobalConfig.appearance.font.clock, 12, Font.Normal, false, {})
        readonly property string workspaces: GlobalConfig.appearance.font.workspaces
    }

    // Google Sans Flex ships in the port's assets/, found relative to this module so that any
    // config home works. Without the file the family falls back to the system.
    readonly property FontLoader googleSansFlex: FontLoader {
        source: Qt.resolvedUrl("../../../assets/google-sans-flex/GoogleSansFlex-VariableFont_GRAD,ROND,opsz,slnt,wdth,wght.ttf")
    }
}
