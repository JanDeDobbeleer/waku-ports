import QtQuick
import Qt.labs.folderlistmodel

// Port of caelestia's C++ FileSystemModel on top of Qt.labs.folderlistmodel. The model has one
// role, `modelData`, which holds a FileSystemEntry; `entries` is the same list as an array.
// waku gap: `recursive` is accepted and ignored (FolderListModel lists one folder), `Videos`
// matches by suffix only, and `isImage` and `mimeType` are decided from the suffix.
ListModel {
    id: root

    enum Filter {
        NoFilter = 0,
        Images = 1,
        Videos = 2,
        Files = 4,
        Dirs = 8
    }

    property string path
    property bool recursive: false
    property bool watchChanges: true
    property bool showHidden: false
    property bool sortReverse: false
    property int filter: FileSystemModel.NoFilter
    property var nameFilters: []
    property var entries: []

    readonly property var imageSuffixes: ["png", "jpg", "jpeg", "webp", "gif", "bmp", "svg", "avif", "tif", "tiff", "ico", "jxl"]
    readonly property var videoSuffixes: ["mp4", "webm", "mkv", "mov", "avi", "m4v"]
    readonly property var mimeBySuffix: ({
            "png": "image/png",
            "jpg": "image/jpeg",
            "jpeg": "image/jpeg",
            "webp": "image/webp",
            "gif": "image/gif",
            "bmp": "image/bmp",
            "svg": "image/svg+xml",
            "avif": "image/avif",
            "mp4": "video/mp4",
            "webm": "video/webm",
            "mkv": "video/x-matroska",
            "mov": "video/quicktime",
            "avi": "video/x-msvideo",
            "txt": "text/plain",
            "json": "application/json"
        })

    readonly property bool wantImages: (filter & FileSystemModel.Images) !== 0
    readonly property bool wantVideos: (filter & FileSystemModel.Videos) !== 0
    readonly property bool wantFiles: (filter & FileSystemModel.Files) !== 0
    readonly property bool wantDirs: (filter & FileSystemModel.Dirs) !== 0
    readonly property bool anyFiles: wantImages || wantVideos || wantFiles
    readonly property var effectiveNameFilters: {
        const out = [...(nameFilters ?? [])];
        if (!wantFiles && (wantImages || wantVideos)) {
            if (wantImages)
                out.push(...imageSuffixes.map(s => "*." + s));
            if (wantVideos)
                out.push(...videoSuffixes.map(s => "*." + s));
        }
        return out.length > 0 ? out : ["*"];
    }

    property Component entryComponent: Component {
        FileSystemEntry {}
    }

    property FolderListModel source: FolderListModel {
        folder: root.path ? "file:///" + root.path.replace(/\\/g, "/").replace(/^\/+/, "") : ""
        nameFilters: root.effectiveNameFilters
        showFiles: !root.wantDirs || root.anyFiles
        showDirs: !root.anyFiles || root.wantDirs
        showDirsFirst: true
        showHidden: root.showHidden
        sortReversed: root.sortReverse
        showDotAndDotDot: false

        onCountChanged: root.scheduleRebuild()
        onStatusChanged: root.scheduleRebuild()
        onFolderChanged: root.scheduleRebuild()
    }

    function scheduleRebuild(): void {
        Qt.callLater(rebuild);
    }

    function rebuild(): void {
        const old = entries;
        const list = [];
        clear();
        const n = source.status === FolderListModel.Ready ? source.count : 0;
        for (let i = 0; i < n; i++) {
            const suffix = (source.get(i, "fileSuffix") ?? "").toLowerCase();
            const isDir = source.get(i, "fileIsDir");
            const name = source.get(i, "fileName");
            const entry = entryComponent.createObject(root, {
                path: source.get(i, "filePath"),
                relativePath: name,
                name: name,
                baseName: source.get(i, "fileBaseName"),
                parentDir: source.folder.toString().replace(/^file:\/\/\//, ""),
                suffix: suffix,
                size: source.get(i, "fileSize"),
                isDir: isDir,
                isImage: !isDir && imageSuffixes.includes(suffix),
                mimeType: isDir ? "inode/directory" : (mimeBySuffix[suffix] ?? "application/octet-stream")
            });
            list.push(entry);
            append({
                modelData: entry
            });
        }
        entries = list;
        for (const e of old)
            e.destroy();
    }

    dynamicRoles: true
    onPathChanged: scheduleRebuild()
}
