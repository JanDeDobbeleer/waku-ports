pragma ComponentBehavior: Bound

import "items"
import QtQuick
import Quickshell
import Celeste.Config
import qs.components.controls
import qs.services
import "WallpaperListHelpers.js" as WallpaperListHelpers

PathView {
    id: root

    required final property SearchBar search
    required final property var screenState
    required final property var panels
    required final property var content

    readonly final property int itemWidth: Tokens.sizes.launcher.wallpaperWidth * 0.8 + Tokens.padding.medium * 2

    readonly final property int numItems: WallpaperListHelpers.numItems(QsWindow.window, panels, screenState, content, Config.border, Config.launcher.maxWallpapers, itemWidth, scriptModel.values.length)

    model: ScriptModel {
        id: scriptModel

        readonly final property string search: WallpaperListHelpers.search(root.search)

        // waku: entries of an earlier directory scan are destroyed, so drop the nulls.
        values: WallpaperListHelpers.query(WallpaperService, search)
        onValuesChanged: root.currentIndex = WallpaperListHelpers.queryIndex(values, search, WallpaperService.actualCurrent)
    }

    Component.onCompleted: currentIndex = WallpaperListHelpers.currentIndex(WallpaperService.list, WallpaperService.actualCurrent)
    Component.onDestruction: WallpaperService.stopPreview()

    onCurrentItemChanged: WallpaperListHelpers.preview(WallpaperService, currentItem)

    implicitWidth: Math.min(numItems, count) * itemWidth
    pathItemCount: numItems
    cacheItemCount: 4

    snapMode: PathView.SnapToItem
    preferredHighlightBegin: 0.5
    preferredHighlightEnd: 0.5
    highlightRangeMode: PathView.StrictlyEnforceRange

    delegate: WallpaperItem {
        screenState: root.screenState
    }

    path: Path {
        startY: root.height / 2

        PathAttribute {
            name: "z"
            value: 0
        }
        PathLine {
            x: root.width / 2
            relativeY: 0
        }
        PathAttribute {
            name: "z"
            value: 1
        }
        PathLine {
            x: root.width
            relativeY: 0
        }
    }

    CustomMouseArea {
        function onWheel(event: WheelEvent): void {
            if (event.angleDelta.y > 0)
                root.decrementCurrentIndex();
            else if (event.angleDelta.y < 0)
                root.incrementCurrentIndex();
        }

        anchors.fill: parent
    }
}
