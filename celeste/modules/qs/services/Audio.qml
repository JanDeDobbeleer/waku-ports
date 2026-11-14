pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Celeste
import Celeste.Config
import Celeste.I18n
import qs.compat
import "AudioHelpers.js" as H

Singleton {
    id: root

    final property string previousSinkName: ""
    final property string previousSourceName: ""

    final property list<PwNode> sinks: []
    final property list<PwNode> sources: []
    final property list<PwNode> streams: []

    readonly final property PwNode sink: Pipewire.defaultAudioSink
    readonly final property PwNode source: Pipewire.defaultAudioSource

    readonly final property bool muted: !!sink?.audio?.muted
    readonly final property real volume: sink?.audio?.volume ?? 0

    readonly final property bool sourceMuted: !!source?.audio?.muted
    readonly final property real sourceVolume: source?.audio?.volume ?? 0

    // waku gap: no audio capture. cava and the beat tracker keep upstream's names and stay silent.
    readonly property alias cava: cava
    readonly property alias beatTracker: beatTracker

    function setVolume(newVolume: real): void {
        if (sink?.ready && sink?.audio) {
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(GlobalConfig.services.maxVolume, newVolume));
        }
    }

    function incrementVolume(amount: real): void {
        setVolume(volume + (amount || GlobalConfig.services.audioIncrement));
    }

    function decrementVolume(amount: real): void {
        setVolume(volume - (amount || GlobalConfig.services.audioIncrement));
    }

    function setSourceVolume(newVolume: real): void {
        if (source?.ready && source?.audio) {
            source.audio.muted = false;
            source.audio.volume = Math.max(0, Math.min(GlobalConfig.services.maxVolume, newVolume));
        }
    }

    function incrementSourceVolume(amount: real): void {
        setSourceVolume(sourceVolume + (amount || GlobalConfig.services.audioIncrement));
    }

    function decrementSourceVolume(amount: real): void {
        setSourceVolume(sourceVolume - (amount || GlobalConfig.services.audioIncrement));
    }

    function setAudioSink(newSink: PwNode): void {
        Pipewire.preferredDefaultAudioSink = newSink;
    }

    function setAudioSource(newSource: PwNode): void {
        Pipewire.preferredDefaultAudioSource = newSource;
    }

    function cycleNextAudioOutput(): void {
        if (sinks.length === 0)
            return;

        let currentIndex = -1;
        for (let i = 0; i < sinks.length; i++) {
            if (sinks[i] === sink)
                currentIndex = i;
        }
        const nextIndex = (currentIndex + 1) % sinks.length;
        setAudioSink(sinks[nextIndex]);
    }

    function setStreamVolume(stream: PwNode, newVolume: real): void {
        if (stream?.ready && stream?.audio) {
            stream.audio.muted = false;
            stream.audio.volume = Math.max(0, Math.min(GlobalConfig.services.maxVolume, newVolume));
        }
    }

    function setStreamMuted(stream: PwNode, muted: bool): void {
        if (stream?.ready && stream?.audio) {
            stream.audio.muted = muted;
        }
    }

    function getStreamVolume(stream: PwNode): real {
        return stream?.audio?.volume ?? 0;
    }

    function getStreamMuted(stream: PwNode): bool {
        return !!stream?.audio?.muted;
    }

    function getStreamName(stream: PwNode): string {
        if (!stream)
            return Tr.trCtx("Unknown", "unknown audio stream");
        // Try application name first, then description, then name
        return H.streamName(stream) || Tr.trCtx("Unknown application", "unknown application audio stream");
    }

    function refreshNodes(): void {
        H.refreshNodes(Pipewire.nodes.values, root);
    }

    onSinkChanged: {
        if (!sink?.ready)
            return;

        const newSinkName = sink.description || sink.name || Tr.trCtx("Unknown device", "unknown audio device");

        if (previousSinkName && previousSinkName !== newSinkName && GlobalConfig.utilities.toasts.audioOutputChanged)
            Toaster.toast(Tr.tr("Audio output changed"), Tr.tr("Now using: %1").arg(newSinkName), "volume_up", Toast.Info, 5000);

        previousSinkName = newSinkName;
    }

    onSourceChanged: {
        if (!source?.ready)
            return;

        const newSourceName = source.description || source.name || Tr.trCtx("Unknown device", "unknown audio device");

        if (previousSourceName && previousSourceName !== newSourceName && GlobalConfig.utilities.toasts.audioInputChanged)
            Toaster.toast(Tr.tr("Audio input changed"), Tr.tr("Now using: %1").arg(newSourceName), "mic", Toast.Info, 5000);

        previousSourceName = newSourceName;
    }

    // Populate immediately: Pipewire.nodes may already be filled by the time this
    // lazily-loaded singleton is created, so onValuesChanged would never fire.
    Component.onCompleted: {
        refreshNodes();
        previousSinkName = sink?.description || sink?.name || Tr.trCtx("Unknown device", "unknown audio device");
        previousSourceName = source?.description || source?.name || Tr.trCtx("Unknown device", "unknown audio device");
    }

    Connections {
        function onValuesChanged(): void {
            root.refreshNodes();
        }

        target: Pipewire.nodes
    }

    // Always track the current defaults so volume/mute bind even if the lists
    // momentarily lag behind the default node.
    PwObjectTracker {
        objects: H.trackable(root.sink, root.source, root.sinks, root.sources, root.streams)
    }

    QtObject {
        id: cava

        readonly final property int bars: GlobalConfig.services.visualiserBars
        readonly final property var values: H.zeros(bars)
    }

    QtObject {
        id: beatTracker

        readonly final property real bpm: 0
    }

    IpcHandler {
        function cycleOutput(): void {
            root.cycleNextAudioOutput();
        }

        target: "audio"
    }
}
