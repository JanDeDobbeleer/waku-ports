pragma Singleton

import Quickshell
import Celeste.Config
import Celeste.Models
import qs.utils

Searcher {
    id: root

    function launch(entry: DesktopEntry): void {
        appDb.incrementFrequency(entry.id);
        // waku: DesktopEntry.execute starts the shortcut or Store app; there is no terminal wrapper.
        entry.execute();
    }

    // Port: Shift+Enter. A new window even when the app runs (Enter raises the running one).
    // executeNew is a waku extension of DesktopEntry; plain Quickshell falls back to execute.
    function launchNew(entry: DesktopEntry): void {
        appDb.incrementFrequency(entry.id);
        if (entry.executeNew)
            entry.executeNew();
        else
            entry.execute();
    }

    // Port: Ctrl+Shift+Enter. Runs the "admin" action of the entry (UAC prompt). False when the
    // entry has none (Store apps without an execution alias).
    function launchAdmin(entry: DesktopEntry): bool {
        const action = Array.from(entry.actions ?? []).find(a => a.id === "admin");
        if (!action)
            return false;
        appDb.incrementFrequency(entry.id);
        action.execute();
        return true;
    }

    function search(search: string): var {
        const prefix = GlobalConfig.launcher.specialPrefix;

        if (search.startsWith(`${prefix}i `)) {
            keys = ["id", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}c `)) {
            keys = ["categories", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}d `)) {
            keys = ["comment", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}e `)) {
            keys = ["execString", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}w `)) {
            keys = ["startupClass", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}g `)) {
            keys = ["genericName", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}k `)) {
            keys = ["keywords", "name"];
            weights = [0.9, 0.1];
        } else {
            keys = ["name"];
            weights = [1];

            if (!search.startsWith(`${prefix}t `))
                return query(search).map(e => e.entry);
        }

        const results = query(search.slice(prefix.length + 2)).map(e => e.entry);
        if (search.startsWith(`${prefix}t `))
            return results.filter(a => a.runInTerminal);
        return results;
    }

    function selector(item: var): string {
        return keys.map(k => item[k]).join(" ");
    }

    list: appDb.apps
    useFuzzy: GlobalConfig.launcher.useFuzzy.apps

    AppDb {
        id: appDb

        path: `${Paths.state}/apps.sqlite`
        favouriteApps: GlobalConfig.launcher.favouriteApps
        entries: DesktopEntries.applications.values.filter(a => !Strings.testRegexList(GlobalConfig.launcher.hiddenApps, a.id))
    }
}
