pragma Singleton

import QtQuick
import Quickshell
import Celeste.Config
import Celeste.I18n
import Celeste.Services
import qs.services
import qs.utils
import "ActionsHelpers.js" as ActionsHelpers

Searcher {
    id: root

    // Runs the row named `name` (case insensitive) as selecting it does. Returns what happened.
    // Hidden dangerous rows are refused here, the same as in the row's own handler.
    function invoke(name: string): string {
        return ActionsHelpers.invoke(name, GlobalConfig.launcher, variants.instances);
    }

    function transformSearch(search: string): string {
        return search.slice(GlobalConfig.launcher.actionPrefix.length);
    }

    list: variants.instances
    useFuzzy: GlobalConfig.launcher.useFuzzy.actions

    Variants {
        id: variants

        model: ActionsHelpers.visibleActions(GlobalConfig.launcher)

        Action {}
    }

    component Action: QtObject {
        id: actionItem

        required final property var modelData
        readonly final property string name: ActionsHelpers.displayName(modelData, Tr)
        readonly final property string desc: ActionsHelpers.displayDescription(modelData, Tr)
        readonly final property string icon: ActionsHelpers.icon(modelData)
        readonly final property list<string> command: ActionsHelpers.command(modelData)
        readonly final property bool enabled: ActionsHelpers.enabled(modelData)
        readonly final property bool dangerous: ActionsHelpers.dangerous(modelData)

        function onClicked(list: var): void {
            ActionsHelpers.onClicked(list, run);
        }

        // Selecting the row. `screenState` and `search` are null when the debug IPC runs it.
        function run(screenState: var, search: var): void {
            ActionsHelpers.run(actionItem, screenState, search, GlobalConfig, Colours, SessionManager, WallpaperService);
        }
    }
}
