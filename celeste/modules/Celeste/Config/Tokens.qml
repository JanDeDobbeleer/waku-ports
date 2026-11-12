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

    // A font of one style ("headline", "title", "body", "label", "mono" or "icon") and size
    // ("small", "medium", "large" or "extraLarge") with options applied: size, scale, weight,
    // italic, width, fill, grade, capitalisation, letterSpacing, vaxis ([tag, value]) and vaxes (a
    // map). Like upstream's chain of FontBuilder calls on `Tokens.font.<style>.builders.<size>`.
    function styled(style: string, sizeName: string, ops: var): font {
        let s = root.font.body;
        if (style === "headline")
            s = root.font.headline;
        else if (style === "title")
            s = root.font.title;
        else if (style === "label")
            s = root.font.label;
        else if (style === "mono")
            s = root.font.mono;
        else if (style === "icon")
            s = root.font.icon;
        return FB.styled(s, sizeName, ops);
    }

    // A font with only the family set, like upstream's `QFont f; f.setFamily(...)`, with the
    // options of styled() applied.
    function clockFont(ops: var): font {
        return FB.builtFrom(FB.make(SS.get(GlobalConfig.appearance, "font.clock"), 12, Font.Normal, false, {}), ops);
    }
    // The master UI scale from shell-tokens.json: a number, or "auto" (1 / devicePixelRatio^0.6,
    // clamped to 0.6..1). A missing, zero or invalid value means 1. Not in upstream.
    readonly final property real dpr: SS.primaryDpr()
    readonly final property real scale: {
        const v = TokenConfig.scale;
        if (v === "auto")
            return Math.min(1, Math.max(0.6, 1 / Math.pow(dpr, 0.6)));
        const n = Number(v);
        return n > 0 && isFinite(n) ? n : 1;
    }
    readonly final property real fontScale: TokenConfig.fontScale > 0 ? TokenConfig.fontScale : 1
    readonly final property real roundingScale: TokenConfig.roundingScale > 0 ? TokenConfig.roundingScale : 1

    // Scales a hard-coded design pixel value by `scale`, for literals in module files.
    function px(value: real): int {
        return Math.round(value * scale);
    }

    readonly final property ScaledTokens rounding: ScaledTokens {
        source: SS.get(TokenConfig.appearance, "rounding")
        scale: SS.get(GlobalConfig.appearance, "rounding.scale") * root.scale * root.roundingScale
    }
    readonly final property ScaledTokens spacing: ScaledTokens {
        source: SS.get(TokenConfig.appearance, "spacing")
        scale: SS.get(GlobalConfig.appearance, "spacing.scale") * root.scale
    }
    readonly final property ScaledTokens padding: ScaledTokens {
        source: SS.get(TokenConfig.appearance, "padding")
        scale: SS.get(GlobalConfig.appearance, "padding.scale") * root.scale
    }
    // Transparency is always global upstream too
    readonly final property TransparencyTokens transparency: TransparencyTokens {
        source: SS.get(GlobalConfig.appearance, "transparency")
    }
    readonly final property SizeTokens sizes: SizeTokens {
        source: TokenConfig.sizes
        scale: root.scale
    }
    readonly final property AnimTokens anim: AnimTokens {}

    readonly final property TokenFonts font: TokenFonts {
        fontScale: SS.get(GlobalConfig.appearance, "font.scale") * root.scale * root.fontScale
    }
}
