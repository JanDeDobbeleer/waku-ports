pragma Singleton

import QtQuick

// Port of upstream Config, an attached type there (per-screen merged settings). Here it is one
// singleton over GlobalConfig: no per-screen overrides and no `Config.screen`. Upstream code that
// says `root.Config.x` must say `Config.x` (see tools/strip-attached.ps1).
QtObject {
    readonly final property bool enabled: GlobalConfig.enabled

    readonly final property GlobalConfig.AppearanceCfg appearance: GlobalConfig.appearance
    readonly final property GlobalConfig.GeneralCfg general: GlobalConfig.general
    readonly final property GlobalConfig.BackgroundCfg background: GlobalConfig.background
    readonly final property GlobalConfig.BarCfg bar: GlobalConfig.bar
    readonly final property GlobalConfig.BorderCfg border: GlobalConfig.border
    readonly final property GlobalConfig.DashboardCfg dashboard: GlobalConfig.dashboard
    readonly final property GlobalConfig.LauncherCfg launcher: GlobalConfig.launcher
    readonly final property GlobalConfig.LockCfg lock: GlobalConfig.lock
    readonly final property GlobalConfig.NexusCfg nexus: GlobalConfig.nexus
    readonly final property GlobalConfig.NotifsCfg notifs: GlobalConfig.notifs
    readonly final property GlobalConfig.OsdCfg osd: GlobalConfig.osd
    readonly final property GlobalConfig.ServicesCfg services: GlobalConfig.services
    readonly final property GlobalConfig.SessionCfg session: GlobalConfig.session
    readonly final property GlobalConfig.SidebarCfg sidebar: GlobalConfig.sidebar
    readonly final property GlobalConfig.UtilitiesCfg utilities: GlobalConfig.utilities
    readonly final property GlobalConfig.PathsCfg paths: GlobalConfig.paths

    function forScreen(screen: string): var {
        return GlobalConfig;
    }
}
