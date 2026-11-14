import QtQuick
import Qt.labs.folderlistmodel
import "FileSystemModelHelpers.js" as FileSystemModelHelpers

// Port of celeste's C++ FileSystemModel on top of Qt.labs.folderlistmodel. The model has one
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

    final property string path
    final property bool recursive: false
    final property bool watchChanges: true
    final property bool showHidden: false
    final property bool sortReverse: false
    final property int filter: FileSystemModel.NoFilter
    final property var nameFilters: []
    final property var entries: []

    readonly final property var imageSuffixes: ["png", "jpg", "jpeg", "webp", "gif", "bmp", "svg", "avif", "tif", "tiff", "ico", "jxl"]
    readonly final property var videoSuffixes: ["mp4", "webm", "mkv", "mov", "avi", "m4v"]
    readonly final property var mimeBySuffix: ({
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

    readonly final property bool wantImages: (filter & FileSystemModel.Images) !== 0
    readonly final property bool wantVideos: (filter & FileSystemModel.Videos) !== 0
    readonly final property bool wantFiles: (filter & FileSystemModel.Files) !== 0
    readonly final property bool wantDirs: (filter & FileSystemModel.Dirs) !== 0
    readonly final property bool anyFiles: wantImages || wantVideos || wantFiles
    readonly final property var effectiveNameFilters: FileSystemModelHelpers.effectiveNameFilters(nameFilters, wantFiles, wantImages, wantVideos, imageSuffixes, videoSuffixes)

    final property Component entryComponent: Component {
        FileSystemEntry {}
    }

    final property FolderListModel source: FolderListModel {
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
        FileSystemModelHelpers.rebuild(root, source, entryComponent, imageSuffixes, mimeBySuffix);
    }

    dynamicRoles: true
    onPathChanged: scheduleRebuild()
}
