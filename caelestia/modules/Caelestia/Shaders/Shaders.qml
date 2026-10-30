pragma Singleton

import QtQuick
import Caelestia.Config

// Port of upstream Shaders: the wallpaper transitions as {url, duration, easing}. The port has no
// compiled transition shaders, so every url is empty and the wallpaper widget cross-fades.
// duration is the unscaled token (upstream scales it at the use site); easing is an easing value.
QtObject {
    function t(file: string, durationName: string, easing: var): var {
        return {
            url: "",
            file: file,
            duration: TokenConfig.appearance.animDurations[durationName],
            easing: easing
        };
    }

    readonly property var chromaticBloom: t("chromatic-bloom", "large", Tokens.anim.linear)
    readonly property var colourDistance: t("colour-distance", "large", Tokens.anim.expressiveSlowEffects)
    readonly property var crossfade: t("crossfade", "large", Tokens.anim.expressiveSlowEffects)
    readonly property var crosshatch: t("crosshatch", "large", Tokens.anim.linear)
    readonly property var crosswarp: t("crosswarp", "large", Tokens.anim.linear)
    readonly property var directional: t("directional", "expressiveSlowEffects", Tokens.anim.expressiveSlowEffects)
    readonly property var directionalWipe: t("directional-wipe", "large", Tokens.anim.linear)
    readonly property var fadeColour: t("fade-colour", "large", Tokens.anim.linear)
    readonly property var glitch: t("glitch", "large", Tokens.anim.linear)
    readonly property var glitchDisplace: t("glitch-displace", "large", Tokens.anim.linear)
    readonly property var heatMelt: t("heat-melt", "large", Tokens.anim.linear)
    readonly property var inkSplash: t("ink-splash", "large", Tokens.anim.linear)
    readonly property var inkwellDrop: t("inkwell-drop", "large", Tokens.anim.linear)
    readonly property var iris: t("iris", "normal", Tokens.anim.emphasizedAccel)
    readonly property var morph: t("morph", "large", Tokens.anim.expressiveSlowEffects)
    readonly property var parametricGlitch: t("parametric-glitch", "large", Tokens.anim.linear)
    readonly property var perlin: t("perlin", "normal", Tokens.anim.linear)
    readonly property var pixelate: t("pixelate", "large", Tokens.anim.linear)
    readonly property var pixelfadeWave: t("pixelfade-wave", "large", Tokens.anim.linear)
    readonly property var plasmaFlow: t("plasma-flow", "large", Tokens.anim.linear)
    readonly property var polkaDotsCurtain: t("polka-dots-curtain", "large", Tokens.anim.linear)
    readonly property var puzzleRight: t("puzzle-right", "large", Tokens.anim.linear)
    readonly property var randomSquares: t("random-squares", "large", Tokens.anim.linear)
    readonly property var smoke: t("smoke", "large", Tokens.anim.linear)
    readonly property var softWarpFade: t("soft-warp-fade", "large", Tokens.anim.linear)
    readonly property var voronoiShatter: t("voronoi-shatter", "large", Tokens.anim.linear)
    readonly property var zoomBlurPull: t("zoom-blur-pull", "large", Tokens.anim.linear)
}
