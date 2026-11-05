pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import waku.services as S

// The apps pinned to the Start menu, saved in %LOCALAPPDATA%\waku\start12_pins.json (outside the
// config home, so saving does not reload the shell). The first time, the list is the apps you launch
// most (the engine's own ranking); after that it is yours: pin and unpin from the right-click menu.
QtObject {
    id: root

    property var ids: []
    property bool loaded: false      // the file was read (or found missing)
    property bool exists: false      // the file exists
    readonly property string path: Quickshell.env("LOCALAPPDATA") + "/waku/start12_pins.json"

    function has(id) {
        return ids.indexOf(id) >= 0;
    }

    function save(next) {
        ids = next;
        exists = true;
        file.setText(JSON.stringify({ ids: next }));
    }

    function toggle(id) {
        save(has(id) ? ids.filter(x => x !== id) : ids.concat([id]));
    }

    // Start from the apps used most, once the catalogue has loaded.
    function seed() {
        if (!loaded || exists || !S.AppsService.ready)
            return;
        const top = S.AppsService.search("", 15).map(e => e.id);
        if (top.length > 0)
            save(top);
    }

    readonly property bool ready: S.AppsService.ready
    onReadyChanged: seed()
    onLoadedChanged: seed()

    property FileView file: FileView {
        path: root.path
        printErrors: false
        onLoaded: {
            try {
                root.ids = JSON.parse(text()).ids || [];
                root.exists = true;
            } catch (e) {
                root.ids = [];
            }
            root.loaded = true;
        }
        onLoadFailed: {
            root.loaded = true;
        }
    }
}
