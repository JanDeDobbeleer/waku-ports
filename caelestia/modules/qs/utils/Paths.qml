pragma Singleton

import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import qs.compat

// Windows port of the upstream XDG paths. Everything the shell writes (state, cache, data) lives
// under `<shell dir>/state`, inside the config home, never in the user's profile.
Singleton {
    id: root

    readonly property string home: slash(Quickshell.env("USERPROFILE") || Quickshell.env("HOME"))
    readonly property string pictures: `${home}/Pictures`
    readonly property string videos: `${home}/Videos`

    readonly property string root_: slash(Quickshell.shellDir)
    readonly property string data: `${root_}/state/data`
    readonly property string state: `${root_}/state`
    readonly property string cache: `${root_}/state/cache`
    readonly property string config: `${root_}/config`

    readonly property string imagecache: `${cache}/imagecache`
    readonly property string notifimagecache: `${imagecache}/notifs`
    readonly property string wallsdir: slash(Quickshell.env("CAELESTIA_WALLPAPERS_DIR")) || absolutePath(GlobalConfig.paths.wallpaperDir)
    readonly property string recsdir: slash(Quickshell.env("CAELESTIA_RECORDINGS_DIR")) || `${videos}/Recordings`
    readonly property string libdir: ""

    // Actions that change the machine (wallpaper, sessions) run only when this is set.
    readonly property bool actionsEnabled: Quickshell.env("CAELESTIA_ALLOW_ACTIONS") === "1"

    function slash(path: var): string {
        return String(path ?? "").split("\\").join("/");
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
        const expanded = slash(path).replace(/^~/, home).replace("${HOME}", home).replace("$HOME", home);
        return toLocalFile(expanded);
    }

    function shortenHome(path: string): string {
        return path.replace(home, "~");
    }
}
