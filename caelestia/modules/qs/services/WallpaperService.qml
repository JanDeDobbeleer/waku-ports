pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import wabar.services as S
import qs.services
import qs.utils

// The wallpaper list and the current wallpaper. Upstream calls this singleton `Wallpapers`; that
// name is taken by wabar.services.Wallpapers, which `import Quickshell` re-exports and which
// shadows any user type of that name, so modules that port `Wallpapers.x` use `WallpaperService.x`.
// The list comes from a read only directory listing of the wallpaper folder
// (GlobalConfig.paths.wallpaperDir), the current wallpaper from wabar's Wallpapers service. That
// service is pointed at the same folder (so `wabarc wallpaper next` and the port agree) and
// applies a choice to Windows, with the animation named by GlobalConfig.services.wallpaperAnimation.
// With CAELESTIA_DRYRUN=1 a choice only logs `DRYRUN wallpaper set <path>`.
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

    // The wallpaper animation: "" is the service's own default, "none" turns it off.
    function configureEngine(): void {
        const name = GlobalConfig.services.wallpaperAnimation;
        S.Wallpapers.configureEngine(name !== "none", name === "none" ? "" : name);
    }

    function setRandom(): void {
        if (list.length === 0)
            return;
        if (Paths.dryRun || !S.Wallpapers.available) {
            const others = list.filter(w => w.path !== actualCurrent);
            const pool = others.length > 0 ? others : list;
            setWallpaper(pool[Math.floor(Math.random() * pool.length)].path);
            return;
        }
        // The engine picks (never the current one) and plays the transition.
        S.Wallpapers.random();
        Toaster.toast(Tr.tr("Wallpaper changed"), Tr.tr("A random wallpaper"), "casino", Toast.Success, 2500);
    }

    function setWallpaper(path: string): void {
        if (Paths.dryRun) {
            console.warn(`DRYRUN wallpaper set ${path}`);
            actualCurrent = path;
        } else if (S.Wallpapers.available) {
            // `actualCurrent` follows S.Wallpapers.current once the change has happened.
            S.Wallpapers.setWallpaper(path);
        } else {
            console.warn("WallpaperService: the Windows wallpaper service is not available; only the shell changes");
            actualCurrent = path;
        }
        const name = path.slice(path.lastIndexOf("/") + 1);
        Toaster.toast(Tr.tr("Wallpaper changed"), name, "image", Toast.Success, 2500);
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
        const old = [...entries]; // a copy: a list property read is live
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

    // Lists the wallpaper folder again. The folder can change after start: the config that names
    // it loads after this singleton, and a run of the lister does not repeat by itself.
    function rescan(): void {
        if (Paths.wallsdir.length === 0)
            return;
        lister.running = false;
        Qt.callLater(() => lister.running = true);
    }

    Component.onCompleted: {
        configureEngine();
        rescan();
    }

    Connections {
        function onWallsdirChanged(): void {
            root.rescan();
        }

        target: Paths
    }

    // Both the shell and the engine (wabarc wallpaper next/random, the gallery) use one folder.
    Binding {
        target: S.Wallpapers
        property: "imagePath"
        value: Paths.wallsdir
        when: Paths.wallsdir.length > 0
    }

    Connections {
        function onWallpaperAnimationChanged(): void {
            root.configureEngine();
        }

        target: GlobalConfig.services
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
