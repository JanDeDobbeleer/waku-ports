pragma Singleton

import QtQuick
import Celeste.Config

// Stub for celeste's C++ Lyrics service (local .lrc files, lrclib and NetEase lookups).
// waku gap: no lookup runs. `lyrics` stays empty, `hasLyrics` false, and `loading` false.
// The properties and methods exist so the lyrics widgets load.
QtObject {
    property var lyrics: []
    property int backend: 0
    property int preferredBackend: 0
    property var lyricCandidates: []
    property var selectedCandidate: ({
            title: "",
            artist: "",
            album: ""
        })
    readonly property bool loading: false
    readonly property bool hasLyrics: lyrics.length > 0
    property real offset: 0
    readonly property string trackArtist: ""
    readonly property string trackTitle: ""

    function indexForTime(time: real): int {
        return -1;
    }

    function timeForIndex(index: int): real {
        return 0;
    }

    function setTrack(artist: string, title: string, album: string, duration: real): void {
    }

    function clearTrack(): void {
    }

    function refresh(): void {
    }
}
