pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Port of upstream's TokenConfig (the shell-tokens.json design tokens). Defaults are the C++
// defaults of plugin/src/Celeste/Config/tokens.hpp. The file is config/shell-tokens.json in
// the config home. No per-screen overrides: forScreen returns this object.
QtObject {
    id: root

    function forScreen(screen: string): var {
        return root;
    }

    function save(): void {
        fileView.writeAdapter();
    }

    property alias appearance: adapter.appearance
    property alias sizes: adapter.sizes
    property alias scale: adapter.scale
    property alias fontScale: adapter.fontScale
    property alias roundingScale: adapter.roundingScale

    component AppearanceCurvesCfg: JsonObject {
        final property var emphasized: [0.05, 0, 2.0 / 15.0, 0.06, 1.0 / 6.0, 0.4, 5.0 / 24.0, 0.82, 0.25, 1, 1, 1]
        final property var emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
        final property var emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
        final property var standard: [0.2, 0, 0, 1, 1, 1]
        final property var standardAccel: [0.3, 0, 1, 1, 1, 1]
        final property var standardDecel: [0, 0, 0, 1, 1, 1]
        final property var expressiveFastSpatial: [0.42, 1.67, 0.21, 0.9, 1, 1]
        final property var expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1, 1, 1]
        final property var expressiveSlowSpatial: [0.39, 1.29, 0.35, 0.98, 1, 1]
        final property var expressiveFastEffects: [0.31, 0.94, 0.34, 1, 1, 1]
        final property var expressiveDefaultEffects: [0.34, 0.8, 0.34, 1, 1, 1]
        final property var expressiveSlowEffects: [0.34, 0.88, 0.34, 1, 1, 1]
    }

    component AppearanceRoundingCfg: JsonObject {
        final property int extraSmall: 4
        final property int small: 8
        final property int medium: 12
        final property int large: 16
        final property int largeIncreased: 20
        final property int extraLarge: 28
        final property int extraLargeIncreased: 32
        final property int extraExtraLarge: 48
        final property int full: 2147483647 // std::numeric_limits<int>::max()
    }

    component AppearanceSpacingCfg: JsonObject {
        final property int extraSmall: 4
        final property int small: 8
        final property int medium: 12
        final property int large: 16
        final property int largeIncreased: 20
        final property int extraLarge: 28
        final property int extraLargeIncreased: 32
        final property int extraExtraLarge: 48
    }

    component AppearancePaddingCfg: JsonObject {
        final property int extraSmall: 4
        final property int small: 8
        final property int medium: 12
        final property int large: 16
        final property int largeIncreased: 20
        final property int extraLarge: 28
        final property int extraLargeIncreased: 32
        final property int extraExtraLarge: 48
    }

    component AppearanceFontSizeCfg: JsonObject {
        final property int small: 11
        final property int smaller: 12
        final property int normal: 13
        final property int larger: 15
        final property int large: 18
        final property int extraLarge: 28
    }

    component AppearanceAnimDurationsCfg: JsonObject {
        final property int small: 200
        final property int normal: 400
        final property int large: 600
        final property int extraLarge: 1000
        final property int expressiveFastSpatial: 350
        final property int expressiveDefaultSpatial: 500
        final property int expressiveSlowSpatial: 650
        final property int expressiveFastEffects: 150
        final property int expressiveDefaultEffects: 200
        final property int expressiveSlowEffects: 300
    }

    component AppearanceCfg: JsonObject {
        // Cubic bezier segments for Easing.BezierSpline: c1x, c1y, c2x, c2y, endX, endY per segment
        final property AppearanceCurvesCfg curves: AppearanceCurvesCfg {}
        final property AppearanceRoundingCfg rounding: AppearanceRoundingCfg {}
        final property AppearanceSpacingCfg spacing: AppearanceSpacingCfg {}
        final property AppearancePaddingCfg padding: AppearancePaddingCfg {}
        final property AppearanceFontSizeCfg fontSize: AppearanceFontSizeCfg {}
        final property AppearanceAnimDurationsCfg animDurations: AppearanceAnimDurationsCfg {}
    }

    component SizesBarCfg: JsonObject {
        final property int innerWidth: 40
        final property int windowPreviewSize: 400
        final property int trayMenuWidth: 300
        final property int batteryWidth: 250
        final property int networkWidth: 320
        final property int audioWidth: 320
        final property int kbLayoutWidth: 320
    }

    component SizesDashboardCfg: JsonObject {
        final property int tabIndicatorHeight: 3
        final property int tabIndicatorSpacing: 5
        final property int userWidth: 340
        final property int logoSize: 30
        final property int uptimeSize: 30
        final property int dateTimeWidth: 110
        final property int mediaWidth: 200
        final property int mediaProgressSweep: 180
        final property int mediaProgressThickness: 6
        final property int resourceProgressThickness: 6
        final property int weatherWidth: 275
        final property int mediaCoverArtSize: 200
        final property int mediaTabWidth: 1000
        final property int mediaTabHeight: 320
        final property int mediaSectionWidth: 300
        final property int perfHeroCardWidth: 400
        final property int perfUsageShapeSize: 100
        final property int perfStorageTextWidth: 160
        final property int perfNetworkCardWidth: 390
        final property int perfNetworkCardHeight: 220
        final property int perfBattWidth: 150
        final property int perfBattWidthSingle: 400
        final property int perfBattHeight: 160
        final property int perfPlaceholderWidth: 700
    }

    component SizesLauncherCfg: JsonObject {
        final property int itemWidth: 600
        final property int itemHeight: 57
        final property int wallpaperWidth: 280
        final property int wallpaperHeight: 200
    }

    component SizesNotifsCfg: JsonObject {
        final property int width: 430
        final property int image: 42
        final property int badge: 20
    }

    component SizesOsdCfg: JsonObject {
        final property int sliderWidth: 30
        final property int sliderHeight: 150
    }

    component SizesSessionCfg: JsonObject {
        final property int button: 80
    }

    component SizesSidebarCfg: JsonObject {
        final property int width: 430
    }

    component SizesUtilitiesCfg: JsonObject {
        final property int width: 430
        final property int toastWidth: 430
    }

    component SizesLockCfg: JsonObject {
        final property real heightMult: 0.7
        final property real ratio: 16.0 / 9.0
        final property int centerWidth: 600
        final property int showWeatherDetailsHeight: 550
        final property int showForecastHeight: 975
        final property int forecastItemWidth: 51
        final property int largeLogoWidth: 320
        final property int largeFontWidth: 400
        final property int fetch4LinesHeight: 600
        final property int fetch3LinesHeight: 500
        final property int showColourBoxRowHeight: 570
    }

    component SizesWinfoCfg: JsonObject {
        final property real heightMult: 0.7
        final property real detailsWidth: 500
    }

    component SizesNexusCfg: JsonObject {
        final property real heightMult: 0.7
        final property real ratio: 16.0 / 9.0
        final property int minWidth: 800
        final property int minHeight: 500
        final property int maxNavWidth: 600
        final property int maxContentWidth: 800
        final property int popupWidth: 300
        final property int minPopupHeight: 200
        final property int maxPopupHeight: 800
        final property int networkShowEthDetailWidth: 620
        final property int networkShowVpnDetailWidth: 620
        final property int maxDialogWidth: 400
        final property int maxDialogHeight: 600
        final property int textFieldWidth: 250
        final property int smallTextFieldWidth: 100
    }

    component SizesCfg: JsonObject {
        final property SizesBarCfg bar: SizesBarCfg {}
        final property SizesDashboardCfg dashboard: SizesDashboardCfg {}
        final property SizesLauncherCfg launcher: SizesLauncherCfg {}
        final property SizesNotifsCfg notifs: SizesNotifsCfg {}
        final property SizesOsdCfg osd: SizesOsdCfg {}
        final property SizesSessionCfg session: SizesSessionCfg {}
        final property SizesSidebarCfg sidebar: SizesSidebarCfg {}
        final property SizesUtilitiesCfg utilities: SizesUtilitiesCfg {}
        final property SizesLockCfg lock: SizesLockCfg {}
        final property SizesWinfoCfg winfo: SizesWinfoCfg {}
        final property SizesNexusCfg nexus: SizesNexusCfg {}
    }

    property FileView file: FileView {
        id: fileView

        path: Quickshell.shellPath("config/shell-tokens.json")
        watchChanges: true
        printErrors: false
        onFileChanged: reload()

        adapter: JsonAdapter {
            id: adapter

            // UI scale. `scale` multiplies every size token (spacing, padding, rounding, fonts,
            // panel sizes); a number, or "auto" to derive it from the screen's devicePixelRatio.
            // `fontScale` is an extra factor for text only, `roundingScale` one for corner radii only.
            // The celeste tokens are designed for about 1x; 0.75 suits a 150% Windows display.
            property var scale: 0.75
            property real fontScale: 1.0
            property real roundingScale: 1.0

            final property AppearanceCfg appearance: AppearanceCfg {}

            final property SizesCfg sizes: SizesCfg {}
        }
    }
}
