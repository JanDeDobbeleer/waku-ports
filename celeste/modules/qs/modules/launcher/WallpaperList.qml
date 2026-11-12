pragma ComponentBehavior: Bound

import "items"
import QtQuick
import Quickshell
import Celeste.Config
import qs.components.controls
import qs.services

PathView {
    id: root

    required final property SearchBar search
    required final property var screenState
    required final property var panels
    required final property var content

    readonly final property int itemWidth: Tokens.sizes.launcher.wallpaperWidth * 0.8 + Tokens.padding.medium * 2

    readonly final property int numItems: {
        const screen = QsWindow.window?.screen;
        if (!screen)
            return 0;

        // Screen width - 4x outer rounding - 2x max side thickness (cause centered)
        const barMargins = Math.max(Config.border.thickness, panels.bar.implicitWidth);
        let outerMargins = 0;
        if (panels.popouts.hasCurrent && panels.popouts.currentCenter + panels.popouts.nonAnimHeight / 2 > screen.height - content.implicitHeight - Config.border.thickness * 2)
            outerMargins = panels.popouts.nonAnimWidth;
        if ((screenState.utilities || screenState.sidebar) && panels.utilities.implicitWidth > outerMargins)
            outerMargins = panels.utilities.implicitWidth;
        const maxWidth = screen.width - Config.border.rounding * 4 - (barMargins + outerMargins) * 2;

        if (maxWidth <= 0)
            return 0;

        const maxItemsOnScreen = Math.floor(maxWidth / itemWidth);
        const visible = Math.min(maxItemsOnScreen, Config.launcher.maxWallpapers, scriptModel.values.length);

        if (visible === 2)
            return 1;
        if (visible > 1 && visible % 2 === 0)
            return visible - 1;
        return visible;
    }

    model: ScriptModel {
        id: scriptModel

        readonly final property string search: root.search.text.split(" ").slice(1).join(" ")

        // waku: entries of an earlier directory scan are destroyed, so drop the nulls.
        values: WallpaperService.query(search).filter(w => w)
        onValuesChanged: root.currentIndex = search ? 0 : values.findIndex(w => w.path === WallpaperService.actualCurrent)
    }

    Component.onCompleted: currentIndex = WallpaperService.list.findIndex(w => w?.path === WallpaperService.actualCurrent)
    Component.onDestruction: WallpaperService.stopPreview()

    onCurrentItemChanged: {
        const path = currentItem?.modelData?.path;
        if (path)
            WallpaperService.preview(path);
    }

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
