pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Celeste
import Celeste.Config
import Celeste.I18n
import waku as W
import waku.services as S
import qs.services
import qs.utils
import "WallpaperServiceHelpers.js" as WallpaperServiceHelpers

// The wallpaper list and the current wallpaper. Upstream calls this singleton `Wallpapers`; that
// name is taken by waku.services.Wallpapers, which `import Quickshell` re-exports and which
// shadows any user type of that name, so modules that port `Wallpapers.x` use `WallpaperService.x`.
// The list comes from a read only directory listing of the wallpaper folder
// (GlobalConfig.paths.wallpaperDir), the current wallpaper from waku's Wallpapers service. That
// service is pointed at the same folder (so `wakuc wallpaper next` and the port agree) and
// applies a choice to Windows.
// GlobalConfig.services.wallpaperLockScreen (default true) makes the service also set the Windows
// lock screen picture after each change.
// With CELESTE_DRYRUN=1 a choice only logs `DRYRUN wallpaper set <path>`.
Searcher {
    id: root

    // No bundled picture: when waku reports no current wallpaper, nothing is shown.
    readonly final property string fallback: ""

    final property bool showPreview: false
    readonly final property string current: showPreview ? previewPath : actualCurrent
    final property string previewPath
    final property string actualCurrent: fromWaku(S.Wallpapers.current)
    final property bool previewColourLock
    final property bool pendingPreviewClear

    final property list<QtObject> entries: []

    // The width of the picker's thumbnails; Visual's `thumbnailWidth` default must match.
    readonly final property int thumbnailWidth: 640

    function fromWaku(path: string): string {
        return Paths.slash(path) || fallback;
    }

    function getCategoryFor(w: var): string {
        return WallpaperServiceHelpers.category(w, Paths.wallsdir);
    }

    // Fills waku's thumbnail cache in the background, current wallpaper first, then its neighbours
    // outward (the picker opens on the current one), so the first open shows images at once.
    function prewarmThumbnails(): void {
        WallpaperServiceHelpers.prewarm(entries, actualCurrent, W.Thumbnails, thumbnailWidth);
    }

    function setRandom(): void {
        if (list.length === 0)
            return;
        if (Paths.dryRun || !S.Wallpapers.available) {
            setWallpaper(WallpaperServiceHelpers.randomPath(list, actualCurrent));
            return;
        }
        // The engine picks (never the current one) and plays the transition.
        S.Wallpapers.random();
        Toaster.toast(Tr.tr("Wallpaper changed"), Tr.tr("A random wallpaper"), "casino", Toast.Info, 2500);
    }

    function setWallpaper(path: string): void {
        applyWallpaper(path, false);
    }

    function setWallpaperAllDesktops(path: string): bool {
        return applyWallpaper(path, true);
    }

    function applyWallpaper(path: string, allDesktops: bool): bool {
        if (Paths.dryRun) {
            console.warn(`DRYRUN wallpaper set${allDesktops ? " on all desktops" : ""} ${path}`);
            actualCurrent = path;
            // No S.Wallpapers.currentChanged follows to end the colour lock.
            previewColourLock = false;
        } else if (S.Wallpapers.available) {
            // `actualCurrent` follows S.Wallpapers.current once the change has happened. A change
            // Windows never reports (a failed set) would keep the preview palette on screen, so
            // the lock also ends after a while.
            if (allDesktops) {
                if (!S.Wallpapers.setWallpaperAllDesktops(path)) {
                    previewColourLock = false;
                    Toaster.toast(Tr.tr("Wallpaper unchanged"), Tr.tr("Could not apply to all desktops"), "error", Toast.Info, 2500);
                    return false;
                }
            } else {
                S.Wallpapers.setWallpaper(path);
            }
            if (previewColourLock)
                colourLockTimeout.restart();
        } else {
            if (allDesktops) {
                previewColourLock = false;
                Toaster.toast(Tr.tr("Wallpaper unchanged"), Tr.tr("The Windows wallpaper service is not available"), "error", Toast.Info, 2500);
                return false;
            }
            console.warn("WallpaperService: the Windows wallpaper service is not available; only the shell changes");
            actualCurrent = path;
            previewColourLock = false;
        }
        const name = path.slice(path.lastIndexOf("/") + 1);
        Toaster.toast(Tr.tr("Wallpaper changed"), allDesktops ? Tr.tr("%1 on all desktops").arg(name) : name, "image", Toast.Info, 2500);
        return true;
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
        const old = entries.slice();
        entries = WallpaperServiceHelpers.createEntries(text, Paths.wallsdir, Paths, Images, entryComp, root);
        WallpaperServiceHelpers.destroyEntries(old);
        prewarmTimer.restart();
    }

    // Lists the wallpaper folder again. The folder can change after start: the config that names
    // it loads after this singleton, and a run of the lister does not repeat by itself.
    function rescan(): void {
        if (Paths.wallsdir.length === 0)
            return;
        lister.running = false;
        WallpaperServiceHelpers.startListerLater(Qt, lister);
    }

    Component.onCompleted: {
        rescan();
    }

    // Waits so the warm-up never competes with the start-up; a new list or a new current wallpaper
    // starts it over with the right order.
    Timer {
        id: prewarmTimer

        interval: 3000
        onTriggered: root.prewarmThumbnails()
    }

    onActualCurrentChanged: prewarmTimer.restart()

    Connections {
        function onWallsdirChanged(): void {
            root.rescan();
        }

        target: Paths
    }

    // Both the shell and the engine (wakuc wallpaper next/random, the gallery) use one folder.
    Binding {
        target: S.Wallpapers
        property: "imagePath"
        value: Paths.wallsdir
        when: Paths.wallsdir.length > 0
    }

    // A change also sets the Windows lock screen picture (GlobalConfig.services.wallpaperLockScreen).
    Binding {
        target: S.Wallpapers
        property: "setLockScreen"
        value: GlobalConfig.services.wallpaperLockScreen
    }

    // The picker closed while the lock held: show the current palette once the lock ends. The
    // flag is consumed, so a later picker session starts without it.
    onPreviewColourLockChanged: {
        if (previewColourLock)
            return;
        colourLockTimeout.stop();
        if (pendingPreviewClear) {
            pendingPreviewClear = false;
            Colours.showPreview = false;
        }
    }

    Timer {
        id: colourLockTimeout

        interval: 10000
        onTriggered: root.previewColourLock = false
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
            return WallpaperServiceHelpers.pathsText(root.list);
        }

        target: "wallpaper"
    }

    Connections {
        function onCurrentChanged(): void {
            root.actualCurrent = root.fromWaku(S.Wallpapers.current);
            root.previewColourLock = false;
        }

        target: S.Wallpapers
    }

    // waku gap: no recursive folder model; a directory listing stands in for FileSystemModel.
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
            final property string path
            final property string name
            final property string parentDir
            final property string relativePath
        }
    }
}
