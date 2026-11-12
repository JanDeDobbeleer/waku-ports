pragma Singleton

import QtQuick 6.10
import Quickshell
import Quickshell.Io
import "../Helpers/QtObj2JS.js" as QtObj2JS
import qs.Commons
import qs.Commons.Migrations
import qs.Modules.OSD
import qs.Services.UI
import qs.compat

Singleton {
  id: root

  property bool isLoaded: false
  property bool reloadSettings: false
  property bool directoriesCreated: false
  property bool shouldOpenSetupWizard: false
  property bool isFreshInstall: false

  /*
  Shell directories.
  - Default config directory: ~/.config/octalia
  - Default cache directory: ~/.cache/octalia
  */
  readonly property alias data: adapter  // Used to access via Settings.data.xxx.yyy
  readonly property int settingsVersion: 59
  property bool isDebug: Quickshell.env("OCTALIA_DEBUG") === "1"
  readonly property string shellName: "octalia"
  readonly property string configDir: ensureTrailingSlash(Quickshell.env("OCTALIA_CONFIG_DIR") || (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/" + shellName + "/")
  readonly property string cacheDir: ensureTrailingSlash(Quickshell.env("OCTALIA_CACHE_DIR") || (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/" + shellName + "/")

  readonly property string settingsFile: Quickshell.env("OCTALIA_SETTINGS_FILE") || (configDir + "settings.json")
  // ~/.face is a Linux convention; on Windows there is no default avatar, so the profile icon shows.
  readonly property string defaultAvatar: ""
  readonly property string defaultVideosDirectory: Quickshell.env("HOME") + "/Videos"
  readonly property string defaultWallpapersDirectory: Quickshell.env("HOME") + "/.config/wallpapers"

  signal settingsLoaded
  signal settingsSaved
  signal settingsReloaded

  // Debounce external reload requests (file watcher + directory watcher)
  // so atomic replacements only trigger one reload.
  Timer {
    id: externalReloadTimer
    running: false
    interval: 200
    onTriggered: {
      if (settingsFileView.path !== undefined) {
        Logger.d("Settings", "Reloading settings after external change detection");
        root.reloadSettings = true;
        settingsFileView.reload();
      }
    }
  }

  function scheduleExternalReload() {
    if (!directoriesCreated || settingsFileView.path === undefined) {
      return;
    }
    externalReloadTimer.restart();
  }

  // -----------------------------------------------------
  // -----------------------------------------------------
  // Ensure directories exist before FileView tries to read files
  Component.onCompleted: {
    // ensure settings dir exists
    Os.mkdirp(configDir);
    Os.mkdirp(cacheDir);

    // Mark directories as created and trigger file loading
    directoriesCreated = true;

    // This should only be activated once when the settings structure has changed
    // Then it should be commented out again, regular users don't need to generate
    // default settings on every start
    if (isDebug) {
      generateDefaultSettings();
      generateWidgetDefaultSettings();
    }

    // Patch-in the local default, resolved to user's home
    adapter.general.avatarImage = defaultAvatar;
    adapter.wallpaper.directory = defaultWallpapersDirectory;
    adapter.ui.fontDefault = Qt.application.font.family;
    adapter.ui.fontFixed = "monospace";

    // Set the adapter to the settingsFileView to trigger the real settings load
    settingsFileView.adapter = adapter;
  }

  // Don't write settings to disk immediately
  // This avoid excessive IO when a variable changes rapidly (ex: sliders)
  Timer {
    id: saveTimer
    running: false
    interval: 500
    onTriggered: {
      root.saveImmediate();
    }
  }

  FileView {
    id: settingsFileView
    path: root.directoriesCreated ? root.settingsFile : undefined
    printErrors: false
    watchChanges: true
    onAdapterUpdated: saveTimer.start()

    onFileChanged: scheduleExternalReload()

    // Trigger initial load when path changes from empty to actual path
    onPathChanged: {
      if (path !== undefined) {
        reload();
      }
    }
    onLoaded: function () {
      var rawJson;
      if (!root.isLoaded) {
        Logger.i("Settings", "Settings loaded");

        // Load raw JSON for migrations (adapter doesn't expose removed properties)
        rawJson = null;
        try {
          rawJson = JSON.parse(settingsFileView.text());
        } catch (e) {
          Logger.w("Settings", "Could not parse raw JSON for migrations");
        }

        // Run versioned migrations immediately, don't move it in upgradeSettings
        runVersionedMigrations(rawJson);

        // Finally, update our local settings version
        adapter.settingsVersion = root.settingsVersion;

        // Emit the signal
        root.isLoaded = true;
        root.settingsLoaded();

        upgradeSettings();
      } else {
        Logger.d("Settings", "Settings reloaded from external file change");
        root.settingsReloaded();
      }
    }
    onLoadFailed: function (error) {
      if (root.reloadSettings) {
        root.reloadSettings = false;
        return;
      }
      if (error.toString().includes("No such file") || error === 2) {
        // File doesn't exist, create it with default values
        root.isFreshInstall = true;
        writeAdapter();

        // We started without settings, we should open the setupWizard
        root.shouldOpenSetupWizard = true;
      }
    }
  }

  // Watch parent config directory as a fallback for declarative setups where
  // settings.json may be replaced atomically (e.g., symlink/store-path swap).
  FileView {
    id: settingsDirWatcher
    path: root.directoriesCreated ? root.configDir : undefined
    printErrors: false
    watchChanges: true
    onFileChanged: scheduleExternalReload()
  }

  // FileView to load default settings for comparison
  FileView {
    id: defaultSettingsFileView
    path: Quickshell.shellDir + "/Assets/settings-default.json"
    printErrors: false
    watchChanges: false
  }

  // Cached default settings object
  property var _defaultSettings: null

  // Load default settings when file is loaded
  Connections {
    target: defaultSettingsFileView
    function onLoaded() {
      try {
        root._defaultSettings = JSON.parse(defaultSettingsFileView.text());
      } catch (e) {
        Logger.w("Settings", "Failed to parse default settings file: " + e);
        root._defaultSettings = null;
      }
    }
  }

  JsonAdapter {
    id: adapter

    property int settingsVersion: 0

    // bar
    component BarWidgetsSettings: JsonObject {
      final property list<var> left: [
        {
          "id": "Launcher"
        },
        {
          "id": "Clock"
        },
        {
          "id": "SystemMonitor"
        },
        {
          "id": "ActiveWindow"
        },
        {
          "id": "MediaMini"
        }
      ]
      final property list<var> center: [
        {
          "id": "Workspace"
        },
        {
          "id": "LayoutSwitcher"
        }
      ]
      final property list<var> right: [
        {
          "id": "Tray"
        },
        {
          "id": "NotificationHistory"
        },
        {
          "id": "Battery"
        },
        {
          "id": "Volume"
        },
        {
          "id": "Brightness"
        },
        {
          "id": "ControlCenter"
        }
      ]
    }

    component BarSettings: JsonObject {
      final property string barType: "simple" // "simple", "floating", "framed"
      final property string position: "top" // "top", "bottom", "left", or "right"
      final property list<string> monitors: [] // holds bar visibility per monitor
      final property string density: "default" // "compact", "default", "comfortable"
      final property bool showOutline: false
      final property bool showCapsule: true
      final property real capsuleOpacity: 1.0
      final property string capsuleColorKey: "none"
      final property int widgetSpacing: 6
      final property int contentPadding: 2
      final property real fontScale: 1.0
      final property bool enableExclusionZoneInset: true

      // Bar background opacity settings
      final property real backgroundOpacity: 0.93
      final property bool useSeparateOpacity: false

      // Floating bar settings
      final property int marginVertical: 4
      final property int marginHorizontal: 4

      // Framed bar settings
      final property int frameThickness: 8
      final property int frameRadius: 12

      // Bar outer corners (inverted/concave corners at bar edges when not floating)
      final property bool outerCorners: true

      // Hide bar/panels when compositor overview is active
      final property bool hideOnOverview: false

      // Auto-hide settings
      final property string displayMode: "always_visible"
      final property int autoHideDelay: 500 // ms before hiding after mouse leaves
      final property int autoShowDelay: 150 // ms before showing when mouse enters
      final property bool showOnWorkspaceSwitch: true // show bar briefly on workspace switch

      // Widget configuration for modular bar system
      final property BarWidgetsSettings widgets: BarWidgetsSettings {}

      final property string mouseWheelAction: "none"
      final property bool reverseScroll: false
      final property bool mouseWheelWrap: true
      final property string middleClickAction: "none"
      final property bool middleClickFollowMouse: false
      final property string middleClickCommand: ""
      final property string rightClickAction: "controlCenter"
      final property bool rightClickFollowMouse: true
      final property string rightClickCommand: ""
      // Per-screen overrides for position and widgets
      // Format: [{ "name": "HDMI-1", "position": "left" }, { "name": "DP-1", "position": "bottom", "widgets": {...} }]
      final property list<var> screenOverrides: []
    }
    final property BarSettings bar: BarSettings {}

    // general
    component GeneralKeybindsSettings: JsonObject {
      final property list<string> keyUp: ["Up"]
      final property list<string> keyDown: ["Down"]
      final property list<string> keyLeft: ["Left"]
      final property list<string> keyRight: ["Right"]
      final property list<string> keyEnter: ["Return", "Enter"]
      final property list<string> keyEnterNew: ["Shift+Return"]
      final property list<string> keyEnterAdmin: ["Ctrl+Shift+Return"]
      final property list<string> keyEscape: ["Esc"]
      final property list<string> keyRemove: ["Del"]
    }

    component GeneralSettings: JsonObject {
      final property string avatarImage: ""
      final property real dimmerOpacity: 0.2
      final property bool showScreenCorners: false
      final property bool forceBlackScreenCorners: false
      final property real scaleRatio: 1.0
      final property real radiusRatio: 1.0
      final property real iRadiusRatio: 1.0
      final property real boxRadiusRatio: 1.0
      final property real screenRadiusRatio: 0.4 // Port: screenRadius 8, the Windows 11 window radius
      final property real animationSpeed: 1.0
      final property bool animationDisabled: false
      final property bool compactLockScreen: false
      final property bool lockScreenAnimations: false
      final property bool lockOnSuspend: true
      final property bool showSessionButtonsOnLockScreen: true
      final property bool showHibernateOnLockScreen: false
      final property bool enableLockScreenMediaControls: false
      final property bool enableShadows: true
      final property bool enableBlurBehind: true
      final property string shadowDirection: "bottom_right"
      final property int shadowOffsetX: 2
      final property int shadowOffsetY: 3
      final property string language: ""
      final property bool allowPanelsOnScreenWithoutBar: true
      final property bool showChangelogOnStartup: true
      final property bool telemetryEnabled: false
      final property bool enableLockScreenCountdown: true
      final property int lockScreenCountdownDuration: 10000
      final property bool autoStartAuth: false
      final property bool allowPasswordWithFprintd: false
      final property string clockStyle: "custom"
      final property string clockFormat: "hh\\nmm"
      final property bool passwordChars: false
      final property list<string> lockScreenMonitors: [] // holds lock screen visibility per monitor
      final property real lockScreenBlur: 0.0
      final property real lockScreenTint: 0.0
      final property GeneralKeybindsSettings keybinds: GeneralKeybindsSettings {}
      final property bool reverseScroll: false
      final property bool smoothScrollEnabled: true
    }
    final property GeneralSettings general: GeneralSettings {}

    // ui
    component UiSettings: JsonObject {
      final property string fontDefault: ""
      final property string fontFixed: ""
      final property real fontDefaultScale: 1.0
      final property real fontFixedScale: 1.0
      final property bool scrollbarAlwaysVisible: true
      final property bool boxBorderEnabled: false
      final property real panelBackgroundOpacity: 0.93
      final property bool translucentWidgets: false
      final property bool panelsAttachedToBar: true
      final property string settingsPanelMode: "attached" // "centered", "attached", "window"
      final property bool settingsPanelSideBarCardStyle: false
    }
    final property UiSettings ui: UiSettings {}

    // location
    component LocationSettings: JsonObject {
      final property string name: ""
      final property bool weatherEnabled: true
      final property bool weatherShowEffects: true
      final property bool weatherTaliaMascotAlways: false
      final property bool useFahrenheit: false
      final property bool use12hourFormat: false
      final property bool showWeekNumberInCalendar: false
      final property bool showCalendarEvents: true
      final property bool showCalendarWeather: true
      final property bool analogClockInCalendar: false
      final property int firstDayOfWeek: -1 // -1 = auto (use locale), 0 = Sunday, 1 = Monday, 6 = Saturday
      final property bool hideWeatherTimezone: false
      final property bool hideWeatherCityName: false
      final property bool autoLocate: false
    }
    final property LocationSettings location: LocationSettings {}

    // calendar
    component CalendarSettings: JsonObject {
      final property list<var> cards: [
        {
          "id": "calendar-header-card",
          "enabled": true
        },
        {
          "id": "calendar-month-card",
          "enabled": true
        },
        {
          "id": "weather-card",
          "enabled": true
        }
      ]
    }
    final property CalendarSettings calendar: CalendarSettings {}

    // wallpaper
    component WallpaperSettings: JsonObject {
      final property bool enabled: true
      final property bool overviewEnabled: false
      final property string directory: ""
      final property list<var> monitorDirectories: []
      final property bool enableMultiMonitorDirectories: false
      final property bool showHiddenFiles: false
      final property string viewMode: "single" // "single" | "recursive" | "browse"
      final property bool setWallpaperOnAllMonitors: true
      final property bool linkLightAndDarkWallpapers: true
      final property string fillMode: "crop"
      final property color fillColor: "#000000"
      final property bool useSolidColor: false
      final property color solidColor: "#1a1a2e"
      final property bool automationEnabled: false
      final property string wallpaperChangeMode: "random" // "random" or "alphabetical"
      final property int randomIntervalSec: 300 // 5 min
      final property int transitionDuration: 1500 // 1500 ms
      final property list<string> transitionType: ["fade", "disc", "stripes", "wipe", "pixelate", "honeycomb"]
      final property bool skipStartupTransition: false
      final property real transitionEdgeSmoothness: 0.05
      final property string panelPosition: "follow_bar"
      final property bool hideWallpaperFilenames: false
      final property bool useOriginalImages: false
      final property real overviewBlur: 0.4
      final property real overviewTint: 0.6
      // Wallhaven settings
      final property bool useWallhaven: false
      final property string wallhavenQuery: ""
      final property string wallhavenSorting: "relevance"
      final property string wallhavenOrder: "desc"
      final property string wallhavenCategories: "111" // general,anime,people
      final property string wallhavenPurity: "100" // sfw only
      final property string wallhavenRatios: ""
      final property string wallhavenApiKey: ""
      final property string wallhavenResolutionMode: "atleast" // "atleast" or "exact"
      final property string wallhavenResolutionWidth: ""

      final property string wallhavenResolutionHeight: ""
      final property string sortOrder: "name" // "name", "name_desc", "date", "date_desc", "random"
      final property list<var> favorites: []
      // Format: [{ "path": "...", "appearance": "light"|"dark", "colorScheme": "...", "darkMode": bool, "useWallpaperColors": bool, "generationMethod": "...", "paletteColors": [...] }]
      // Legacy entries omit "appearance" and use darkMode to infer light vs dark slot.
    }
    final property WallpaperSettings wallpaper: WallpaperSettings {}

    // applauncher
    component AppLauncherSettings: JsonObject {
      final property bool enableClipboardHistory: false
      final property bool autoPasteClipboard: false
      final property bool enableClipPreview: true
      final property bool clipboardWrapText: true
      final property bool enableClipboardSmartIcons: true
      final property bool enableClipboardChips: true
      final property string clipboardWatchTextCommand: "wl-paste --type text --watch cliphist store"
      final property string clipboardWatchImageCommand: "wl-paste --type image --watch cliphist store"
      final property string position: "center"  // Position: center, top_left, top_right, bottom_left, bottom_right, bottom_center, top_center
      final property list<string> pinnedApps: []
      final property bool sortByMostUsed: true
      final property string terminalCommand: "wt.exe"
      final property bool customLaunchPrefixEnabled: false
      final property string customLaunchPrefix: ""
      // View mode: "list" or "grid"
      final property string viewMode: "list"
      final property bool showCategories: true
      // Icon mode: "tabler" or "native"
      final property string iconMode: "tabler"
      final property bool showIconBackground: false
      final property bool enableSettingsSearch: true
      final property bool enableWindowsSearch: true
      final property bool enableSessionSearch: true
      final property bool ignoreMouseInput: false
      final property string screenshotAnnotationTool: ""
      final property bool overviewLayer: false
      final property string density: "default" // "compact", "default", "comfortable"
    }
    final property AppLauncherSettings appLauncher: AppLauncherSettings {}

    // control center
    component ControlCenterShortcutsSettings: JsonObject {
      final property list<var> left: [
        {
          "id": "Network"
        },
        {
          "id": "Bluetooth"
        },
        {
          "id": "WallpaperSelector"
        },
        {
          "id": "OctaliaPerformance"
        }
      ]
      final property list<var> right: [
        {
          "id": "Notifications"
        },
        {
          "id": "PowerProfile"
        },
        {
          "id": "KeepAwake"
        }
      ]
    }

    component ControlCenterSettings: JsonObject {
      // Position: close_to_bar_button, center, top_left, top_right, bottom_left, bottom_right, bottom_center, top_center
      final property string position: "close_to_bar_button"
      final property string diskPath: "/"
      final property ControlCenterShortcutsSettings shortcuts: ControlCenterShortcutsSettings {}

      final property list<var> cards: [
        {
          "id": "profile-card",
          "enabled": true
        },
        {
          "id": "shortcuts-card",
          "enabled": true
        },
        {
          "id": "audio-card",
          "enabled": true
        },
        {
          "id": "brightness-card",
          "enabled": false
        },
        {
          "id": "weather-card",
          "enabled": true
        },
        {
          "id": "media-sysmon-card",
          "enabled": true
        }
      ]
    }
    final property ControlCenterSettings controlCenter: ControlCenterSettings {}

    // system monitor
    component SystemMonitorSettings: JsonObject {
      final property int cpuWarningThreshold: 80
      final property int cpuCriticalThreshold: 90
      final property int tempWarningThreshold: 80
      final property int tempCriticalThreshold: 90
      final property int gpuWarningThreshold: 80
      final property int gpuCriticalThreshold: 90
      final property int memWarningThreshold: 80
      final property int memCriticalThreshold: 90
      final property int swapWarningThreshold: 80
      final property int swapCriticalThreshold: 90
      final property int diskWarningThreshold: 80
      final property int diskCriticalThreshold: 90
      final property int diskAvailWarningThreshold: 20
      final property int diskAvailCriticalThreshold: 10
      final property int batteryWarningThreshold: 20
      final property int batteryCriticalThreshold: 5
      final property bool enableDgpuMonitoring: false // Opt-in: reading dGPU sysfs/nvidia-smi wakes it from D3cold, draining battery
      final property bool useCustomColors: false
      final property string warningColor: ""
      final property string criticalColor: ""
      final property string externalMonitor: "taskmgr"
    }
    final property SystemMonitorSettings systemMonitor: SystemMonitorSettings {}

    // performance
    component OctaliaPerformanceSettings: JsonObject {
      final property bool disableWallpaper: true
      final property bool disableDesktopWidgets: true
    }
    final property OctaliaPerformanceSettings octaliaPerformance: OctaliaPerformanceSettings {}

    // dock
    component DockSettings: JsonObject {
      final property bool enabled: false
      final property string position: "bottom" // "top", "bottom", "left", "right"
      final property string displayMode: "auto_hide" // "always_visible", "auto_hide", "exclusive"
      final property string dockType: "floating" // "floating", "attached"
      final property real backgroundOpacity: 1.0
      final property real floatingRatio: 1.0
      final property real size: 1
      final property bool onlySameOutput: true
      final property list<string> monitors: [] // holds dock visibility per monitor
      final property list<string> pinnedApps: [] // Desktop entry IDs pinned to the dock (e.g., "org.kde.konsole", "firefox.desktop")
      final property bool colorizeIcons: false
      final property bool showLauncherIcon: false
      final property string launcherPosition: "end" // "start", "end"
      final property bool launcherUseDistroLogo: false
      final property string launcherIcon: ""
      final property string launcherIconColor: "none"
      final property bool pinnedStatic: false
      final property bool inactiveIndicators: false
      final property bool groupApps: false
      final property string groupContextMenuMode: "extended" // "list", "extended"
      final property string groupClickAction: "cycle" // "cycle", "list"
      final property string groupIndicatorStyle: "dots" // "number", "dots"
      final property double deadOpacity: 0.6
      final property real animationSpeed: 1.0 // Speed multiplier for hide/show animations (0.1 = slowest, 2.0 = fastest)
      final property bool sitOnFrame: false
      final property bool showDockIndicator: false
      final property int indicatorThickness: 3
      final property string indicatorColor: "primary"
      final property real indicatorOpacity: 0.6
    }
    final property DockSettings dock: DockSettings {}

    // network
    component NetworkSettings: JsonObject {
      final property bool bluetoothRssiPollingEnabled: false  // Opt-in Bluetooth RSSI polling (uses bluetoothctl)
      final property int bluetoothRssiPollIntervalMs: 60000 // Polling interval in milliseconds for RSSI queries
      final property string networkPanelView: "wifi"
      final property string wifiDetailsViewMode: "grid"   // "grid" or "list"
      final property string bluetoothDetailsViewMode: "grid" // "grid" or "list"
      final property bool bluetoothHideUnnamedDevices: false
      final property bool disableDiscoverability: false
      final property bool bluetoothAutoConnect: true
    }
    final property NetworkSettings network: NetworkSettings {}

    // session menu
    component SessionMenuSettings: JsonObject {
      final property bool enableCountdown: true
      final property int countdownDuration: 10000
      final property string position: "center"
      final property bool showHeader: true
      final property bool showKeybinds: true
      final property bool largeButtonsStyle: true
      final property string largeButtonsLayout: "single-row"
      final property list<var> powerOptions: [
        {
          "action": "lock",
          "enabled": true,
          "keybind": "1"
        },
        {
          "action": "suspend",
          "enabled": true,
          "keybind": "2"
        },
        {
          "action": "hibernate",
          "enabled": true,
          "keybind": "3"
        },
        {
          "action": "reboot",
          "enabled": true,
          "keybind": "4"
        },
        {
          "action": "logout",
          "enabled": true,
          "keybind": "5"
        },
        {
          "action": "shutdown",
          "enabled": true,
          "keybind": "6"
        },
        {
          "action": "rebootToUefi",
          "enabled": true,
          "keybind": "7"
        }
      ]
    }
    final property SessionMenuSettings sessionMenu: SessionMenuSettings {}

    // notifications
    component NotificationsSaveToHistorySettings: JsonObject {
      final property bool low: true
      final property bool normal: true
      final property bool critical: true
    }

    component NotificationsSoundsSettings: JsonObject {
      final property bool enabled: false
      final property real volume: 0.5
      final property bool separateSounds: false
      final property string criticalSoundFile: ""
      final property string normalSoundFile: ""
      final property string lowSoundFile: ""
      final property string excludedApps: "discord,firefox,chrome,chromium,edge"
    }

    component NotificationsSettings: JsonObject {
      final property bool enabled: true
      final property bool enableMarkdown: false
      final property string density: "default" // "default", "compact"
      final property list<string> monitors: [] // holds notifications visibility per monitor
      final property string location: "top_right"
      final property bool overlayLayer: true
      final property real backgroundOpacity: 1.0
      final property bool respectExpireTimeout: false
      final property int lowUrgencyDuration: 3
      final property int normalUrgencyDuration: 8
      final property int criticalUrgencyDuration: 15
      final property bool clearDismissed: true
      final property NotificationsSaveToHistorySettings saveToHistory: NotificationsSaveToHistorySettings {}
      final property NotificationsSoundsSettings sounds: NotificationsSoundsSettings {}
      final property bool enableMediaToast: false
      final property bool enableKeyboardLayoutToast: true
      final property bool enableBatteryToast: true
    }
    final property NotificationsSettings notifications: NotificationsSettings {}

    // on-screen display
    component OsdSettings: JsonObject {
      final property bool enabled: true
      final property string location: "top_right"
      final property int autoHideMs: 2000
      final property bool overlayLayer: true
      final property real backgroundOpacity: 1.0
      final property list<var> enabledTypes: [OSD.Type.Volume, OSD.Type.InputVolume, OSD.Type.Brightness]
      final property list<string> monitors: [] // holds osd visibility per monitor
    }
    final property OsdSettings osd: OsdSettings {}

    // audio
    component AudioSettings: JsonObject {
      final property int volumeStep: 5
      final property bool volumeOverdrive: false
      final property int spectrumFrameRate: 30
      final property string visualizerType: "linear"
      final property bool spectrumMirrored: true
      final property list<string> mprisBlacklist: []
      final property string preferredPlayer: ""
      final property bool volumeFeedback: false
      final property string volumeFeedbackSoundFile: ""
    }
    final property AudioSettings audio: AudioSettings {}

    // brightness
    component BrightnessSettings: JsonObject {
      final property int brightnessStep: 5
      final property bool enforceMinimum: true
      final property bool enableDdcSupport: false
      final property list<var> backlightDeviceMappings: []
      // Format: [{ "output": "eDP-1", "device": "/sys/class/backlight/intel_backlight" }]
    }
    final property BrightnessSettings brightness: BrightnessSettings {}

    component ColorSchemesSettings: JsonObject {
      final property bool useWallpaperColors: false
      final property string predefinedScheme: "Octalia (default)"
      final property bool darkMode: true
      final property string schedulingMode: "off"
      final property string manualSunrise: "06:30"
      final property string manualSunset: "18:30"
      final property string generationMethod: "tonal-spot"
      final property string monitorForColors: ""
      final property bool syncGsettings: true
    }
    final property ColorSchemesSettings colorSchemes: ColorSchemesSettings {}

    // templates toggles
    component TemplatesSettings: JsonObject {
      final property list<var> activeTemplates: []
      // Format: [{ "id": "gtk", "enabled": true }, { "id": "qt", "enabled": true }, ...]
      final property bool enableUserTheming: false
    }
    final property TemplatesSettings templates: TemplatesSettings {}

    // night light
    component NightLightSettings: JsonObject {
      final property bool enabled: false
      final property bool forced: false
      final property bool autoSchedule: true
      final property string nightTemp: "4000"
      final property string dayTemp: "6500"
      final property string manualSunrise: "06:30"
      final property string manualSunset: "18:30"
    }
    final property NightLightSettings nightLight: NightLightSettings {}

    // hooks
    component HooksSettings: JsonObject {
      final property bool enabled: false
      final property string wallpaperChange: ""
      final property string darkModeChange: ""
      final property string screenLock: ""
      final property string screenUnlock: ""
      final property string performanceModeEnabled: ""
      final property string performanceModeDisabled: ""
      final property string startup: ""
      final property string session: ""
      final property string colorGeneration: ""
    }
    final property HooksSettings hooks: HooksSettings {}

    // idle management
    component IdleSettings: JsonObject {
      final property bool enabled: false
      final property int screenOffTimeout: 600    // seconds, 0 = disabled
      final property int lockTimeout: 660         // seconds, 0 = disabled
      final property int suspendTimeout: 1800     // seconds, 0 = disabled
      final property int fadeDuration: 5       // seconds of fade-to-black before action fires
      final property string screenOffCommand: ""
      final property string lockCommand: ""
      final property string suspendCommand: ""
      final property string resumeScreenOffCommand: ""
      final property string resumeLockCommand: ""
      final property string resumeSuspendCommand: ""
      final property string customCommands: "[]" // JSON array of {timeout, command, resumeCommand}
    }
    final property IdleSettings idle: IdleSettings {}

    // desktop widgets
    component DesktopWidgetsSettings: JsonObject {
      final property bool enabled: false
      final property bool overviewEnabled: true
      final property bool gridSnap: false
      final property bool gridSnapScale: false
      final property list<var> monitorWidgets: []
      // Format: [{ "name": "DP-1", "widgets": [...] }, { "name": "HDMI-1", "widgets": [...] }]
    }
    final property DesktopWidgetsSettings desktopWidgets: DesktopWidgetsSettings {}
  }

  // -----------------------------------------------------
  // Preprocess paths by adding trailing "/"
  function ensureTrailingSlash(path) {
    return path.endsWith("/") ? path : path + "/";
  }

  // -----------------------------------------------------
  // Preprocess paths by expanding "~" to user's home directory
  function preprocessPath(path) {
    if (typeof path !== "string" || path === "") {
      return path;
    }

    // Expand "~" to user's home directory
    if (path.startsWith("~/")) {
      return Quickshell.env("HOME") + path.substring(1);
    } else if (path === "~") {
      return Quickshell.env("HOME");
    }

    return path;
  }

  // -----------------------------------------------------
  // Get default value for a setting path (e.g., "general.scaleRatio" or "bar.position")
  // Returns undefined if not found
  function getDefaultValue(path) {
    var i;
    if (!root._defaultSettings) {
      return undefined;
    }

    var parts = path.split(".");
    var current = root._defaultSettings;

    for (i = 0; i < parts.length; i++) {
      if (current === undefined || current === null) {
        return undefined;
      }
      current = current[parts[i]];
    }

    return current;
  }

  // -----------------------------------------------------
  // Compare current value with default value
  // Returns true if values differ, false if they match or default is not found
  function isValueChanged(path, currentValue): bool {
    var defaultValue = getDefaultValue(path);
    if (defaultValue === undefined) {
      return false; // Can't compare if default not found
    }

    // Deep comparison for objects and arrays
    if (typeof currentValue === "object" && typeof defaultValue === "object") {
      return JSON.stringify(currentValue) !== JSON.stringify(defaultValue);
    }

    // Simple comparison for primitives
    return currentValue !== defaultValue;
  }

  // -----------------------------------------------------
  // Helper to find a screen override entry by name in the array
  // Format: [{ "name": "HDMI-A-1", "position": "left" }, ...]
  // Note: QML's list<var> is not a true JS array, so we check for .length instead of Array.isArray()
  function _findScreenOverride(screenName) {
    var i;
    var overrides = data.bar.screenOverrides;
    if (!screenName || !overrides || overrides.length === undefined) {
      return null;
    }
    for (i = 0; i < overrides.length; i++) {
      if (overrides[i] && overrides[i].name === screenName) {
        return overrides[i];
      }
    }
    return null;
  }

  // Helper to find index of a screen override entry
  function _findScreenOverrideIndex(screenName): int {
    var i;
    var overrides = data.bar.screenOverrides;
    if (!screenName || !overrides || overrides.length === undefined) {
      return -1;
    }
    for (i = 0; i < overrides.length; i++) {
      if (overrides[i] && overrides[i].name === screenName) {
        return i;
      }
    }
    return -1;
  }

  // -----------------------------------------------------
  // Check if a screen's overrides are enabled
  // Returns true if enabled flag is true or undefined (backward compat)
  // Returns false only if enabled is explicitly false
  function isScreenOverrideEnabled(screenName): bool {
    var override = _findScreenOverride(screenName);
    if (!override) {
      return false;
    }
    return override.enabled !== false;
  }

  // -----------------------------------------------------
  // Get effective bar position for a screen (with inheritance)
  // If the screen has a position override and overrides are enabled, use it; otherwise use global default
  function getBarPositionForScreen(screenName) {
    var override = _findScreenOverride(screenName);
    if (override && override.enabled !== false && override.position !== undefined) {
      return override.position;
    }
    return data.bar.position || "top";
  }

  // -----------------------------------------------------
  // Get effective bar widgets for a screen (with inheritance)
  // If the screen has widget overrides and overrides are enabled, use them; otherwise use global defaults
  function getBarWidgetsForScreen(screenName) {
    var override = _findScreenOverride(screenName);
    if (override && override.enabled !== false && override.widgets !== undefined) {
      return override.widgets;
    }
    return data.bar.widgets;
  }

  // -----------------------------------------------------
  // Get effective bar density for a screen (with inheritance)
  // If the screen has a density override and overrides are enabled, use it; otherwise use global default
  function getBarDensityForScreen(screenName) {
    var override = _findScreenOverride(screenName);
    if (override && override.enabled !== false && override.density !== undefined) {
      return override.density;
    }
    return data.bar.density || "default";
  }

  // -----------------------------------------------------
  // Get effective bar display mode for a screen (with inheritance)
  // If the screen has a displayMode override and overrides are enabled, use it; otherwise use global default
  function getBarDisplayModeForScreen(screenName) {
    var override = _findScreenOverride(screenName);
    if (override && override.enabled !== false && override.displayMode !== undefined) {
      return override.displayMode;
    }
    return data.bar.displayMode || "always_visible";
  }

  // -----------------------------------------------------
  // Check if a screen has any overrides, optionally for a specific property
  function hasScreenOverride(screenName, property): bool {
    var override = _findScreenOverride(screenName);
    if (!override) {
      return false;
    }
    if (property) {
      return override[property] !== undefined;
    }
    // Check if screen has any override property (besides "name")
    var keys = Object.keys(override);
    return keys.length > 1 || (keys.length === 1 && keys[0] !== "name");
  }

  // -----------------------------------------------------
  // Get the screen override entry directly (for in-place modifications)
  // Returns the actual entry object from the array, not a copy
  function getScreenOverrideEntry(screenName) {
    return _findScreenOverride(screenName);
  }

  // -----------------------------------------------------
  // Set a per-screen override
  function setScreenOverride(screenName, property, value) {
    var i, newEntry;
    if (!screenName)
      return;

    var overrides = JSON.parse(JSON.stringify(data.bar.screenOverrides || []));
    if (overrides.length === undefined) {
      overrides = [];
    }

    var index = -1;
    for (i = 0; i < overrides.length; i++) {
      if (overrides[i] && overrides[i].name === screenName) {
        index = i;
        break;
      }
    }

    if (index === -1) {
      // Create new entry
      newEntry = {
        "name": screenName
      };
      newEntry[property] = value;
      overrides.push(newEntry);
    } else {
      // Update existing entry
      overrides[index][property] = value;
    }
    data.bar.screenOverrides = overrides;
  }

  // -----------------------------------------------------
  // Clear a per-screen override (revert to global default)
  // If property is null, clears all overrides for that screen
  function clearScreenOverride(screenName, property) {
    var i, keys;
    if (!screenName)
      return;

    var overrides = data.bar.screenOverrides;
    if (!overrides || overrides.length === undefined) {
      return;
    }

    overrides = JSON.parse(JSON.stringify(overrides));

    var index = -1;
    for (i = 0; i < overrides.length; i++) {
      if (overrides[i] && overrides[i].name === screenName) {
        index = i;
        break;
      }
    }

    if (index === -1) {
      return;
    }

    if (property) {
      delete overrides[index][property];
      // Remove screen entry if only "name" remains
      keys = Object.keys(overrides[index]);
      if (keys.length <= 1 && (keys.length === 0 || keys[0] === "name")) {
        overrides.splice(index, 1);
      }
    } else {
      overrides.splice(index, 1);
    }
    data.bar.screenOverrides = overrides;
  }

  // -----------------------------------------------------
  // Public function to trigger immediate settings saving
  function saveImmediate() {
    settingsFileView.writeAdapter();
    root.settingsSaved(); // Emit signal after saving
  }

  // -----------------------------------------------------
  // Generate default settings: for reference only, not used by the shell
  function generateDefaultSettings() {
    var defaultPath, jsonData, plainAdapter;
    try {
      Logger.d("Settings", "Generating settings-default.json");

      // Prepare a clean JSON
      plainAdapter = QtObj2JS.qtObjectToPlainObject(adapter);
      jsonData = JSON.stringify(plainAdapter, null, 2);

      defaultPath = Quickshell.shellDir + "/Assets/settings-default.json";

      Quickshell.execDetached(["sh", "-c", `cat > "${defaultPath}" << 'OCTALIA_EOF'\n${jsonData}\nOCTALIA_EOF`]);
    } catch (error) {
      Logger.e("Settings", "Failed to generate default settings file: " + error);
    }
  }

  // -----------------------------------------------------
  // Generate default widget settings: for reference only, not used by the shell
  function generateWidgetDefaultSettings() {
    var defaultPath, jsonData, output;
    try {
      Logger.d("Settings", "Generating settings-widgets-default.json");

      output = {
        "bar": QtObj2JS.qtObjectToPlainObject(BarWidgetRegistry.widgetMetadata),
        "controlCenter": QtObj2JS.qtObjectToPlainObject(ControlCenterWidgetRegistry.widgetMetadata),
        "desktop": QtObj2JS.qtObjectToPlainObject(DesktopWidgetRegistry.widgetMetadata)
      };
      jsonData = JSON.stringify(output, null, 2);

      defaultPath = Quickshell.shellDir + "/Assets/settings-widgets-default.json";

      Quickshell.execDetached(["sh", "-c", `cat > "${defaultPath}" << 'OCTALIA_EOF'\n${jsonData}\nOCTALIA_EOF`]);
    } catch (error) {
      Logger.e("Settings", "Failed to generate widget default settings file: " + error);
    }
  }

  // -----------------------------------------------------
  // Run versioned migrations using MigrationRegistry
  // rawJson is the parsed JSON file content (before adapter filtering)
  function runVersionedMigrations(rawJson) {
    var i;
    // Skip migrations on fresh installs (no prior settings file)
    if (!rawJson || root.isFreshInstall) {
      Logger.i("Settings", "Fresh install detected, skipping migrations");
      return;
    }

    const currentVersion = adapter.settingsVersion;
    const migrations = MigrationRegistry.migrations;

    Logger.i("Settings", "adapter.settingsVersion:", adapter.settingsVersion);

    // Get all migration versions and sort them
    const versions = Object.keys(migrations).map(v => parseInt(v)).sort((a, b) => a - b);

    // Run migrations in order for versions newer than current
    for (i = 0; i < versions.length; i++) {
      const version = versions[i];

      if (currentVersion < version) {
        // Create migration instance and run it
        const migrationComponent = migrations[version];
        const migration = migrationComponent.createObject(root);

        if (migration && typeof migration.migrate === "function") {
          const success = migration.migrate(adapter, Logger, rawJson);
          if (!success) {
            Logger.e("Settings", "Migration to v" + version + " failed");
          }
        } else {
          Logger.e("Settings", "Invalid migration for v" + version);
        }

        // Clean up migration instance
        if (migration) {
          migration.destroy();
        }
      }
    }
  }

  // -----------------------------------------------------
  // If the settings structure has changed, ensure
  // backward compatibility by upgrading the settings
  function upgradeSettings() {
    var desktopWidget, i, m, s, shortcut, widget;
    // Wait for BarWidgetRegistry to be ready
    if (!BarWidgetRegistry.widgets || Object.keys(BarWidgetRegistry.widgets).length === 0) {
      Logger.d("Settings", "BarWidgetRegistry not ready, deferring upgrade");
      Qt.callLater(upgradeSettings);
      return;
    }

    // -----------------
    const sections = ["left", "center", "right"];

    // 1. remove any non existing bar widget type
    var removedWidget = false;
    for (s = 0; s < sections.length; s++) {
      const sectionName = sections[s];
      const widgets = adapter.bar.widgets[sectionName];
      // Iterate backward through the widgets array, so it does not break when removing a widget
      for (i = widgets.length - 1; i >= 0; i--) {
        widget = widgets[i];
        if (!BarWidgetRegistry.hasWidget(widget.id)) {
          Logger.w(`Settings`, `!!! Deleted invalid bar widget ${widget.id} !!!`);
          widgets.splice(i, 1);
          removedWidget = true;
        }
      }
    }

    // -----------------
    // 2. remove any non existing control center widget type
    const ccSections = ["left", "right"];
    for (s = 0; s < ccSections.length; s++) {
      const sectionName = ccSections[s];
      const shortcuts = adapter.controlCenter.shortcuts[sectionName];
      for (i = shortcuts.length - 1; i >= 0; i--) {
        shortcut = shortcuts[i];
        if (!ControlCenterWidgetRegistry.hasWidget(shortcut.id)) {
          Logger.w(`Settings`, `!!! Deleted invalid control center widget ${shortcut.id} !!!`);
          shortcuts.splice(i, 1);
          removedWidget = true;
        }
      }
    }

    // -----------------
    // 3. remove any non existing desktop widget type
    const monitorWidgets = adapter.desktopWidgets.monitorWidgets;
    for (m = 0; m < monitorWidgets.length; m++) {
      const monitor = monitorWidgets[m];
      if (!monitor.widgets)
        continue;
      for (i = monitor.widgets.length - 1; i >= 0; i--) {
        desktopWidget = monitor.widgets[i];
        if (!DesktopWidgetRegistry.hasWidget(desktopWidget.id)) {
          Logger.w(`Settings`, `!!! Deleted invalid desktop widget ${desktopWidget.id} !!!`);
          monitor.widgets.splice(i, 1);
          removedWidget = true;
        }
      }
    }

    // -----------------
    // 4. upgrade user widget settings
    for (s = 0; s < sections.length; s++) {
      const sectionName = sections[s];
      for (i = 0; i < adapter.bar.widgets[sectionName].length; i++) {
        widget = adapter.bar.widgets[sectionName][i];

        // Check if widget registry supports user settings, if it does not, then there is nothing to do
        if (BarWidgetRegistry.widgetMetadata[widget.id] === undefined) {
          continue;
        }

        if (upgradeWidget(widget)) {
          Logger.d("Settings", `Upgraded ${widget.id} widget:`, JSON.stringify(widget));
        }
      }
    }
  }

  // -----------------------------------------------------
  // Function to clean up deprecated user/custom bar widgets settings
  function upgradeWidget(widget) {
    var i;
    // Backup the widget definition before altering
    const widgetBefore = JSON.stringify(widget);

    // Get all existing custom settings keys
    const keys = Object.keys(BarWidgetRegistry.widgetMetadata[widget.id]);

    // Delete deprecated user settings from the wiget
    for (const k of Object.keys(widget)) {
      if (k === "id") {
        continue;
      }
      if (!keys.includes(k)) {
        delete widget[k];
      }
    }

    // Inject missing default setting (metaData) from BarWidgetRegistry
    for (i = 0; i < keys.length; i++) {
      const k = keys[i];
      if (k === "id") {
        continue;
      }

      if (widget[k] === undefined) {
        widget[k] = BarWidgetRegistry.widgetMetadata[widget.id][k];
      }
    }

    // Compare settings, to detect if something has been upgraded
    const widgetAfter = JSON.stringify(widget);
    return (widgetAfter !== widgetBefore);
  }
}
