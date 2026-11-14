pragma ComponentBehavior: Bound
import QtQuick
import "ScaleSizes.js" as SS

// Tokens.sizes: the panel size tokens of TokenConfig.sizes times `scale`, as typed properties.
// Generated from the names in ScaleSizes.js.
QtObject {
    id: root

    required final property var source
    final property real scale: 1

    readonly final property BarSizes bar: BarSizes {}

    readonly final property DashboardSizes dashboard: DashboardSizes {}

    readonly final property LauncherSizes launcher: LauncherSizes {}

    readonly final property NotifsSizes notifs: NotifsSizes {}

    readonly final property OsdSizes osd: OsdSizes {}

    readonly final property SessionSizes session: SessionSizes {}

    readonly final property SidebarSizes sidebar: SidebarSizes {}

    readonly final property UtilitiesSizes utilities: UtilitiesSizes {}

    readonly final property LockSizes lock: LockSizes {}

    readonly final property WinfoSizes winfo: WinfoSizes {}

    readonly final property NexusSizes nexus: NexusSizes {}

    component BarSizes: QtObject {
        readonly final property int innerWidth: SS.sized(root.source, "bar", "innerWidth", root.scale)
        readonly final property int windowPreviewSize: SS.sized(root.source, "bar", "windowPreviewSize", root.scale)
        readonly final property int trayMenuWidth: SS.sized(root.source, "bar", "trayMenuWidth", root.scale)
        readonly final property int batteryWidth: SS.sized(root.source, "bar", "batteryWidth", root.scale)
        readonly final property int networkWidth: SS.sized(root.source, "bar", "networkWidth", root.scale)
        readonly final property int audioWidth: SS.sized(root.source, "bar", "audioWidth", root.scale)
        readonly final property int kbLayoutWidth: SS.sized(root.source, "bar", "kbLayoutWidth", root.scale)
    }

    component DashboardSizes: QtObject {
        readonly final property int tabIndicatorHeight: SS.sized(root.source, "dashboard", "tabIndicatorHeight", root.scale)
        readonly final property int tabIndicatorSpacing: SS.sized(root.source, "dashboard", "tabIndicatorSpacing", root.scale)
        readonly final property int userWidth: SS.sized(root.source, "dashboard", "userWidth", root.scale)
        readonly final property int logoSize: SS.sized(root.source, "dashboard", "logoSize", root.scale)
        readonly final property int uptimeSize: SS.sized(root.source, "dashboard", "uptimeSize", root.scale)
        readonly final property int dateTimeWidth: SS.sized(root.source, "dashboard", "dateTimeWidth", root.scale)
        readonly final property int mediaWidth: SS.sized(root.source, "dashboard", "mediaWidth", root.scale)
        readonly final property int mediaProgressThickness: SS.sized(root.source, "dashboard", "mediaProgressThickness", root.scale)
        readonly final property int resourceProgressThickness: SS.sized(root.source, "dashboard", "resourceProgressThickness", root.scale)
        readonly final property int weatherWidth: SS.sized(root.source, "dashboard", "weatherWidth", root.scale)
        readonly final property int mediaCoverArtSize: SS.sized(root.source, "dashboard", "mediaCoverArtSize", root.scale)
        readonly final property int mediaTabWidth: SS.sized(root.source, "dashboard", "mediaTabWidth", root.scale)
        readonly final property int mediaTabHeight: SS.sized(root.source, "dashboard", "mediaTabHeight", root.scale)
        readonly final property int mediaSectionWidth: SS.sized(root.source, "dashboard", "mediaSectionWidth", root.scale)
        readonly final property int perfHeroCardWidth: SS.sized(root.source, "dashboard", "perfHeroCardWidth", root.scale)
        readonly final property int perfUsageShapeSize: SS.sized(root.source, "dashboard", "perfUsageShapeSize", root.scale)
        readonly final property int perfStorageTextWidth: SS.sized(root.source, "dashboard", "perfStorageTextWidth", root.scale)
        readonly final property int perfNetworkCardWidth: SS.sized(root.source, "dashboard", "perfNetworkCardWidth", root.scale)
        readonly final property int perfNetworkCardHeight: SS.sized(root.source, "dashboard", "perfNetworkCardHeight", root.scale)
        readonly final property int perfBattWidth: SS.sized(root.source, "dashboard", "perfBattWidth", root.scale)
        readonly final property int perfBattWidthSingle: SS.sized(root.source, "dashboard", "perfBattWidthSingle", root.scale)
        readonly final property int perfBattHeight: SS.sized(root.source, "dashboard", "perfBattHeight", root.scale)
        readonly final property int perfPlaceholderWidth: SS.sized(root.source, "dashboard", "perfPlaceholderWidth", root.scale)
        readonly final property real mediaProgressSweep: SS.kept(root.source, "dashboard", "mediaProgressSweep")
    }

    component LauncherSizes: QtObject {
        readonly final property int itemWidth: SS.sized(root.source, "launcher", "itemWidth", root.scale)
        readonly final property int itemHeight: SS.sized(root.source, "launcher", "itemHeight", root.scale)
        readonly final property int wallpaperWidth: SS.sized(root.source, "launcher", "wallpaperWidth", root.scale)
        readonly final property int wallpaperHeight: SS.sized(root.source, "launcher", "wallpaperHeight", root.scale)
    }

    component NotifsSizes: QtObject {
        readonly final property int width: SS.sized(root.source, "notifs", "width", root.scale)
        readonly final property int image: SS.sized(root.source, "notifs", "image", root.scale)
        readonly final property int badge: SS.sized(root.source, "notifs", "badge", root.scale)
    }

    component OsdSizes: QtObject {
        readonly final property int sliderWidth: SS.sized(root.source, "osd", "sliderWidth", root.scale)
        readonly final property int sliderHeight: SS.sized(root.source, "osd", "sliderHeight", root.scale)
    }

    component SessionSizes: QtObject {
        readonly final property int button: SS.sized(root.source, "session", "button", root.scale)
    }

    component SidebarSizes: QtObject {
        readonly final property int width: SS.sized(root.source, "sidebar", "width", root.scale)
    }

    component UtilitiesSizes: QtObject {
        readonly final property int width: SS.sized(root.source, "utilities", "width", root.scale)
        readonly final property int toastWidth: SS.sized(root.source, "utilities", "toastWidth", root.scale)
    }

    component LockSizes: QtObject {
        readonly final property int centerWidth: SS.sized(root.source, "lock", "centerWidth", root.scale)
        readonly final property int showWeatherDetailsHeight: SS.sized(root.source, "lock", "showWeatherDetailsHeight", root.scale)
        readonly final property int showForecastHeight: SS.sized(root.source, "lock", "showForecastHeight", root.scale)
        readonly final property int forecastItemWidth: SS.sized(root.source, "lock", "forecastItemWidth", root.scale)
        readonly final property int largeLogoWidth: SS.sized(root.source, "lock", "largeLogoWidth", root.scale)
        readonly final property int largeFontWidth: SS.sized(root.source, "lock", "largeFontWidth", root.scale)
        readonly final property int fetch4LinesHeight: SS.sized(root.source, "lock", "fetch4LinesHeight", root.scale)
        readonly final property int fetch3LinesHeight: SS.sized(root.source, "lock", "fetch3LinesHeight", root.scale)
        readonly final property int showColourBoxRowHeight: SS.sized(root.source, "lock", "showColourBoxRowHeight", root.scale)
        readonly final property real heightMult: SS.kept(root.source, "lock", "heightMult")
        readonly final property real ratio: SS.kept(root.source, "lock", "ratio")
    }

    component WinfoSizes: QtObject {
        readonly final property int detailsWidth: SS.sized(root.source, "winfo", "detailsWidth", root.scale)
        readonly final property real heightMult: SS.kept(root.source, "winfo", "heightMult")
    }

    component NexusSizes: QtObject {
        readonly final property int minWidth: SS.sized(root.source, "nexus", "minWidth", root.scale)
        readonly final property int minHeight: SS.sized(root.source, "nexus", "minHeight", root.scale)
        readonly final property int maxNavWidth: SS.sized(root.source, "nexus", "maxNavWidth", root.scale)
        readonly final property int maxContentWidth: SS.sized(root.source, "nexus", "maxContentWidth", root.scale)
        readonly final property int popupWidth: SS.sized(root.source, "nexus", "popupWidth", root.scale)
        readonly final property int minPopupHeight: SS.sized(root.source, "nexus", "minPopupHeight", root.scale)
        readonly final property int maxPopupHeight: SS.sized(root.source, "nexus", "maxPopupHeight", root.scale)
        readonly final property int networkShowEthDetailWidth: SS.sized(root.source, "nexus", "networkShowEthDetailWidth", root.scale)
        readonly final property int networkShowVpnDetailWidth: SS.sized(root.source, "nexus", "networkShowVpnDetailWidth", root.scale)
        readonly final property int maxDialogWidth: SS.sized(root.source, "nexus", "maxDialogWidth", root.scale)
        readonly final property int maxDialogHeight: SS.sized(root.source, "nexus", "maxDialogHeight", root.scale)
        readonly final property int textFieldWidth: SS.sized(root.source, "nexus", "textFieldWidth", root.scale)
        readonly final property int smallTextFieldWidth: SS.sized(root.source, "nexus", "smallTextFieldWidth", root.scale)
        readonly final property real heightMult: SS.kept(root.source, "nexus", "heightMult")
        readonly final property real ratio: SS.kept(root.source, "nexus", "ratio")
    }
}
