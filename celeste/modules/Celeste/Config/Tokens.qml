pragma Singleton

import QtQuick
import "FontBuilder.js" as FB
import "ScaleSizes.js" as SS

// Port of upstream Tokens, an attached type there (per-screen merged design tokens). Here it is
// one singleton: no per-screen overrides and no `Tokens.screen`. Upstream code that says
// `root.Tokens.x` must say `Tokens.x` (see tools/strip-attached.ps1).
QtObject {
    id: root

    function forScreen(screen: string): var {
        return TokenConfig;
    }

    // The master UI scale from shell-tokens.json: a number, or "auto" (1 / devicePixelRatio^0.6,
    // clamped to 0.6..1). A missing, zero or invalid value means 1. Not in upstream.
    readonly property real dpr: Qt.application.screens.length > 0 ? Qt.application.screens[0].devicePixelRatio : 1
    readonly property real scale: {
        const v = TokenConfig.scale;
        if (v === "auto")
            return Math.min(1, Math.max(0.6, 1 / Math.pow(dpr, 0.6)));
        const n = Number(v);
        return n > 0 && isFinite(n) ? n : 1;
    }
    readonly property real fontScale: TokenConfig.fontScale > 0 ? TokenConfig.fontScale : 1
    readonly property real roundingScale: TokenConfig.roundingScale > 0 ? TokenConfig.roundingScale : 1

    // Scales a hard-coded design pixel value by `scale`, for literals in module files.
    function px(value: real): int {
        return Math.round(value * scale);
    }

    readonly property QtObject rounding: ScaledTokens {
        source: TokenConfig.appearance.rounding
        scale: GlobalConfig.appearance.rounding.scale * root.scale * root.roundingScale
    }
    readonly property QtObject spacing: ScaledTokens {
        source: TokenConfig.appearance.spacing
        scale: GlobalConfig.appearance.spacing.scale * root.scale
    }
    readonly property QtObject padding: ScaledTokens {
        source: TokenConfig.appearance.padding
        scale: GlobalConfig.appearance.padding.scale * root.scale
    }
    // Transparency is always global upstream too
    readonly property var transparency: GlobalConfig.appearance.transparency
    readonly property var sizes: SS.scaleSizes(TokenConfig.sizes, root.scale)
    readonly property QtObject anim: AnimTokens {}

    readonly property QtObject font: QtObject {
        readonly property real fontScale: GlobalConfig.appearance.font.scale * root.scale * root.fontScale

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
}
