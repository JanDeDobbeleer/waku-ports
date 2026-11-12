import QtQuick

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
        counts[id] = (counts[id] ?? 0) + 1;
        for (const app of sorted) {
            if (app.appId === id)
                app.frequency = counts[id];
        }
        resort();
    }

    function isFavourite(id: string): bool {
        for (const pattern of favouriteApps ?? []) {
            try {
                if (new RegExp(pattern).test(id))
                    return true;
            } catch (e) {
            }
        }
        return false;
    }

    final property var cache: ({})

    function rebuild(): void {
        const next = {};
        const list = [];
        for (const e of entries ?? []) {
            if (!e)
                continue;
            const id = e.id;
            let app = cache[id];
            if (!app || app.entry !== e)
                app = entryComponent.createObject(root, {
                    entry: e,
                    frequency: counts[id] ?? 0
                });
            next[id] = app;
            list.push(app);
        }
        for (const id in cache) {
            if (next[id] !== cache[id])
                cache[id].destroy();
        }
        cache = next;
        sorted = list;
        resort();
    }

    function resort(): void {
        const list = [...sorted];
        const fav = new Map(list.map(a => [a, isFavourite(a.appId)]));
        list.sort((a, b) => {
            if (fav.get(a) !== fav.get(b))
                return fav.get(a) ? -1 : 1;
            if (a.frequency !== b.frequency)
                return b.frequency - a.frequency;
            return a.name.localeCompare(b.name);
        });
        sorted = list;
    }
}
