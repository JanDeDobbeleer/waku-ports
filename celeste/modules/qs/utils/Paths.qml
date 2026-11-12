pragma Singleton

import QtQuick
import Quickshell
import Celeste
import Celeste.Config
import qs.compat

// Windows port of the upstream XDG paths. Everything the shell writes (state, cache, data) lives
// under `<shell dir>/state`, inside the config home, never in the user's profile.
Singleton {
    id: root

    readonly final property string home: slash(Quickshell.env("USERPROFILE") || Quickshell.env("HOME"))
    readonly final property string pictures: `${home}/Pictures`
    readonly final property string videos: `${home}/Videos`

    readonly final property string root_: slash(Quickshell.shellDir)
    readonly final property string dataDir: `${root_}/state/data`
    readonly final property string state: `${root_}/state`
    readonly final property string cache: `${root_}/state/cache`
    readonly final property string config: `${root_}/config`

    readonly final property string imagecache: `${cache}/imagecache`
    readonly final property string notifimagecache: `${imagecache}/notifs`
    readonly final property string wallsdir: slash(Quickshell.env("CELESTE_WALLPAPERS_DIR")) || absolutePath(GlobalConfig.paths.wallpaperDir)
    readonly final property string recsdir: slash(Quickshell.env("CELESTE_RECORDINGS_DIR")) || `${videos}/Recordings`
    readonly final property string libdir: ""

    // Test switch: CELESTE_DRYRUN=1 makes every action that changes the machine (wallpaper,
    // light/dark theme, lock, sleep, shutdown) log a `DRYRUN ...` line and do nothing else.
    readonly final property bool dryRun: Quickshell.env("CELESTE_DRYRUN") === "1"

    function slash(path: var): string {
        // The drive letter is upper case, so two spellings of one path compare equal.
        return String(path ?? "").split("\\").join("/").replace(/^[a-z]:/, m => m.toUpperCase());
    }

    function toLocalFile(path: url): string {
        const plain = slash(path.toString());
        // A drive path is already local. Qt.resolvedUrl would read "c:" as a URL scheme.
        if (/^[A-Za-z]:\//.test(plain))
            return plain;
        path = Qt.resolvedUrl(path);
        return path.toString() ? CUtils.toLocalFile(path) : "";
    }

    function absolutePath(path: string): string {
        // Port: celeste's "root:/" means the shell root, which is the config home here.
        if (path.startsWith("root:/"))
            return toLocalFile(Qt.resolvedUrl("../../../" + path.substring(6)));
        const expanded = slash(path).replace(/^~/, home).replace("${HOME}", home).replace("$HOME", home);
        return toLocalFile(expanded);
    }

    function shortenHome(path: string): string {
        return path.replace(home, "~");
    }
}
