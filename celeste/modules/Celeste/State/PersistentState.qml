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
    // Port: the colour choice of the launcher (Colours restores it at startup).
    property alias colourScheme: adapter.colourScheme
    property alias colourSeed: adapter.colourSeed
    property alias colourVariant: adapter.colourVariant
    property alias colourMode: adapter.colourMode
    // Port: the profile picture chosen in the dashboard (a file path, empty for the Windows account picture).
    property alias faceImage: adapter.faceImage

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
            property string colourScheme: "dynamic" // dynamic or material
            property string colourSeed: "wallpaper" // wallpaper, or a key of Colours.seeds
            property string colourVariant: "tonalspot"
            property string colourMode: "dark" // dark or light
            property string faceImage: ""
        }
    }
}
