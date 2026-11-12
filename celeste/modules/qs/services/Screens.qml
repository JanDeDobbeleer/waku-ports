pragma Singleton

import Quickshell
import Celeste.Config
import qs.compat
import "ScreensHelpers.js" as ScreensHelpers

Singleton {
    id: root

    readonly final property list<ShellScreen> screens: ScreensHelpers.enabledScreens(Quickshell.screens, GlobalConfig)

    function isExcluded(screen: ShellScreen): bool {
        return ScreensHelpers.isExcluded(screen, GlobalConfig);
    }
}
