pragma Singleton

import QtQuick

// Port of upstream Config, an attached type there (per-screen merged settings). Here it is one
// singleton over GlobalConfig: no per-screen overrides and no `Config.screen`. Upstream code that
// says `root.Config.x` must say `Config.x` (see tools/strip-attached.ps1).
QtObject {
    readonly property bool enabled: GlobalConfig.enabled

    readonly property var appearance: GlobalConfig.appearance
    readonly property var general: GlobalConfig.general
    readonly property var background: GlobalConfig.background
    readonly property var bar: GlobalConfig.bar
    readonly property var border: GlobalConfig.border
    readonly property var dashboard: GlobalConfig.dashboard
    readonly property var launcher: GlobalConfig.launcher
    readonly property var lock: GlobalConfig.lock
    readonly property var nexus: GlobalConfig.nexus
    readonly property var notifs: GlobalConfig.notifs
    readonly property var osd: GlobalConfig.osd
    readonly property var services: GlobalConfig.services
    readonly property var session: GlobalConfig.session
    readonly property var sidebar: GlobalConfig.sidebar
    readonly property var utilities: GlobalConfig.utilities
    readonly property var paths: GlobalConfig.paths

    function forScreen(screen: string): var {
        return GlobalConfig;
    }
}
