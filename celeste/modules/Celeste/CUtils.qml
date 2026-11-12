pragma Singleton

import QtQuick
import Quickshell.Io
import "CUtilsHelpers.js" as CUtilsHelpers

// Port of upstream CUtils (plugin/src/Celeste/cutils.cpp) as a QML singleton.
// Differences: copyFile and deleteFile run cmd.exe and return true without waiting for the
// result; saveItem ignores its crop rectangle; enumToString knows only the Config enums.
QtObject {
    id: root

    readonly final property string version: "celeste-port"
    readonly final property string qtVersion: "6.10"

    // No-op for declaring variable/expression dependencies in QML bindings
    function dependency(value: var): void {
    }

    // saveItem(target, path, onSaved, onFailed) or saveItem(target, path, rect, onSaved, onFailed)
    function saveItem(target: var, path: var, a3: var, a4: var, a5: var): void {
        CUtilsHelpers.saveItem(root, target, path, a3, a4, a5);
    }

    function copyFile(source: var, target: var, overwrite: var): bool {
        return CUtilsHelpers.copyFile(root, source, target, overwrite);
    }

    function deleteFile(path: var): bool {
        return CUtilsHelpers.deleteFile(root, path);
    }

    function toLocalFile(url: var): string {
        const s = String(url);
        if (s.startsWith("file:///"))
            return decodeURIComponent(s.slice(8));
        if (s.startsWith("file://"))
            return "//" + decodeURIComponent(s.slice(7));
        console.warn("CUtils.toLocalFile: given url is not a local file", s);
        return "";
    }

    // NaN (0/0 in the ripple gradient) becomes min: the debug Qt build asserts on a NaN stop position.
    function clamp(value: real, min: real, max: real): real {
        return isNaN(value) ? min : Math.min(Math.max(value, min), max);
    }

    // Enumerator names by setting name. The QML enums cannot be enumerated, so the names are listed here.
    readonly final property var _enums: {
        const display = ["Shapes", "Text", "Icons"];
        const temperature = ["Auto", "Celsius", "Fahrenheit", "Kelvin"];
        const lyrics = ["Auto", "Local", "LRCLIB", "NetEase"];
        return {
            displayType: display,
            specialDisplayType: display,
            capitalisation: ["Preserve", "Upper", "Lower"],
            lyricsBackend: lyrics,
            backend: lyrics,
            gpuType: ["Auto", "Nvidia", "Generic", "None"],
            fullscreen: ["On", "Off"],
            weatherUnits: temperature,
            sensorUnits: temperature,
            dataUnits: ["Binary", "Decimal"],
            clockFormat: ["Auto", "TwelveHour", "TwentyFourHour"],
            wallpaperTransition: ["ChromaticBloom", "ColourDistance", "Crossfade", "Crosshatch", "Crosswarp", "Directional", "DirectionalWipe", "FadeColour", "Glitch", "GlitchDisplace", "HeatMelt", "InkSplash", "InkwellDrop", "Iris", "Morph", "ParametricGlitch", "Perlin", "Pixelate", "PixelfadeWave", "PlasmaFlow", "PolkaDotsCurtain", "PuzzleRight", "RandomSquares", "Smoke", "SoftWarpFade", "VoronoiShatter", "ZoomBlurPull"]
        };
    }

    // Name of an enum value, for the Config enums only: enumToString(Config.background, "wallpaperTransition")
    function enumToString(target: var, property: string, value: var): string {
        const e = _enums[property];
        if (!e) {
            console.warn("CUtils.enumToString: unsupported property", property);
            return "";
        }
        const v = value !== undefined ? Number(value) : Number(target ? target[property] : NaN);
        return e[v] ?? "";
    }

    function findChild(item: var, name: string): var {
        return CUtilsHelpers.findChild(item, name);
    }

    function findChildren(item: var, name: string): var {
        return CUtilsHelpers.findChildren(item, name);
    }

    function findChildrenMatching(item: var, pattern: string): var {
        return CUtilsHelpers.findChildrenMatching(item, pattern);
    }

    function _run(command: var): void {
        CUtilsHelpers.runCommand(root, proc, command);
    }

    final property Component proc: Component {
        Process {
            onExited: destroy()
        }
    }
}
