pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Celeste
import Celeste.Config
import Celeste.I18n
import Celeste.State
import waku.services as S
import qs.services
import qs.compat
import qs.utils

// Celeste's colour service over waku's ColorScheme. Upstream reads a scheme.json written by the
// `celeste scheme` CLI. Here the scheme is generated in process from the wallpaper
// (`ColorScheme.fromImage`) or from a fixed seed colour, and the role names get the `m3` prefix
// that celeste's QML expects (`ColorScheme.colors.primary` becomes `palette.m3primary`).
// waku gap: ColorScheme has no success roles and no terminal colours, so `m3success*` and
// `term*` keep the defaults of the M3Palette below. The scheme, seed, variant and mode are kept in
// PersistentState (state/persistent.json in the config home) and restored at startup.
Singleton {
    id: root

    property bool showPreview
    property string scheme: "dynamic"
    // The ColorScheme variant (one of S.ColorScheme.variants).
    property string flavour: "tonalspot"
    // "wallpaper" for the dynamic scheme, else a key of `seeds` (the material scheme).
    property string seed: "wallpaper"
    readonly property var seeds: ({
            "purple": "#6750A4",
            "rose": "#A8627B",
            "teal": "#006A6A",
            "blue": "#1B5EA8",
            "green": "#3B6A3B",
            "orange": "#9C4A00"
        })
    // False until the saved choice is read, so the defaults never overwrite it.
    property bool restored
    readonly property bool light: showPreview ? previewLight : currentLight
    property bool currentLight
    property bool previewLight
    readonly property M3Palette palette: showPreview ? preview : current
    readonly property M3TPalette tPalette: M3TPalette {}
    readonly property M3Palette current: M3Palette {}
    readonly property M3Palette preview: M3Palette {}
    readonly property Transparency transparency: Transparency {}
    property real wallLuminance

    // Used when the wallpaper cannot be read, or the scheme is not "dynamic".
    readonly property color fallbackSeed: "#a8627b"

    property string pendingCurrent
    property string pendingPreview

    function getLuminance(c: color): real {
        if (c.r == 0 && c.g == 0 && c.b == 0)
            return 0;
        return Math.sqrt(0.299 * (c.r ** 2) + 0.587 * (c.g ** 2) + 0.114 * (c.b ** 2));
    }

    function alterColour(c: color, a: real, layer: int): color {
        const luminance = getLuminance(c);

        const offset = (!light || layer == 1 ? 1 : -layer / 2) * (light ? 0.2 : 0.3) * (1 - transparency.base) * (1 + wallLuminance * (light ? (layer == 1 ? 3 : 1) : 2.5));
        const scale = (luminance + offset) / luminance;
        const r = Math.max(0, Math.min(1, c.r * scale));
        const g = Math.max(0, Math.min(1, c.g * scale));
        const b = Math.max(0, Math.min(1, c.b * scale));

        return Qt.rgba(r, g, b, a);
    }

    function layer(c: color, layer: var): color {
        if (!transparency.enabled)
            return c;

        return layer === 0 ? Qt.alpha(c, transparency.base) : alterColour(c, transparency.layers, layer ?? 1);
    }

    function on(c: color): color {
        if (c.hslLightness < 0.5)
            return Qt.hsla(c.hslHue, c.hslSaturation, 0.9, 1);
        return Qt.hsla(c.hslHue, c.hslSaturation, 0.1, 1);
    }

    // Copies a name -> colour map (ColorScheme.colors, or the `colours` of a scheme.json with
    // hex strings) onto a palette, adding the `m3` prefix.
    function applyColours(colours: var, target: var): void {
        for (const [name, colour] of Object.entries(colours)) {
            const propName = name.startsWith("term") ? name : `m3${name}`;
            if (target.hasOwnProperty(propName))
                target[propName] = colour;
        }
    }

    function applyScheme(scheme: var, isPreview: bool): void {
        if (!scheme?.valid)
            return;
        applyColours(scheme.colors, isPreview ? preview : current);
    }

    function samePath(a: string, b: string): bool {
        return a.split("\\").join("/") === b.split("\\").join("/");
    }

    // Builds the palette of the current (or the preview) wallpaper. Image schemes arrive
    // through fromImageFinished.
    function regenerate(isPreview: bool): void {
        const path = isPreview ? WallpaperService.previewPath : WallpaperService.actualCurrent;
        const dark = !(isPreview ? previewLight : currentLight);

        if (scheme === "dynamic" && path) {
            if (isPreview)
                pendingPreview = path;
            else
                pendingCurrent = path;
            S.ColorScheme.fromImage(path, flavour, dark);
        } else {
            // A request still in flight for the wallpaper must not replace this palette.
            if (isPreview)
                pendingPreview = "";
            else
                pendingCurrent = "";
            applyScheme(S.ColorScheme.fromColor(seeds[seed] ?? fallbackSeed, flavour, dark), isPreview);
        }

        if (!isPreview) {
            const lum = path ? S.ColorScheme.luminance(path) : -1;
            wallLuminance = lum < 0 ? 0 : lum;
        }
    }

    // Loads a scheme.json as the `celeste scheme` CLI writes it.
    function load(data: string, isPreview: bool): void {
        const colours = isPreview ? preview : current;
        const scheme = JSON.parse(data);

        if (!isPreview) {
            root.scheme = scheme.name;
            flavour = scheme.flavour;
            currentLight = scheme.mode === "light";
        } else {
            previewLight = scheme.mode === "light";
        }

        const mapped = {};
        for (const [name, colour] of Object.entries(scheme.colours))
            mapped[name] = `#${colour}`;
        applyColours(mapped, colours);
    }

    // Sets the palette's mode and regenerates the palette for it. A preview palette left on screen
    // after the picker closed would hide the new one, so it goes unless the picker still previews.
    function applyMode(mode: string): void {
        currentLight = mode === "light";
        previewLight = currentLight;
        if (!WallpaperService.showPreview)
            showPreview = false;
        regenerate(false);
    }

    // Switches the Windows app and system light/dark theme through waku's ControlCenter, which
    // only has a toggle: it is toggled when the theme is not the wanted one already.
    function setWindowsTheme(mode: string): void {
        if (Paths.dryRun) {
            console.warn(`DRYRUN theme ${mode} (windows is ${S.ControlCenter.darkMode ? "dark" : "light"})`);
            return;
        }
        if (!S.ControlCenter.available)
            return;
        if (S.ControlCenter.darkMode !== (mode === "dark"))
            S.ControlCenter.toggleTheme();
    }

    // The launcher's Light and Dark: the palette and the Windows theme.
    function setMode(mode: string): void {
        applyMode(mode);
        setWindowsTheme(mode);
        Toaster.toast(mode === "light" ? Tr.tr("Light mode") : Tr.tr("Dark mode"), Tr.tr("Colour scheme and Windows theme"), mode === "light" ? "light_mode" : "dark_mode", Toast.Info, 2500);
    }

    function persist(): void {
        if (!restored)
            return;
        PersistentState.colourScheme = scheme;
        PersistentState.colourSeed = seed;
        PersistentState.colourVariant = flavour;
        PersistentState.colourMode = currentLight ? "light" : "dark";
    }

    // Reads the saved choice once (the file loads asynchronously) and rebuilds the palette.
    // The Windows theme is not touched: only a Light or Dark command changes it.
    function restore(): void {
        if (restored)
            return;
        const saved = PersistentState;
        if (saved.colourScheme === "dynamic" || (saved.colourScheme === "material" && seeds[saved.colourSeed])) {
            scheme = saved.colourScheme;
            seed = scheme === "dynamic" ? "wallpaper" : saved.colourSeed;
        }
        if (S.ColorScheme.variants.includes(saved.colourVariant))
            flavour = saved.colourVariant;
        currentLight = saved.colourMode === "light";
        previewLight = currentLight;
        restored = true;
        regenerate(false);
    }

    onSchemeChanged: persist()
    onSeedChanged: persist()
    onFlavourChanged: persist()
    onCurrentLightChanged: persist()

    readonly property string wallpaperPath: WallpaperService.actualCurrent
    readonly property string previewWallpaperPath: WallpaperService.previewPath

    onWallpaperPathChanged: regenerate(false)
    onPreviewWallpaperPathChanged: {
        if (WallpaperService.showPreview)
            regenerate(true);
    }

    Component.onCompleted: {
        if (PersistentState.file.loaded)
            restore();
        else
            regenerate(false);
    }

    Connections {
        function onLoaded(): void {
            root.restore();
        }

        function onLoadFailed(): void {
            // No saved choice yet: keep the defaults and start saving.
            root.restored = true;
        }

        target: PersistentState.file
    }

    Connections {
        // A result asked for before a mode switch arrives with the old mode; it is dropped, so a
        // late dark scheme never replaces the light one (and the other way round). Only the
        // dynamic scheme takes a wallpaper result, so a late one never replaces a material palette.
        function onFromImageFinished(path: string, scheme: var): void {
            if (root.scheme !== "dynamic")
                return;
            if (root.pendingCurrent && root.samePath(path, root.pendingCurrent) && scheme.dark === !root.currentLight)
                root.applyScheme(scheme, false);
            if (root.pendingPreview && root.samePath(path, root.pendingPreview) && scheme.dark === !root.previewLight) {
                root.applyScheme(scheme, true);
                root.showPreview = WallpaperService.showPreview;
            }
        }

        function onFromImageFailed(path: string, error: string): void {
            console.warn("Colours: no scheme for", path, error);
            if (root.pendingCurrent && root.samePath(path, root.pendingCurrent))
                root.applyScheme(S.ColorScheme.fromColor(root.fallbackSeed, root.flavour, !root.currentLight), false);
        }

        target: S.ColorScheme
    }

    component Transparency: QtObject {
        readonly property bool enabled: Tokens.transparency.enabled
        readonly property real base: Math.max(0, Math.min(1, Tokens.transparency.base - (root.light ? 0.1 : 0)))
        readonly property real layers: Math.max(0, Math.min(1, Tokens.transparency.layers))
    }

    component M3TPalette: QtObject {
        readonly property color m3primary_paletteKeyColor: root.layer(root.palette.m3primary_paletteKeyColor)
        readonly property color m3secondary_paletteKeyColor: root.layer(root.palette.m3secondary_paletteKeyColor)
        readonly property color m3tertiary_paletteKeyColor: root.layer(root.palette.m3tertiary_paletteKeyColor)
        readonly property color m3neutral_paletteKeyColor: root.layer(root.palette.m3neutral_paletteKeyColor)
        readonly property color m3neutral_variant_paletteKeyColor: root.layer(root.palette.m3neutral_variant_paletteKeyColor)
        readonly property color m3background: root.layer(root.palette.m3background, 0)
        readonly property color m3onBackground: root.layer(root.palette.m3onBackground)
        readonly property color m3surface: root.layer(root.palette.m3surface, 0)
        readonly property color m3surfaceDim: root.layer(root.palette.m3surfaceDim, 0)
        readonly property color m3surfaceBright: root.layer(root.palette.m3surfaceBright, 0)
        readonly property color m3surfaceContainerLowest: root.layer(root.palette.m3surfaceContainerLowest)
        readonly property color m3surfaceContainerLow: root.layer(root.palette.m3surfaceContainerLow)
        readonly property color m3surfaceContainer: root.layer(root.palette.m3surfaceContainer)
        readonly property color m3surfaceContainerHigh: root.layer(root.palette.m3surfaceContainerHigh)
        readonly property color m3surfaceContainerHighest: root.layer(root.palette.m3surfaceContainerHighest)
        readonly property color m3onSurface: root.layer(root.palette.m3onSurface)
        readonly property color m3surfaceVariant: root.layer(root.palette.m3surfaceVariant, 0)
        readonly property color m3onSurfaceVariant: root.layer(root.palette.m3onSurfaceVariant)
        readonly property color m3inverseSurface: root.layer(root.palette.m3inverseSurface, 0)
        readonly property color m3inverseOnSurface: root.layer(root.palette.m3inverseOnSurface)
        readonly property color m3outline: root.layer(root.palette.m3outline)
        readonly property color m3outlineVariant: root.layer(root.palette.m3outlineVariant)
        readonly property color m3shadow: root.layer(root.palette.m3shadow)
        readonly property color m3scrim: root.layer(root.palette.m3scrim)
        readonly property color m3surfaceTint: root.layer(root.palette.m3surfaceTint)
        readonly property color m3primary: root.layer(root.palette.m3primary)
        readonly property color m3onPrimary: root.layer(root.palette.m3onPrimary)
        readonly property color m3primaryContainer: root.layer(root.palette.m3primaryContainer)
        readonly property color m3onPrimaryContainer: root.layer(root.palette.m3onPrimaryContainer)
        readonly property color m3inversePrimary: root.layer(root.palette.m3inversePrimary)
        readonly property color m3secondary: root.layer(root.palette.m3secondary)
        readonly property color m3onSecondary: root.layer(root.palette.m3onSecondary)
        readonly property color m3secondaryContainer: root.layer(root.palette.m3secondaryContainer)
        readonly property color m3onSecondaryContainer: root.layer(root.palette.m3onSecondaryContainer)
        readonly property color m3tertiary: root.layer(root.palette.m3tertiary)
        readonly property color m3onTertiary: root.layer(root.palette.m3onTertiary)
        readonly property color m3tertiaryContainer: root.layer(root.palette.m3tertiaryContainer)
        readonly property color m3onTertiaryContainer: root.layer(root.palette.m3onTertiaryContainer)
        readonly property color m3error: root.layer(root.palette.m3error)
        readonly property color m3onError: root.layer(root.palette.m3onError)
        readonly property color m3errorContainer: root.layer(root.palette.m3errorContainer)
        readonly property color m3onErrorContainer: root.layer(root.palette.m3onErrorContainer)
        readonly property color m3success: root.layer(root.palette.m3success)
        readonly property color m3onSuccess: root.layer(root.palette.m3onSuccess)
        readonly property color m3successContainer: root.layer(root.palette.m3successContainer)
        readonly property color m3onSuccessContainer: root.layer(root.palette.m3onSuccessContainer)
        readonly property color m3primaryFixed: root.layer(root.palette.m3primaryFixed)
        readonly property color m3primaryFixedDim: root.layer(root.palette.m3primaryFixedDim)
        readonly property color m3onPrimaryFixed: root.layer(root.palette.m3onPrimaryFixed)
        readonly property color m3onPrimaryFixedVariant: root.layer(root.palette.m3onPrimaryFixedVariant)
        readonly property color m3secondaryFixed: root.layer(root.palette.m3secondaryFixed)
        readonly property color m3secondaryFixedDim: root.layer(root.palette.m3secondaryFixedDim)
        readonly property color m3onSecondaryFixed: root.layer(root.palette.m3onSecondaryFixed)
        readonly property color m3onSecondaryFixedVariant: root.layer(root.palette.m3onSecondaryFixedVariant)
        readonly property color m3tertiaryFixed: root.layer(root.palette.m3tertiaryFixed)
        readonly property color m3tertiaryFixedDim: root.layer(root.palette.m3tertiaryFixedDim)
        readonly property color m3onTertiaryFixed: root.layer(root.palette.m3onTertiaryFixed)
        readonly property color m3onTertiaryFixedVariant: root.layer(root.palette.m3onTertiaryFixedVariant)
    }

    component M3Palette: QtObject {
        property color m3primary_paletteKeyColor: "#a8627b"
        property color m3secondary_paletteKeyColor: "#8e6f78"
        property color m3tertiary_paletteKeyColor: "#986e4c"
        property color m3neutral_paletteKeyColor: "#807477"
        property color m3neutral_variant_paletteKeyColor: "#837377"
        property color m3background: "#191114"
        property color m3onBackground: "#efdfe2"
        property color m3surface: "#191114"
        property color m3surfaceDim: "#191114"
        property color m3surfaceBright: "#403739"
        property color m3surfaceContainerLowest: "#130c0e"
        property color m3surfaceContainerLow: "#22191c"
        property color m3surfaceContainer: "#261d20"
        property color m3surfaceContainerHigh: "#31282a"
        property color m3surfaceContainerHighest: "#3c3235"
        property color m3onSurface: "#efdfe2"
        property color m3surfaceVariant: "#514347"
        property color m3onSurfaceVariant: "#d5c2c6"
        property color m3inverseSurface: "#efdfe2"
        property color m3inverseOnSurface: "#372e30"
        property color m3outline: "#9e8c91"
        property color m3outlineVariant: "#514347"
        property color m3shadow: "#000000"
        property color m3scrim: "#000000"
        property color m3surfaceTint: "#ffb0ca"
        property color m3primary: "#ffb0ca"
        property color m3onPrimary: "#541d34"
        property color m3primaryContainer: "#6f334a"
        property color m3onPrimaryContainer: "#ffd9e3"
        property color m3inversePrimary: "#8b4a62"
        property color m3secondary: "#e2bdc7"
        property color m3onSecondary: "#422932"
        property color m3secondaryContainer: "#5a3f48"
        property color m3onSecondaryContainer: "#ffd9e3"
        property color m3tertiary: "#f0bc95"
        property color m3onTertiary: "#48290c"
        property color m3tertiaryContainer: "#b58763"
        property color m3onTertiaryContainer: "#000000"
        property color m3error: "#ffb4ab"
        property color m3onError: "#690005"
        property color m3errorContainer: "#93000a"
        property color m3onErrorContainer: "#ffdad6"
        property color m3success: "#B5CCBA"
        property color m3onSuccess: "#213528"
        property color m3successContainer: "#374B3E"
        property color m3onSuccessContainer: "#D1E9D6"
        property color m3primaryFixed: "#ffd9e3"
        property color m3primaryFixedDim: "#ffb0ca"
        property color m3onPrimaryFixed: "#39071f"
        property color m3onPrimaryFixedVariant: "#6f334a"
        property color m3secondaryFixed: "#ffd9e3"
        property color m3secondaryFixedDim: "#e2bdc7"
        property color m3onSecondaryFixed: "#2b151d"
        property color m3onSecondaryFixedVariant: "#5a3f48"
        property color m3tertiaryFixed: "#ffdcc3"
        property color m3tertiaryFixedDim: "#f0bc95"
        property color m3onTertiaryFixed: "#2f1500"
        property color m3onTertiaryFixedVariant: "#623f21"
        property color term0: "#353434"
        property color term1: "#ff4c8a"
        property color term2: "#ffbbb7"
        property color term3: "#ffdedf"
        property color term4: "#b3a2d5"
        property color term5: "#e98fb0"
        property color term6: "#ffba93"
        property color term7: "#eed1d2"
        property color term8: "#b39e9e"
        property color term9: "#ff80a3"
        property color term10: "#ffd3d0"
        property color term11: "#fff1f0"
        property color term12: "#dcbc93"
        property color term13: "#f9a8c2"
        property color term14: "#ffd1c0"
        property color term15: "#ffffff"
    }
}
