pragma Singleton

import QtQuick

// Port of upstream Config, an attached type there (per-screen merged settings). Here it is one
// singleton over GlobalConfig: no per-screen overrides and no `Config.screen`. Upstream code that
// says `root.Config.x` must say `Config.x` (see tools/strip-attached.ps1).
QtObject {
    readonly property bool enabled: GlobalConfig.enabled

    readonly property GlobalConfig.AppearanceCfg appearance: GlobalConfig.appearance
    readonly property GlobalConfig.GeneralCfg general: GlobalConfig.general
    readonly property GlobalConfig.BackgroundCfg background: GlobalConfig.background
    readonly property GlobalConfig.BarCfg bar: GlobalConfig.bar
    readonly property GlobalConfig.BorderCfg border: GlobalConfig.border
    readonly property GlobalConfig.DashboardCfg dashboard: GlobalConfig.dashboard
    readonly property GlobalConfig.LauncherCfg launcher: GlobalConfig.launcher
    readonly property GlobalConfig.LockCfg lock: GlobalConfig.lock
    readonly property GlobalConfig.NexusCfg nexus: GlobalConfig.nexus
    readonly property GlobalConfig.NotifsCfg notifs: GlobalConfig.notifs
    readonly property GlobalConfig.OsdCfg osd: GlobalConfig.osd
    readonly property GlobalConfig.ServicesCfg services: GlobalConfig.services
    readonly property GlobalConfig.SessionCfg session: GlobalConfig.session
    readonly property GlobalConfig.SidebarCfg sidebar: GlobalConfig.sidebar
    readonly property GlobalConfig.UtilitiesCfg utilities: GlobalConfig.utilities
    readonly property GlobalConfig.PathsCfg paths: GlobalConfig.paths

    function forScreen(screen: string): var {
        return GlobalConfig;
    }
}
