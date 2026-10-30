pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Port of upstream's TokenConfig (the shell-tokens.json design tokens). Defaults are the C++
// defaults of plugin/src/Caelestia/Config/tokens.hpp. The file is config/shell-tokens.json in
// the config home. No per-screen overrides: forScreen returns this object.
QtObject {
    id: root

    function forScreen(screen: string): var {
        return root;
    }

    function save(): void {
        file.writeAdapter();
    }

    property alias appearance: adapter.appearance
    property alias sizes: adapter.sizes

    property FileView file: FileView {
        id: file

        path: Quickshell.shellPath("config/shell-tokens.json")
        watchChanges: true
        printErrors: false
        onFileChanged: reload()

        adapter: JsonAdapter {
            id: adapter

            property JsonObject appearance: JsonObject {
                // Cubic bezier segments for Easing.BezierSpline: c1x, c1y, c2x, c2y, endX, endY per segment
                property JsonObject curves: JsonObject {
                    property var emphasized: [0.05, 0, 2.0 / 15.0, 0.06, 1.0 / 6.0, 0.4, 5.0 / 24.0, 0.82, 0.25, 1, 1, 1]
                    property var emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
                    property var emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
                    property var standard: [0.2, 0, 0, 1, 1, 1]
                    property var standardAccel: [0.3, 0, 1, 1, 1, 1]
                    property var standardDecel: [0, 0, 0, 1, 1, 1]
                    property var expressiveFastSpatial: [0.42, 1.67, 0.21, 0.9, 1, 1]
                    property var expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1, 1, 1]
                    property var expressiveSlowSpatial: [0.39, 1.29, 0.35, 0.98, 1, 1]
                    property var expressiveFastEffects: [0.31, 0.94, 0.34, 1, 1, 1]
                    property var expressiveDefaultEffects: [0.34, 0.8, 0.34, 1, 1, 1]
                    property var expressiveSlowEffects: [0.34, 0.88, 0.34, 1, 1, 1]
                }
                property JsonObject rounding: JsonObject {
                    property int extraSmall: 4
                    property int small: 8
                    property int medium: 12
                    property int large: 16
                    property int largeIncreased: 20
                    property int extraLarge: 28
                    property int extraLargeIncreased: 32
                    property int extraExtraLarge: 48
                    property int full: 2147483647 // std::numeric_limits<int>::max()
                }
                property JsonObject spacing: JsonObject {
                    property int extraSmall: 4
                    property int small: 8
                    property int medium: 12
                    property int large: 16
                    property int largeIncreased: 20
                    property int extraLarge: 28
                    property int extraLargeIncreased: 32
                    property int extraExtraLarge: 48
                }
                property JsonObject padding: JsonObject {
                    property int extraSmall: 4
                    property int small: 8
                    property int medium: 12
                    property int large: 16
                    property int largeIncreased: 20
                    property int extraLarge: 28
                    property int extraLargeIncreased: 32
                    property int extraExtraLarge: 48
                }
                property JsonObject fontSize: JsonObject {
                    property int small: 11
                    property int smaller: 12
                    property int normal: 13
                    property int larger: 15
                    property int large: 18
                    property int extraLarge: 28
                }
                property JsonObject animDurations: JsonObject {
                    property int small: 200
                    property int normal: 400
                    property int large: 600
                    property int extraLarge: 1000
                    property int expressiveFastSpatial: 350
                    property int expressiveDefaultSpatial: 500
                    property int expressiveSlowSpatial: 650
                    property int expressiveFastEffects: 150
                    property int expressiveDefaultEffects: 200
                    property int expressiveSlowEffects: 300
                }
            }

            property JsonObject sizes: JsonObject {
                property JsonObject bar: JsonObject {
                    property int innerWidth: 40
                    property int windowPreviewSize: 400
                    property int trayMenuWidth: 300
                    property int batteryWidth: 250
                    property int networkWidth: 320
                    property int audioWidth: 320
                    property int kbLayoutWidth: 320
                }
                property JsonObject dashboard: JsonObject {
                    property int tabIndicatorHeight: 3
                    property int tabIndicatorSpacing: 5
                    property int userWidth: 340
                    property int logoSize: 30
                    property int uptimeSize: 30
                    property int dateTimeWidth: 110
                    property int mediaWidth: 200
                    property int mediaProgressSweep: 180
                    property int mediaProgressThickness: 6
                    property int resourceProgressThickness: 6
                    property int weatherWidth: 275
                    property int mediaCoverArtSize: 200
                    property int mediaTabWidth: 1000
                    property int mediaTabHeight: 320
                    property int mediaSectionWidth: 300
                    property int perfHeroCardWidth: 400
                    property int perfUsageShapeSize: 100
                    property int perfStorageTextWidth: 160
                    property int perfNetworkCardWidth: 390
                    property int perfNetworkCardHeight: 220
                    property int perfBattWidth: 150
                    property int perfBattWidthSingle: 400
                    property int perfBattHeight: 160
                    property int perfPlaceholderWidth: 700
                }
                property JsonObject launcher: JsonObject {
                    property int itemWidth: 600
                    property int itemHeight: 57
                    property int wallpaperWidth: 280
                    property int wallpaperHeight: 200
                }
                property JsonObject notifs: JsonObject {
                    property int width: 430
                    property int image: 42
                    property int badge: 20
                }
                property JsonObject osd: JsonObject {
                    property int sliderWidth: 30
                    property int sliderHeight: 150
                }
                property JsonObject session: JsonObject {
                    property int button: 80
                }
                property JsonObject sidebar: JsonObject {
                    property int width: 430
                }
                property JsonObject utilities: JsonObject {
                    property int width: 430
                    property int toastWidth: 430
                }
                property JsonObject lock: JsonObject {
                    property real heightMult: 0.7
                    property real ratio: 16.0 / 9.0
                    property int centerWidth: 600
                    property int showWeatherDetailsHeight: 550
                    property int showForecastHeight: 975
                    property int forecastItemWidth: 51
                    property int largeLogoWidth: 320
                    property int largeFontWidth: 400
                    property int fetch4LinesHeight: 600
                    property int fetch3LinesHeight: 500
                    property int showColourBoxRowHeight: 570
                }
                property JsonObject winfo: JsonObject {
                    property real heightMult: 0.7
                    property real detailsWidth: 500
                }
                property JsonObject nexus: JsonObject {
                    property real heightMult: 0.7
                    property real ratio: 16.0 / 9.0
                    property int minWidth: 800
                    property int minHeight: 500
                    property int maxNavWidth: 600
                    property int maxContentWidth: 800
                    property int popupWidth: 300
                    property int minPopupHeight: 200
                    property int maxPopupHeight: 800
                    property int networkShowEthDetailWidth: 620
                    property int networkShowVpnDetailWidth: 620
                    property int maxDialogWidth: 400
                    property int maxDialogHeight: 600
                    property int textFieldWidth: 250
                    property int smallTextFieldWidth: 100
                }
            }
        }
    }
}
