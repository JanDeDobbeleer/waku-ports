.pragma library

function effectiveNameFilters(filters, wantsFiles, wantsImages, wantsVideos, imageSuffixes, videoSuffixes) {
    const result = [];
    for (let i = 0; i < filters.length; i++)
        result.push(filters[i]);
    if (!wantsFiles && (wantsImages || wantsVideos)) {
        if (wantsImages) {
            for (let i = 0; i < imageSuffixes.length; i++)
                result.push("*." + imageSuffixes[i]);
        }
        if (wantsVideos) {
            for (let i = 0; i < videoSuffixes.length; i++)
                result.push("*." + videoSuffixes[i]);
        }
    }
    return result.length > 0 ? result : ["*"];
}

function rebuild(model, source, component, imageSuffixes, mimeBySuffix) {
    const old = model.entries.slice();
    const list = [];
    model.clear();
    const count = source.status === 1 ? source.count : 0;
    for (let i = 0; i < count; i++) {
        const suffix = (source.get(i, "fileSuffix") || "").toLowerCase();
        const isDir = source.get(i, "fileIsDir");
        const name = source.get(i, "fileName");
        const entry = component.createObject(model, {
            path: source.get(i, "filePath"),
            relativePath: name,
            name: name,
            baseName: source.get(i, "fileBaseName"),
            parentDir: source.folder.toString().replace(/^file:\/\//, ""),
            suffix: suffix,
            size: source.get(i, "fileSize"),
            isDir: isDir,
            isImage: !isDir && imageSuffixes.indexOf(suffix) !== -1,
            mimeType: isDir ? "inode/directory" : (mimeBySuffix[suffix] || "application/octet-stream")
        });
        list.push(entry);
        model.append({ modelData: entry });
    }
    model.entries = list;
    for (let i = 0; i < old.length; i++)
        old[i].destroy();
}
