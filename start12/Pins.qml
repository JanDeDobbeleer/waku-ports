pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import waku.services as S
import "Data.js" as Data

// The apps pinned to the Start menu, saved in %LOCALAPPDATA%\waku\start12_pins.json (outside the
// config home, so saving does not reload the shell). The first time, the list is the apps you launch
// most (the engine's own ranking); after that it is yours: pin and unpin from the right-click menu.
QtObject {
    id: root

    property list<string> ids: []
    property bool loaded: false      // the file was read (or found missing)
    property bool exists: false      // the file exists
    readonly property string path: Quickshell.env("LOCALAPPDATA") + "/waku/start12_pins.json"

    function has(id: string): bool {
        return ids.indexOf(id) >= 0;
    }

    function save(next: list<string>): void {
        ids = next;
        exists = true;
        pinsFile.setText(JSON.stringify({ ids: Array.from(next) }));
    }

    function toggle(id: string): void {
        save(has(id) ? Data.without(ids, id) : Array.from(ids).concat([id]));
    }

    // Start from the apps used most, once the catalogue has loaded.
    function seed(): void {
        if (!loaded || exists || !S.AppsService.ready)
            return;
        const top = Data.ids(S.AppsService.search("", 15));
        if (top.length > 0)
            save(top);
    }

    readonly property bool ready: S.AppsService.ready
    onReadyChanged: seed()
    onLoadedChanged: seed()

    property FileView file: FileView {
        id: pinsFile
        path: root.path
        printErrors: false
        onLoaded: {
            const read = Data.pinIds(text());
            root.ids = read || [];
            root.exists = read !== null;
            root.loaded = true;
        }
        onLoadFailed: {
            root.loaded = true;
        }
    }
}
