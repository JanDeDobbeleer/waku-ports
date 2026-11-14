pragma Singleton

import Quickshell
import Celeste.Config
import Celeste.Models
import qs.utils
import "AppsHelpers.js" as AppsHelpers

Searcher {
    id: root

    function launch(entry: DesktopEntry): void {
        AppsHelpers.launch(appDb, entry);
    }

    // Port: Shift+Enter. A new window even when the app runs (Enter raises the running one).
    // executeNew is a waku extension of DesktopEntry; plain Quickshell falls back to execute.
    function launchNew(entry: DesktopEntry): void {
        AppsHelpers.launchNew(appDb, entry);
    }

    // Port: Ctrl+Shift+Enter. Runs the "admin" action of the entry (UAC prompt). False when the
    // entry has none (Store apps without an execution alias).
    function launchAdmin(entry: DesktopEntry): bool {
        return AppsHelpers.launchAdmin(appDb, entry);
    }

    function search(search: string): var {
        return AppsHelpers.search(root, search, GlobalConfig.launcher.specialPrefix);
    }

    function selector(item: var): string {
        return AppsHelpers.selector(keys, item);
    }

    list: appDb.apps
    useFuzzy: GlobalConfig.launcher.useFuzzy.apps

    AppDb {
        id: appDb

        path: `${Paths.state}/apps.sqlite`
        favouriteApps: GlobalConfig.launcher.favouriteApps
        entries: AppsHelpers.visibleEntries(DesktopEntries.applications, GlobalConfig.launcher.hiddenApps, Strings)
    }
}
