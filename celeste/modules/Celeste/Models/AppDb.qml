import QtQuick
import "AppDbHelpers.js" as AppDbHelpers

// Port of celeste's C++ AppDb: wraps DesktopEntry objects as AppEntry objects and sorts them by
// favourite (the id matches a regex of favouriteApps), then launch count, then name.
// waku gap: counts live in memory only (the original keeps them in an SQLite file at `path`).
// `path` is accepted and ignored.
QtObject {
    id: root

    readonly final property string uuid: "appdb"
    final property string path
    final property var entries: []
    final property var favouriteApps: []
    readonly final property var apps: sorted

    final property var counts: ({})
    final property var sorted: []

    final property Component entryComponent: Component {
        AppEntry {}
    }

    onEntriesChanged: rebuild()
    onFavouriteAppsChanged: resort()

    function incrementFrequency(id: string): void {
        AppDbHelpers.incrementFrequency(root, id);
    }

    function isFavourite(id: string): bool {
        return AppDbHelpers.isFavourite(favouriteApps, id);
    }

    final property var cache: ({})

    function rebuild(): void {
        AppDbHelpers.rebuild(root);
    }

    function resort(): void {
        AppDbHelpers.resort(root);
    }
}
