pragma Singleton

import QtQuick
import Quickshell.Io

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
        let onSaved, onFailed;
        if (typeof a3 === "function") {
            onSaved = a3;
            onFailed = a4;
        } else {
            onSaved = a4;
            onFailed = a5;
        }

        if (!target) {
            console.warn("CUtils.saveItem: a target is required");
            return;
        }
        const file = toLocalFile(path);
        if (!file) {
            console.warn("CUtils.saveItem:", path, "is not a local file");
            return;
        }
        const ok = target.grabToImage(result => {
            if (result.saveToFile(file)) {
                if (onSaved)
                    onSaved(file);
            } else {
                console.warn("CUtils.saveItem: failed to save", file);
                if (onFailed)
                    onFailed(file);
            }
        });
        if (!ok)
            console.warn("CUtils.saveItem: failed to grab", target);
    }

    function copyFile(source: var, target: var, overwrite = true): bool {
        const src = toLocalFile(source);
        const dst = toLocalFile(target);
        if (!src || !dst)
            return false;
        _run(["cmd.exe", "/c", "copy", overwrite ? "/Y" : "/-Y", src.replace(/\//g, "\\"), dst.replace(/\//g, "\\")]);
        return true;
    }

    function deleteFile(path: var): bool {
        const file = toLocalFile(path);
        if (!file)
            return false;
        _run(["cmd.exe", "/c", "del", "/F", "/Q", file.replace(/\//g, "\\")]);
        return true;
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
        return _find(item, c => c.objectName === name, null);
    }

    function findChildren(item: var, name: string): var {
        const out = [];
        _find(item, c => c.objectName === name, out);
        return out;
    }

    function findChildrenMatching(item: var, pattern: string): var {
        const re = new RegExp(pattern);
        const out = [];
        _find(item, c => re.test(c.objectName), out);
        return out;
    }

    // Depth first over the visual children; collects into `out` when given, else returns the first match
    function _find(item: var, match: var, out: var): var {
        if (!item)
            return out ? out : null;
        for (const child of item.children) {
            if (match(child)) {
                if (!out)
                    return child;
                out.push(child);
            }
            const found = _find(child, match, out);
            if (!out && found)
                return found;
        }
        return out ? out : null;
    }

    function _run(command: var): void {
        const p = proc.createObject(root, {
            command: command
        });
        p.running = true;
    }

    final property Component proc: Component {
        Process {
            onExited: destroy()
        }
    }
}
