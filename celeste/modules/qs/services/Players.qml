pragma Singleton

import QtQml
import Quickshell
import Quickshell.Services.Mpris
import Celeste
import Celeste.Config
import Celeste.I18n
import qs.components.misc
import qs.compat
import "PlayersHelpers.js" as PlayersHelpers

Singleton {
    id: root

    readonly final property list<MprisPlayer> list: PlayersHelpers.players(Mpris.players)
    readonly final property MprisPlayer active: PlayersHelpers.active(props.manualActive, list, GlobalConfig.services)
    property alias manualActive: props.manualActive

    // Dedup key for progressive metadata (e.g. mpv-mpris/yt-dlp player fills title then artist later).
    final property string lastNowPlayingKey: ""

    function getIdentity(player: MprisPlayer): string {
        return PlayersHelpers.getIdentity(player, GlobalConfig.services);
    }

    function getArtUrl(player: MprisPlayer): string {
        return PlayersHelpers.getArtUrl(player);
    }

    // Quickshell only emits postTrackChanged when trackid/url/title change, so late
    // artist updates (common with mpv-mpris + yt-dlp player) never retrigger it. Watch
    // title/artist too and toast once both are usable.
    function maybeToastNowPlaying(): void {
        if (!GlobalConfig.utilities.toasts.nowPlaying)
            return;

        const player = root.active;
        if (!player)
            return;

        const title = player.trackTitle ?? "";
        const artist = player.trackArtist ?? "";
        if (!title || !artist)
            return;

        const key = `${getIdentity(player)}\0${player.uniqueId}\0${title}\0${artist}`;
        if (key === lastNowPlayingKey)
            return;

        lastNowPlayingKey = key;
        Toaster.toast(Tr.tr("Now playing"), Tr.trCtx("%1 - %2", "track artist and title").arg(artist).arg(title), "music_note", Toast.Info, 5000);
    }

    onActiveChanged: lastNowPlayingKey = ""

    Connections {
        function onPostTrackChanged(): void {
            root.maybeToastNowPlaying();
        }

        function onTrackTitleChanged(): void {
            root.maybeToastNowPlaying();
        }

        function onTrackArtistChanged(): void {
            root.maybeToastNowPlaying();
        }

        target: root.active
    }

    PersistentProperties {
        id: props

        final property MprisPlayer manualActive

        reloadableId: "players"
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "mediaToggle"
        description: "Toggle media playback"
        onPressed: {
            const active = root.active;
            PlayersHelpers.invoke(active, "togglePlaying");
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "mediaPrev"
        description: "Previous track"
        onPressed: {
            const active = root.active;
            PlayersHelpers.invoke(active, "previous");
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "mediaNext"
        description: "Next track"
        onPressed: {
            const active = root.active;
            PlayersHelpers.invoke(active, "next");
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "mediaStop"
        description: "Stop media playback"
        onPressed: PlayersHelpers.invoke(root.active, "stop")
    }

    IpcHandler {
        function getActive(prop: string): string {
            const active = root.active;
            return PlayersHelpers.getActiveProperty(active, prop);
        }

        function list(): string {
            return PlayersHelpers.list(root.list, root);
        }

        function play(): void {
            const active = root.active;
            PlayersHelpers.invoke(active, "play");
        }

        function pause(): void {
            const active = root.active;
            PlayersHelpers.invoke(active, "pause");
        }

        function playPause(): void {
            const active = root.active;
            PlayersHelpers.invoke(active, "togglePlaying");
        }

        function previous(): void {
            const active = root.active;
            PlayersHelpers.invoke(active, "previous");
        }

        function next(): void {
            const active = root.active;
            PlayersHelpers.invoke(active, "next");
        }

        function stop(): void {
            PlayersHelpers.invoke(root.active, "stop");
        }

        target: "mpris"
    }
}
