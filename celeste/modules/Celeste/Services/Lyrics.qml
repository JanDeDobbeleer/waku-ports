pragma Singleton

import QtQuick

// Stub for celeste's C++ Lyrics service (local .lrc files, lrclib and NetEase lookups).
// waku gap: no lookup runs. `lyrics` stays empty, `hasLyrics` false, and `loading` false.
// The properties and methods exist so the lyrics widgets load.
QtObject {
    final property var lyrics: []
    final property int backend: 0
    final property int preferredBackend: 0
    final property var lyricCandidates: []
    final property var selectedCandidate: ({
            title: "",
            artist: "",
            album: ""
        })
    readonly final property bool loading: false
    readonly final property bool hasLyrics: lyrics.length > 0
    final property real offset: 0
    readonly final property string trackArtist: ""
    readonly final property string trackTitle: ""

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
