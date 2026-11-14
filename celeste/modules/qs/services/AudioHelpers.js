.pragma library

// qmlcachegen cannot compile property reads from plain objects, spreads or untyped arrows.

function streamName(stream) {
    return stream.properties["application.name"] || stream.description || stream.name;
}

function refreshNodes(nodes, root) {
    const newSinks = [];
    const newSources = [];
    const newStreams = [];

    for (const node of nodes) {
        if (!node.isStream) {
            if (node.isSink)
                newSinks.push(node);
            else if (node.audio)
                newSources.push(node);
        } else if (node.audio) {
            newStreams.push(node);
        }
    }

    root.sinks = newSinks;
    root.sources = newSources;
    root.streams = newStreams;
}

function trackable(sink, source, sinks, sources, streams) {
    return [sink, source, ...sinks, ...sources, ...streams].filter(n => n);
}

function zeros(length) {
    return Array.from({
        length: length
    }, () => 0);
}
