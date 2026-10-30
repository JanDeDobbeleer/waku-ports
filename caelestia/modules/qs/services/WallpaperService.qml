pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import wabar.services as S
import qs.services
import qs.utils

// The wallpaper list and the current wallpaper. Upstream calls this singleton `Wallpapers`; that
// name is taken by wabar.services.Wallpapers, which `import Quickshell` re-exports and which
// shadows any user type of that name, so modules that port `Wallpapers.x` use `WallpaperService.x`. The list comes from a read only directory
// listing of the wallpaper folder (GlobalConfig.paths.wallpaperDir), the current wallpaper from
// wabar's Wallpapers service. Setting a wallpaper changes the shell's own view; it reaches Windows
// only when CAELESTIA_ALLOW_ACTIONS=1 is set (see Paths.actionsEnabled).
Searcher {
    id: root

    readonly property string fallback: Paths.slash(Quickshell.shellPath("assets/wallpaper.webp"))

    property bool showPreview: false
    readonly property string current: showPreview ? previewPath : actualCurrent
    property string previewPath
    property string actualCurrent: fromWabar(S.Wallpapers.current)
    property bool previewColourLock
    property bool pendingPreviewClear

    property list<QtObject> entries: []

    function fromWabar(path: string): string {
        return Paths.slash(path) || fallback;
    }

    function getCategoryFor(w: var): string {
        let category = w.parentDir.slice(Paths.wallsdir.length + 1);
        if (category.includes("/"))
            category = category.slice(0, category.indexOf("/"));
        return category;
    }

    function setRandom(): void {
        if (list.length === 0)
            return;
        setWallpaper(list[Math.floor(Math.random() * list.length)].path);
    }

    function setWallpaper(path: string): void {
        actualCurrent = path;
        if (Paths.actionsEnabled)
            S.Wallpapers.setWallpaper(path);
    }

    function preview(path: string): void {
        previewPath = path;
        showPreview = true;

        if (Colours.scheme === "dynamic")
            Colours.regenerate(true);
    }

    function stopPreview(): void {
        showPreview = false;
        if (previewColourLock)
            pendingPreviewClear = true;
        else
            Colours.showPreview = false;
    }

    // Parses the output of `dir /s /b /a-d` into entries.
    function setEntries(text: string): void {
        const base = Paths.wallsdir;
        const old = entries;
        const next = [];
        for (const line of text.split(/\r?\n/)) {
            const path = Paths.slash(line.trim());
            if (!path || !Images.isValidImageByName(path))
                continue;
            const slash = path.lastIndexOf("/");
            next.push(entryComp.createObject(root, {
                path: path,
                name: path.slice(slash + 1),
                parentDir: path.slice(0, slash),
                relativePath: path.startsWith(base + "/") ? path.slice(base.length + 1) : path
            }));
        }
        entries = next;
        for (const o of old)
            o.destroy();
    }

    onPreviewColourLockChanged: {
        if (!previewColourLock && pendingPreviewClear)
            Colours.showPreview = false;
    }

    list: entries
    key: "relativePath"
    useFuzzy: GlobalConfig.launcher.useFuzzy.wallpapers
    extraOpts: useFuzzy ? ({}) : ({
            forward: false
        })

    IpcHandler {
        function get(): string {
            return root.actualCurrent;
        }

        function set(path: string): void {
            root.setWallpaper(path);
        }

        function list(): string {
            return root.list.map(w => w.path).join("\n");
        }

        target: "wallpaper"
    }

    Connections {
        function onCurrentChanged(): void {
            root.actualCurrent = root.fromWabar(S.Wallpapers.current);
            root.previewColourLock = false;
        }

        target: S.Wallpapers
    }

    // wabar gap: no recursive folder model; a directory listing stands in for FileSystemModel.
    Process {
        id: lister

        running: Paths.wallsdir.length > 0
        command: ["cmd.exe", "/c", "dir", "/s", "/b", "/a-d", Paths.wallsdir.split("/").join("\\")]
        stdout: StdioCollector {
            onStreamFinished: root.setEntries(text)
        }
    }

    Component {
        id: entryComp

        QtObject {
            property string path
            property string name
            property string parentDir
            property string relativePath
        }
    }
}
