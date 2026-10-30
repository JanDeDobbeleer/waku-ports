pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Port of upstream PersistentState: values that survive a restart. Stored in state/persistent.json
// in the config home (upstream: the XDG state dir). A change writes the file at once.
QtObject {
    id: root

    property alias wallpaperPlaying: adapter.wallpaperPlaying
    property alias doNotDisturb: adapter.doNotDisturb

    property FileView file: FileView {
        path: Quickshell.shellPath("state/persistent.json")
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        adapter: JsonAdapter {
            id: adapter

            property bool wallpaperPlaying: true
            property bool doNotDisturb: false
        }
    }
}
