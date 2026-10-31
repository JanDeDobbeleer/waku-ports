pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "ConfigList.js" as CL

// Port of upstream's GlobalConfig (the shell.json settings tree). Defaults are the C++ defaults
// of plugin/src/Caelestia/Config/*config.hpp. The file is config/shell.json in the config home.
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
        file.writeAdapter();
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
        property string family: "" // Empty inherits the style family
        property int size: 14
        property int weight: Font.Normal
        property bool italic: false
        property var vaxes: ({
                ROND: 25
            })
    }

    component FontStyleCfg: JsonObject {
        property string family: "Google Sans Flex"
        property FontCfg large: FontCfg {}
        property FontCfg medium: FontCfg {}
        property FontCfg small: FontCfg {}
    }

    property FileView file: FileView {
        id: file

        path: Quickshell.shellPath("config/shell.json")
        watchChanges: true
        printErrors: false
        onFileChanged: reload()

        adapter: JsonAdapter {
            id: adapter

            property JsonObject appearance: JsonObject {
                property real deformScale: 1
                property JsonObject rounding: JsonObject {
                    property real scale: 1
                }
                property JsonObject spacing: JsonObject {
                    property real scale: 1
                }
                property JsonObject padding: JsonObject {
                    property real scale: 1
                }
                property JsonObject font: JsonObject {
                    property real scale: 1
                    property FontStyleCfg headline: FontStyleCfg {
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
                    property FontStyleCfg title: FontStyleCfg {
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
                    property FontStyleCfg body: FontStyleCfg {
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
                    property FontStyleCfg label: FontStyleCfg {
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
                    property FontStyleCfg mono: FontStyleCfg {
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
                    property FontStyleCfg icon: FontStyleCfg {
                        family: "Material Symbols Rounded"
                        property FontCfg extraLarge: FontCfg {
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
                    property string clock: "Rubik"
                    // Google Sans Flex doesn't play well with unicode symbols apparently, so use Rubik instead
                    property string workspaces: "Rubik"
                }
                property JsonObject anim: JsonObject {
                    property JsonObject durations: JsonObject {
                        property real scale: 1
                    }
                }
                property JsonObject transparency: JsonObject {
                    property bool enabled: false
                    property real base: 0.85
                    property real layers: 0.4
                }
            }

            property JsonObject general: JsonObject {
                property string logo: ""
                property string language: ""
                property bool showOverFullscreen: false
                property real mediaGifSpeedAdjustment: 300
                property real sessionGifSpeed: 0.7
                property JsonObject apps: JsonObject {
                    property list<string> terminal: ["foot"]
                    property list<string> audio: ["pwvucontrol"]
                    property list<string> playback: ["mpv"]
                    property list<string> explorer: ["thunar"]
                }
                property JsonObject idle: JsonObject {
                    property bool lockBeforeSleep: true
                    property bool inhibitWhenAudio: true
                    property bool inhibitWhenCharging: false
                    property var timeouts: CL.list([
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
                property JsonObject battery: JsonObject {
                    property var warnLevels: CL.list([
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
                    property int criticalLevel: 3
                }
            }

            property JsonObject background: JsonObject {
                property bool enabled: true
                property bool wallpaperEnabled: true
                property int wallpaperTransition: WallpaperTransition.Crossfade
                property JsonObject desktopClock: JsonObject {
                    property bool enabled: false
                    property real scale: 1
                    property string position: "bottom-right"
                    property bool invertColors: false
                    property JsonObject background: JsonObject {
                        property bool enabled: false
                        property real opacity: 0.7
                        property bool blur: true
                    }
                    property JsonObject shadow: JsonObject {
                        property bool enabled: true
                        property real opacity: 0.7
                        property real blur: 0.4
                    }
                }
                property JsonObject visualiser: JsonObject {
                    property bool enabled: false
                    property bool autoHide: true
                    property bool blur: false
                    property real rounding: 1
                    property real spacing: 1
                }
            }

            property JsonObject bar: JsonObject {
                property bool persistent: true
                property bool showOnHover: true
                property int dragThreshold: 20
                property JsonObject scrollActions: JsonObject {
                    property bool workspaces: true
                    property bool volume: true
                    property bool brightness: true
                }
                property JsonObject popouts: JsonObject {
                    property bool activeWindow: true
                    property bool tray: true
                    property bool statusIcons: true
                }
                property JsonObject workspaces: JsonObject {
                    property int shown: 5
                    property bool activeIndicator: true
                    property bool occupiedBg: false
                    property bool showUnoccupied: true
                    // Port: show the occupied workspaces, the active one and the first empty one after
                    // them; false shows every komorebi workspace of the monitor.
                    property bool dynamic: true
                    property bool perMonitor: true
                    property bool showUtilities: true
                    property bool showWindowsOnSpecialWorkspaces: true
                    property int maxWindowIcons: 5
                    property bool activeTrail: true
                    property int displayType: BarWorkspaceDisplay.Shapes
                    property int specialDisplayType: BarWorkspaceDisplay.Icons
                    property string label: String.fromCodePoint(0xf444) + "  "
                    property string occupiedLabel: String.fromCodePoint(0xf0baf)
                    property string activeLabel: String.fromCodePoint(0xf0baf)
                    property int capitalisation: BarWorkspaceCapitalisation.Preserve
                    property var workspaceIcons: CL.list([])
                    onWorkspaceIconsChanged: CL.list(workspaceIcons)
                    property var specialWorkspaceIcons: CL.list([
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
                    property list<string> ignoredTags: ["hide_in_bar", "xwl_popup"]
                    property var windowIcons: CL.list([
                        {
                            name: "",
                            regex: "steam(_app_(default|[0-9]+))?",
                            flags: "",
                            icon: "sports_esports"
                        }
                    ])
                    onWindowIconsChanged: CL.list(windowIcons)
                }
                property JsonObject activeWindow: JsonObject {
                    property bool compact: false
                    property bool inverted: false
                    property bool showOnHover: true
                }
                property JsonObject tray: JsonObject {
                    property bool background: false
                    property bool recolour: false
                    property bool compact: false
                    property var iconSubs: CL.list([])
                    onIconSubsChanged: CL.list(iconSubs)
                    property list<string> hiddenIcons: []
                }
                property JsonObject status: JsonObject {
                    property bool background: false
                }
                property JsonObject clock: JsonObject {
                    property bool background: false
                    property bool showDate: false
                    property bool showIcon: true
                    property bool showSeconds: false
                }
                property var statusIcons: CL.list([
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
                property var entries: CL.list([
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
                property list<string> excludedScreens: []
            }

            property JsonObject border: JsonObject {
                property int thickness: 10
                property int rounding: 25
                property int smoothing: 20
                readonly property int minThickness: 2
                readonly property int clampedThickness: Math.max(minThickness, thickness)
            }

            property JsonObject dashboard: JsonObject {
                property bool enabled: true
                property bool showOnHover: true
                // Port: milliseconds the pointer must rest at the top edge before the dashboard opens.
                property int hoverDelay: 400
                property bool showDashboard: true
                property bool showMedia: true
                property bool showPerformance: true
                property bool showWeather: true
                // Port: the Utilities tab (quick actions that open Windows UI).
                property bool showUtilities: true
                property bool showClockSeconds: false
                property int mediaUpdateInterval: 500
                property int resourceUpdateInterval: 1000
                property int dragThreshold: 50
                property JsonObject performance: JsonObject {
                    property bool showBattery: true
                    property bool showGpu: true
                    property bool showCpu: true
                    property bool showMemory: true
                    property bool showStorage: true
                    property bool showNetwork: true
                }
            }

            property JsonObject launcher: JsonObject {
                property bool enabled: true
                property bool showOnHover: false
                property int maxShown: 7
                property int maxWallpapers: 9
                property string specialPrefix: "@"
                property string actionPrefix: ">"
                property bool enableDangerousActions: false
                property int dragThreshold: 50
                property bool vimKeybinds: false
                property list<string> favouriteApps: []
                property list<string> hiddenApps: []
                property JsonObject useFuzzy: JsonObject {
                    property bool apps: false
                    property bool actions: false
                    property bool schemes: false
                    property bool variants: false
                    property bool wallpapers: false
                }
                property var actions: CL.list([
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
                        command: ["caelestia", "wallpaper", "-r"],
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
                        command: ["caelestia", "shell", "nexus", "open"],
                        dangerous: false
                    }
                ])
                onActionsChanged: CL.list(actions)
            }

            property JsonObject lock: JsonObject {
                property bool enabled: true
                property bool useWallpaper: false
                property bool recolourLogo: true
                property bool enableFprint: true
                property int maxFprintTries: 3
                property bool enableHowdy: true
                property int maxHowdyTries: 3
                property bool triggerHowdyOnWake: true
                property bool hideNotifs: false
                property bool enableSessionControls: false
            }

            property JsonObject nexus: JsonObject {
                property int wallpapersPerRow: 4
                property int maxNetworksShown: 5
                property int networkRescanInterval: 15000
            }

            property JsonObject notifs: JsonObject {
                property bool expire: true
                property int fullscreen: NotifsFullscreen.On
                property int defaultExpireTimeout: 5000
                property int fullscreenExpireTimeout: 2000
                property real clearThreshold: 0.3
                property int expandThreshold: 20
                property bool actionOnClick: false
                property int groupPreviewNum: 3
                property bool openExpanded: false
            }

            property JsonObject osd: JsonObject {
                property bool enabled: true
                property int hideDelay: 2000
                property bool enableBrightness: true
                property bool enableMicrophone: false
            }

            property JsonObject services: JsonObject {
                property string weatherLocation: ""
                property int weatherUnits: TemperatureUnit.Auto // Auto guesses based on locale
                property int sensorUnits: TemperatureUnit.Celsius
                property int dataUnits: DataUnit.Binary // Binary (KiB/MiB/GiB) or decimal (KB/MB/GB)
                property int clockFormat: ClockFormat.Auto
                property int gpuType: GpuType.Auto
                property int visualiserBars: 60
                property real audioIncrement: 0.1
                property real brightnessIncrement: 0.1
                property real maxVolume: 1.0
                property bool smartScheme: true
                // Port: false blocks every session action (lock, sleep, shutdown, ...) in the launcher and the session menu.
                property bool allowSystemActions: true
                // Port: the animation wabar plays when the wallpaper changes: circle, slide_top, diamond, split, fade or none. Empty is wabar's default.
                property string wallpaperAnimation: ""
                // Port: a wallpaper change also sets the Windows lock screen (and sign-in screen) picture.
                property bool wallpaperLockScreen: true
                property string defaultPlayer: "Spotify"
                property var playerAliases: CL.list([
                    {
                        from: "com.github.th_ch.youtube_music",
                        to: "YT Music"
                    }
                ])
                onPlayerAliasesChanged: CL.list(playerAliases)
                property int lyricsBackend: LyricsBackend.Auto
            }

            property JsonObject session: JsonObject {
                property bool enabled: true
                property int dragThreshold: 30
                property bool vimKeybinds: false
                property JsonObject icons: JsonObject {
                    property string logout: "logout"
                    property string shutdown: "power_settings_new"
                    property string hibernate: "downloading"
                    property string reboot: "cached"
                }
                property JsonObject commands: JsonObject {
                    property list<string> logout: ["logout"]
                    property list<string> shutdown: ["poweroff"]
                    property list<string> hibernate: ["hibernate"]
                    property list<string> reboot: ["reboot"]
                }
            }

            property JsonObject sidebar: JsonObject {
                property bool enabled: true
                property bool showOnHover: false
                property int minHoverThreshold: 200
                property int dragThreshold: 80
            }

            property JsonObject utilities: JsonObject {
                property bool enabled: true
                property int maxToasts: 4
                property JsonObject cards: JsonObject {
                    property bool keepAwake: true
                    property bool recorder: true
                    property bool quickToggles: true
                }
                property JsonObject toasts: JsonObject {
                    property string fullscreen: "off"
                    property bool configLoaded: true
                    property bool chargingChanged: true
                    property bool gameModeChanged: true
                    property bool dndChanged: true
                    property bool audioOutputChanged: true
                    property bool audioInputChanged: true
                    property bool capsLockChanged: true
                    property bool numLockChanged: true
                    property bool kbLayoutChanged: true
                    property bool kbLimit: true
                    property bool vpnChanged: true
                    property bool nowPlaying: false
                }
                property JsonObject vpn: JsonObject {
                    property bool enabled: false
                    property var provider: CL.list([])
                    onProviderChanged: CL.list(provider)
                    property string selectedProvider: ""
                }
                property var quickToggles: CL.list([
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

            property JsonObject paths: JsonObject {
                property string wallpaperDir: root._home + "/Pictures/Wallpapers"
                property string lyricsDir: root._home + "/Music/Lyrics/"
                property string sessionGif: "root:/assets/kurukuru.gif"
                property string mediaGif: "root:/assets/bongocat.gif"
                property string noNotifsPic: "root:/assets/dino.png"
                property string lockNoNotifsPic: "root:/assets/dino.png"
            }
        }
    }
}
