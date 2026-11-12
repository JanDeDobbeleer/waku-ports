pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "ConfigList.js" as CL

// Port of upstream's GlobalConfig (the shell.json settings tree). Defaults are the C++ defaults
// of plugin/src/Celeste/Config/*config.hpp. The file is config/shell.json in the config home.
// Differences from upstream: no per-screen overrides (forScreen returns this object), enum
// settings are stored as the integer value of their enum, and the mutators of a list (insert,
// remove, move) change the array in place without notifying bindings.
QtObject {
    id: root

    readonly property bool enabled: true

    function forScreen(screen: string): var {
        return root;
    }

    // Writes the current values back to config/shell.json.
    function save(): void {
        fileView.writeAdapter();
    }

    property alias appearance: adapter.appearance
    property alias general: adapter.general
    property alias background: adapter.background
    property alias bar: adapter.bar
    property alias border: adapter.border
    property alias dashboard: adapter.dashboard
    property alias launcher: adapter.launcher
    property alias lock: adapter.lock
    property alias nexus: adapter.nexus
    property alias notifs: adapter.notifs
    property alias osd: adapter.osd
    property alias services: adapter.services
    property alias session: adapter.session
    property alias sidebar: adapter.sidebar
    property alias utilities: adapter.utilities
    property alias paths: adapter.paths

    readonly property string _home: Quickshell.env("USERPROFILE") || Quickshell.env("HOME") || ""

    component FontCfg: JsonObject {
        final property string family: "" // Empty inherits the style family
        final property int size: 14
        final property int weight: Font.Normal
        final property bool italic: false
        final property var vaxes: ({
                ROND: 25
            })
    }

    component FontStyleCfg: JsonObject {
        final property string family: "Google Sans Flex"
        final property FontCfg large: FontCfg {}
        final property FontCfg medium: FontCfg {}
        final property FontCfg small: FontCfg {}
    }

    component AppearanceRoundingCfg: JsonObject {
        final property real scale: 1
    }

    component AppearanceSpacingCfg: JsonObject {
        final property real scale: 1
    }

    component AppearancePaddingCfg: JsonObject {
        final property real scale: 1
    }

    component AppearanceFontCfg: JsonObject {
        final property real scale: 1
        final property FontStyleCfg headline: FontStyleCfg {
            large: FontCfg {
                size: 32
                weight: Font.Medium
            }
            medium: FontCfg {
                size: 28
                weight: Font.Medium
            }
            small: FontCfg {
                size: 24
                weight: Font.Medium
            }
        }
        final property FontStyleCfg title: FontStyleCfg {
            large: FontCfg {
                size: 22
                weight: Font.Medium
            }
            medium: FontCfg {
                size: 16
                weight: Font.Medium
            }
            small: FontCfg {
                size: 14
                weight: Font.Medium
            }
        }
        final property FontStyleCfg body: FontStyleCfg {
            large: FontCfg {
                size: 16
            }
            medium: FontCfg {
                size: 14
            }
            small: FontCfg {
                size: 12
            }
        }
        final property FontStyleCfg label: FontStyleCfg {
            large: FontCfg {
                size: 14
                weight: Font.Medium
            }
            medium: FontCfg {
                size: 12
                weight: Font.Medium
            }
            small: FontCfg {
                size: 11
            }
        }
        final property FontStyleCfg mono: FontStyleCfg {
            family: "CaskaydiaCove NF"
            large: FontCfg {
                size: 16
                vaxes: ({})
            }
            medium: FontCfg {
                size: 14
                vaxes: ({})
            }
            small: FontCfg {
                size: 12
                vaxes: ({})
            }
        }
        // Upstream sizes are static_cast<int>(px / 1.33): 48 -> 36, 32 -> 24, 24 -> 18, 20 -> 15
        final property FontStyleCfg icon: FontStyleCfg {
            family: "Material Symbols Rounded"
            final property FontCfg extraLarge: FontCfg {
                size: 36
            }
            large: FontCfg {
                size: 24
            }
            medium: FontCfg {
                size: 18
            }
            small: FontCfg {
                size: 15
            }
        }
        final property string clock: "Rubik"
        // Google Sans Flex doesn't play well with unicode symbols apparently, so use Rubik instead
        final property string workspaces: "Rubik"
    }

    component AppearanceAnimDurationsCfg: JsonObject {
        final property real scale: 1
    }

    component AppearanceAnimCfg: JsonObject {
        final property AppearanceAnimDurationsCfg durations: AppearanceAnimDurationsCfg {}
    }

    component AppearanceTransparencyCfg: JsonObject {
        final property bool enabled: false
        final property real base: 0.85
        final property real layers: 0.4
    }

    component AppearanceCfg: JsonObject {
        final property real deformScale: 1
        final property AppearanceRoundingCfg rounding: AppearanceRoundingCfg {}
        final property AppearanceSpacingCfg spacing: AppearanceSpacingCfg {}
        final property AppearancePaddingCfg padding: AppearancePaddingCfg {}
        final property AppearanceFontCfg font: AppearanceFontCfg {}
        final property AppearanceAnimCfg anim: AppearanceAnimCfg {}
        final property AppearanceTransparencyCfg transparency: AppearanceTransparencyCfg {}
    }

    component GeneralAppsCfg: JsonObject {
        final property list<string> terminal: ["foot"]
        final property list<string> audio: ["pwvucontrol"]
        final property list<string> playback: ["mpv"]
        final property list<string> explorer: ["thunar"]
    }

    component GeneralIdleCfg: JsonObject {
        final property bool lockBeforeSleep: true
        final property bool inhibitWhenAudio: true
        final property bool inhibitWhenCharging: false
        final property var timeouts: CL.list([
            {
                enabled: true,
                timeout: 180,
                idleAction: "lock",
                inhibitWhenAudio: false,
                inhibitWhenCharging: false,
                respectInhibitors: true
            },
            {
                enabled: true,
                timeout: 300,
                idleAction: "dpms off",
                returnAction: "dpms on",
                inhibitWhenAudio: false,
                inhibitWhenCharging: false,
                respectInhibitors: true
            },
            {
                enabled: true,
                timeout: 600,
                idleAction: ["suspendThenHibernate"],
                inhibitWhenAudio: false,
                inhibitWhenCharging: false,
                respectInhibitors: true
            }
        ])
        onTimeoutsChanged: CL.list(timeouts)
    }

    component GeneralBatteryCfg: JsonObject {
        final property var warnLevels: CL.list([
            {
                level: 20,
                title: "Low battery",
                message: "You might want to plug in a charger",
                icon: "battery_android_frame_2",
                critical: false
            },
            {
                level: 10,
                title: "Did you see the previous message?",
                message: "You should probably plug in a charger <b>now</b>",
                icon: "battery_android_frame_1",
                critical: false
            },
            {
                level: 5,
                title: "Critical battery level",
                message: "PLUG THE CHARGER RIGHT NOW!!",
                icon: "battery_android_alert",
                critical: true
            }
        ])
        onWarnLevelsChanged: CL.list(warnLevels)
        final property int criticalLevel: 3
    }

    component GeneralCfg: JsonObject {
        final property string logo: ""
        final property string language: ""
        final property bool showOverFullscreen: false
        final property real mediaGifSpeedAdjustment: 300
        final property GeneralAppsCfg apps: GeneralAppsCfg {}
        final property GeneralIdleCfg idle: GeneralIdleCfg {}
        final property GeneralBatteryCfg battery: GeneralBatteryCfg {}
    }

    component BackgroundDesktopClockBackgroundCfg: JsonObject {
        final property bool enabled: false
        final property real opacity: 0.7
        final property bool blur: true
    }

    component BackgroundDesktopClockShadowCfg: JsonObject {
        final property bool enabled: true
        final property real opacity: 0.7
        final property real blur: 0.4
    }

    component BackgroundDesktopClockCfg: JsonObject {
        final property bool enabled: false
        final property real scale: 1
        final property string position: "bottom-right"
        final property bool invertColors: false
        final property BackgroundDesktopClockBackgroundCfg background: BackgroundDesktopClockBackgroundCfg {}
        final property BackgroundDesktopClockShadowCfg shadow: BackgroundDesktopClockShadowCfg {}
    }

    component BackgroundVisualiserCfg: JsonObject {
        final property bool enabled: false
        final property bool autoHide: true
        final property bool blur: false
        final property real rounding: 1
        final property real spacing: 1
    }

    component BackgroundCfg: JsonObject {
        final property bool enabled: true
        final property bool wallpaperEnabled: true
        final property int wallpaperTransition: WallpaperTransition.Crossfade
        final property BackgroundDesktopClockCfg desktopClock: BackgroundDesktopClockCfg {}
        final property BackgroundVisualiserCfg visualiser: BackgroundVisualiserCfg {}
    }

    component BarScrollActionsCfg: JsonObject {
        final property bool workspaces: true
        final property bool volume: true
        final property bool brightness: true
    }

    component BarPopoutsCfg: JsonObject {
        final property bool activeWindow: true
        final property bool tray: true
        final property bool statusIcons: true
    }

    component BarWorkspacesCfg: JsonObject {
        final property int shown: 5
        final property bool activeIndicator: true
        final property bool occupiedBg: false
        final property bool showUnoccupied: true
        // Port: show the occupied workspaces, the active one and the first empty one after
        // them; false shows every desktop.
        final property bool dynamic: true
        final property bool perMonitor: true
        final property bool showUtilities: true
        final property bool showWindowsOnSpecialWorkspaces: true
        final property int maxWindowIcons: 5
        final property bool activeTrail: true
        final property int displayType: BarWorkspaceDisplay.Shapes
        final property int specialDisplayType: BarWorkspaceDisplay.Icons
        final property string label: String.fromCodePoint(0xf444) + "  "
        final property string occupiedLabel: String.fromCodePoint(0xf0baf)
        final property string activeLabel: String.fromCodePoint(0xf0baf)
        final property int capitalisation: BarWorkspaceCapitalisation.Preserve
        final property var workspaceIcons: CL.list([])
        onWorkspaceIconsChanged: CL.list(workspaceIcons)
        final property var specialWorkspaceIcons: CL.list([
            {
                name: "special",
                regex: "",
                flags: "",
                icon: "star"
            },
            {
                name: "communication",
                regex: "",
                flags: "",
                icon: "forum"
            },
            {
                name: "music",
                regex: "",
                flags: "",
                icon: "music_cast"
            },
            {
                name: "todo",
                regex: "",
                flags: "",
                icon: "checklist"
            },
            {
                name: "sysmon",
                regex: "",
                flags: "",
                icon: "monitor_heart"
            }
        ])
        onSpecialWorkspaceIconsChanged: CL.list(specialWorkspaceIcons)
        final property list<string> ignoredTags: ["hide_in_bar", "xwl_popup"]
        final property var windowIcons: CL.list([
            {
                name: "",
                regex: "steam(_app_(default|[0-9]+))?",
                flags: "",
                icon: "sports_esports"
            }
        ])
        onWindowIconsChanged: CL.list(windowIcons)
    }

    component BarActiveWindowCfg: JsonObject {
        final property bool compact: false
        final property bool inverted: false
        final property bool showOnHover: true
    }

    component BarTrayCfg: JsonObject {
        final property bool background: false
        final property bool recolour: false
        final property bool compact: false
        final property var iconSubs: CL.list([])
        onIconSubsChanged: CL.list(iconSubs)
        final property list<string> hiddenIcons: []
    }

    component BarStatusCfg: JsonObject {
        final property bool background: false
    }

    component BarClockCfg: JsonObject {
        final property bool background: false
        final property bool showDate: false
        final property bool showIcon: true
        final property bool showSeconds: false
    }

    component BarCfg: JsonObject {
        final property bool persistent: true
        final property bool showOnHover: true
        final property int dragThreshold: 20
        final property BarScrollActionsCfg scrollActions: BarScrollActionsCfg {}
        final property BarPopoutsCfg popouts: BarPopoutsCfg {}
        final property BarWorkspacesCfg workspaces: BarWorkspacesCfg {}
        final property BarActiveWindowCfg activeWindow: BarActiveWindowCfg {}
        final property BarTrayCfg tray: BarTrayCfg {}
        final property BarStatusCfg status: BarStatusCfg {}
        final property BarClockCfg clock: BarClockCfg {}
        final property var statusIcons: CL.list([
            {
                id: "lockStatus",
                enabled: true
            },
            {
                id: "audio",
                enabled: false
            },
            {
                id: "microphone",
                enabled: false
            },
            {
                id: "kbLayout",
                enabled: false
            },
            {
                id: "network",
                enabled: true
            },
            {
                id: "bluetooth",
                enabled: true
            },
            {
                id: "battery",
                enabled: true
            }
        ])
        onStatusIconsChanged: CL.list(statusIcons)
        final property var entries: CL.list([
            {
                id: "logo",
                enabled: true
            },
            {
                id: "workspaces",
                enabled: true
            },
            {
                id: "layout",
                enabled: true
            },
            {
                id: "spacer",
                enabled: true
            },
            {
                id: "activeWindow",
                enabled: true
            },
            {
                id: "spacer",
                enabled: true
            },
            {
                id: "clock",
                enabled: true
            },
            {
                id: "statusIcons",
                enabled: true
            },
            {
                id: "tray",
                enabled: true
            },
            {
                id: "power",
                enabled: true
            }
        ])
        onEntriesChanged: CL.list(entries)
        final property list<string> excludedScreens: []
    }

    component BorderCfg: JsonObject {
        final property int thickness: 10
        final property int rounding: 25
        final property int smoothing: 20
        readonly property int minThickness: 2
        readonly property int clampedThickness: Math.max(minThickness, thickness)
    }

    component DashboardPerformanceCfg: JsonObject {
        final property bool showBattery: true
        final property bool showGpu: true
        final property bool showCpu: true
        final property bool showMemory: true
        final property bool showStorage: true
        final property bool showNetwork: true
    }

    component DashboardCfg: JsonObject {
        final property bool enabled: true
        final property bool showOnHover: true
        // Port: milliseconds the pointer must rest at the top edge before the dashboard opens.
        final property int hoverDelay: 400
        final property bool showDashboard: true
        final property bool showMedia: true
        final property bool showPerformance: true
        final property bool showWeather: true
        // Port: the Utilities tab (quick actions that open Windows UI).
        final property bool showUtilities: true
        final property bool showClockSeconds: false
        final property int mediaUpdateInterval: 500
        final property int resourceUpdateInterval: 1000
        final property int dragThreshold: 50
        final property DashboardPerformanceCfg performance: DashboardPerformanceCfg {}
    }

    component LauncherUseFuzzyCfg: JsonObject {
        final property bool apps: false
        final property bool actions: false
        final property bool schemes: false
        final property bool variants: false
        final property bool wallpapers: false
    }

    component LauncherCfg: JsonObject {
        final property bool enabled: true
        final property bool showOnHover: false
        final property int maxShown: 7
        final property int maxWallpapers: 9
        final property string specialPrefix: "@"
        final property string actionPrefix: ">"
        final property bool enableDangerousActions: false
        final property int dragThreshold: 50
        final property bool vimKeybinds: false
        final property list<string> favouriteApps: []
        final property list<string> hiddenApps: []
        final property LauncherUseFuzzyCfg useFuzzy: LauncherUseFuzzyCfg {}
        final property var actions: CL.list([
            {
                enabled: true,
                name: "Calculator",
                icon: "calculate",
                description: "Do simple maths equations (powered by Qalc)",
                command: ["autocomplete", "calc"],
                dangerous: false
            },
            {
                enabled: true,
                name: "Scheme",
                icon: "palette",
                description: "Change the current colour scheme",
                command: ["autocomplete", "scheme"],
                dangerous: false
            },
            {
                enabled: true,
                name: "Wallpaper",
                icon: "image",
                description: "Change the current wallpaper",
                command: ["autocomplete", "wallpaper"],
                dangerous: false
            },
            {
                enabled: true,
                name: "Variant",
                icon: "colors",
                description: "Change the current scheme variant",
                command: ["autocomplete", "variant"],
                dangerous: false
            },
            {
                enabled: true,
                name: "Random",
                icon: "casino",
                description: "Switch to a random wallpaper",
                command: ["celeste", "wallpaper", "-r"],
                dangerous: false
            },
            {
                enabled: true,
                name: "Light",
                icon: "light_mode",
                description: "Change the scheme to light mode",
                command: ["setMode", "light"],
                dangerous: false
            },
            {
                enabled: true,
                name: "Dark",
                icon: "dark_mode",
                description: "Change the scheme to dark mode",
                command: ["setMode", "dark"],
                dangerous: false
            },
            {
                enabled: true,
                name: "Shutdown",
                icon: "power_settings_new",
                description: "Shutdown the system",
                command: ["poweroff"],
                dangerous: true
            },
            {
                enabled: true,
                name: "Reboot",
                icon: "cached",
                description: "Reboot the system",
                command: ["reboot"],
                dangerous: true
            },
            {
                enabled: true,
                name: "Logout",
                icon: "exit_to_app",
                description: "Log out of the current session",
                command: ["logout"],
                dangerous: true
            },
            {
                enabled: true,
                name: "Lock",
                icon: "lock",
                description: "Lock the current session",
                command: ["loginctl", "lock-session"],
                dangerous: false
            },
            {
                enabled: true,
                name: "Sleep",
                icon: "bedtime",
                description: "Suspend then hibernate",
                command: ["suspendThenHibernate"],
                dangerous: false
            },
            {
                enabled: true,
                name: "Settings",
                icon: "settings",
                description: "Configure the shell",
                command: ["celeste", "shell", "nexus", "open"],
                dangerous: false
            }
        ])
        onActionsChanged: CL.list(actions)
    }

    component LockCfg: JsonObject {
        final property bool enabled: true
        final property bool useWallpaper: false
        final property bool recolourLogo: true
        final property bool enableFprint: true
        final property int maxFprintTries: 3
        final property bool enableHowdy: true
        final property int maxHowdyTries: 3
        final property bool triggerHowdyOnWake: true
        final property bool hideNotifs: false
        final property bool enableSessionControls: false
    }

    component NexusCfg: JsonObject {
        final property int wallpapersPerRow: 4
        final property int maxNetworksShown: 5
        final property int networkRescanInterval: 15000
    }

    component NotifsCfg: JsonObject {
        final property bool expire: true
        final property int fullscreen: NotifsFullscreen.On
        final property int defaultExpireTimeout: 5000
        final property int fullscreenExpireTimeout: 2000
        final property real clearThreshold: 0.3
        final property int expandThreshold: 20
        final property bool actionOnClick: false
        final property int groupPreviewNum: 3
        final property bool openExpanded: false
    }

    component OsdCfg: JsonObject {
        final property bool enabled: true
        final property int hideDelay: 2000
        final property bool enableBrightness: true
        final property bool enableMicrophone: false
    }

    component ServicesCfg: JsonObject {
        final property string weatherLocation: ""
        final property int weatherUnits: TemperatureUnit.Auto // Auto guesses based on locale
        final property int sensorUnits: TemperatureUnit.Celsius
        final property int dataUnits: DataUnit.Binary // Binary (KiB/MiB/GiB) or decimal (KB/MB/GB)
        final property int clockFormat: ClockFormat.Auto
        final property int gpuType: GpuType.Auto
        final property int visualiserBars: 60
        final property real audioIncrement: 0.1
        final property real brightnessIncrement: 0.1
        final property real maxVolume: 1.0
        final property bool smartScheme: true
        // Port: false blocks every session action (lock, sleep, shutdown, ...) in the launcher and the session menu.
        final property bool allowSystemActions: true
        // Port: a wallpaper change also sets the Windows lock screen (and sign-in screen) picture.
        final property bool wallpaperLockScreen: true
        final property string defaultPlayer: "Spotify"
        final property var playerAliases: CL.list([
            {
                from: "com.github.th_ch.youtube_music",
                to: "YT Music"
            }
        ])
        onPlayerAliasesChanged: CL.list(playerAliases)
        final property int lyricsBackend: LyricsBackend.Auto
    }

    component SessionIconsCfg: JsonObject {
        final property string logout: "logout"
        final property string shutdown: "power_settings_new"
        final property string hibernate: "downloading"
        final property string reboot: "cached"
    }

    component SessionCommandsCfg: JsonObject {
        final property list<string> logout: ["logout"]
        final property list<string> shutdown: ["poweroff"]
        final property list<string> hibernate: ["hibernate"]
        final property list<string> reboot: ["reboot"]
    }

    component SessionCfg: JsonObject {
        final property bool enabled: true
        final property int dragThreshold: 30
        final property bool vimKeybinds: false
        final property SessionIconsCfg icons: SessionIconsCfg {}
        final property SessionCommandsCfg commands: SessionCommandsCfg {}
    }

    component SidebarCfg: JsonObject {
        final property bool enabled: true
        final property bool showOnHover: false
        final property int minHoverThreshold: 200
        final property int dragThreshold: 80
    }

    component UtilitiesCardsCfg: JsonObject {
        final property bool keepAwake: true
        final property bool quickToggles: true
    }

    component UtilitiesToastsCfg: JsonObject {
        final property string fullscreen: "off"
        final property bool configLoaded: true
        final property bool chargingChanged: true
        final property bool gameModeChanged: true
        final property bool dndChanged: true
        final property bool audioOutputChanged: true
        final property bool audioInputChanged: true
        final property bool capsLockChanged: true
        final property bool numLockChanged: true
        final property bool kbLayoutChanged: true
        final property bool kbLimit: true
        final property bool vpnChanged: true
        final property bool nowPlaying: false
    }

    component UtilitiesVpnCfg: JsonObject {
        final property bool enabled: false
        final property var provider: CL.list([])
        onProviderChanged: CL.list(provider)
        final property string selectedProvider: ""
    }

    component UtilitiesCfg: JsonObject {
        final property bool enabled: true
        final property int maxToasts: 4
        final property UtilitiesCardsCfg cards: UtilitiesCardsCfg {}
        final property UtilitiesToastsCfg toasts: UtilitiesToastsCfg {}
        final property UtilitiesVpnCfg vpn: UtilitiesVpnCfg {}
        final property var quickToggles: CL.list([
            {
                id: "wifi",
                enabled: true
            },
            {
                id: "bluetooth",
                enabled: true
            },
            {
                id: "mic",
                enabled: true
            },
            {
                id: "settings",
                enabled: true
            },
            {
                id: "gameMode",
                enabled: true
            },
            {
                id: "wallpaperPlaying",
                enabled: true
            },
            {
                id: "dnd",
                enabled: true
            },
            {
                id: "vpn",
                enabled: false
            }
        ])
        onQuickTogglesChanged: CL.list(quickToggles)
    }

    component PathsCfg: JsonObject {
        final property string wallpaperDir: root._home + "/Pictures/Wallpapers"
        final property string lyricsDir: root._home + "/Music/Lyrics/"
        final property string mediaGif: "root:/assets/bongocat.gif"
        final property string noNotifsPic: "root:/assets/dino.png"
        final property string lockNoNotifsPic: "root:/assets/dino.png"
    }

    property FileView file: FileView {
        id: fileView

        path: Quickshell.shellPath("config/shell.json")
        watchChanges: true
        printErrors: false
        onFileChanged: reload()

        adapter: JsonAdapter {
            id: adapter

            final property AppearanceCfg appearance: AppearanceCfg {}

            final property GeneralCfg general: GeneralCfg {}

            final property BackgroundCfg background: BackgroundCfg {}

            final property BarCfg bar: BarCfg {}

            final property BorderCfg border: BorderCfg {}

            final property DashboardCfg dashboard: DashboardCfg {}

            final property LauncherCfg launcher: LauncherCfg {}

            final property LockCfg lock: LockCfg {}

            final property NexusCfg nexus: NexusCfg {}

            final property NotifsCfg notifs: NotifsCfg {}

            final property OsdCfg osd: OsdCfg {}

            final property ServicesCfg services: ServicesCfg {}

            final property SessionCfg session: SessionCfg {}

            final property SidebarCfg sidebar: SidebarCfg {}

            final property UtilitiesCfg utilities: UtilitiesCfg {}

            final property PathsCfg paths: PathsCfg {}
        }
    }
}
