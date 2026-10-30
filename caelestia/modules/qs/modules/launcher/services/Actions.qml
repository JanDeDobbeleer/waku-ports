pragma Singleton

import ".."
import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Services
import qs.services
import qs.utils

Searcher {
    id: root

    // Runs the row named `name` (case insensitive) as selecting it does. Returns what happened.
    // Hidden dangerous rows are refused here, the same as in the row's own handler.
    function invoke(name: string): string {
        const wanted = name.toLowerCase();
        const cfg = GlobalConfig.launcher.actions.values.find(a => a.enabled && (a.name ?? "").toLowerCase() === wanted);
        if (!cfg)
            return `no action named ${name}`;
        if (cfg.dangerous && !GlobalConfig.launcher.enableDangerousActions) {
            console.warn(`REFUSED launcher action ${cfg.name}: launcher.enableDangerousActions is false`);
            return "refused: dangerous actions are disabled";
        }
        const row = variants.instances.find(a => a.name.toLowerCase() === wanted);
        if (!row)
            return `no row for ${name}`;
        row.run(null, null);
        return "ok";
    }

    function transformSearch(search: string): string {
        return search.slice(GlobalConfig.launcher.actionPrefix.length);
    }

    list: variants.instances
    useFuzzy: GlobalConfig.launcher.useFuzzy.actions

    Variants {
        id: variants

        model: {
            const enableDangerous = GlobalConfig.launcher.enableDangerousActions;
            // wabar gap: the nexus settings window is not ported; its action is hidden.
            return GlobalConfig.launcher.actions.values.filter(a => a.enabled && (enableDangerous || !a.dangerous) && !(a.command ?? []).includes("nexus"));
        }

        Action {}
    }

    component Action: QtObject {
        required property var modelData
        readonly property string name: modelData.name ? Tr.trMarked(modelData.name) : Tr.trCtx("Unnamed", "launcher action with no name")
        readonly property string desc: modelData.description ? Tr.trMarked(modelData.description) : Tr.trCtx("No description", "launcher action with no description")
        readonly property string icon: modelData.icon ?? "help_outline"
        readonly property list<string> command: modelData.command ?? []
        readonly property bool enabled: modelData.enabled ?? true
        readonly property bool dangerous: modelData.dangerous ?? false

        function onClicked(list: AppList): void {
            run(list.screenState, list.search);
        }

        // Selecting the row. `screenState` and `search` are null when the debug IPC runs it.
        function run(screenState: var, search: var): void {
            if (command.length === 0)
                return;
            if (dangerous && !GlobalConfig.launcher.enableDangerousActions) {
                console.warn(`REFUSED launcher action ${name}: launcher.enableDangerousActions is false`);
                return;
            }

            if (command[0] === "autocomplete" && command.length > 1) {
                if (search)
                    search.text = `${GlobalConfig.launcher.actionPrefix}${command[1]} `;
                return;
            }
            if (screenState)
                screenState.launcher = false;
            if (command[0] === "setMode" && command.length > 1) {
                Colours.setMode(command[1]);
            } else if (SessionManager.exec(command, true)) {
                return;
            } else if (command[0] === "caelestia" && command[1] === "wallpaper" && command[2] === "-r") {
                WallpaperService.setRandom();
            } else {
                // wabar gap: the other commands call Linux tools.
                console.warn("Launcher: no Windows counterpart for", command.join(" "));
            }
        }
    }
}
