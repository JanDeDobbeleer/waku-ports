pragma ComponentBehavior: Bound

import QtQuick 6.10

import qs.Commons
import qs.Modules.MainScreen
import qs.Widgets
import "LauncherUtils.js" as LauncherUtils

SmartPanel {
  id: root

  // Disable when overlay mode is enabled (LauncherOverlayWindow handles it)
  enabled: !Settings.data.appLauncher.overviewLayer
  visible: !Settings.data.appLauncher.overviewLayer

  // Reference to core (set after panelContent loads)
  property LauncherCore launcherCoreRef

  // Expose core launcher for external access (e.g., IPC)
  readonly property string searchText: launcherCoreRef ? LauncherUtils.field(launcherCoreRef, "searchText") : ""
  readonly property int selectedIndex: launcherCoreRef ? LauncherUtils.field(launcherCoreRef, "selectedIndex") : 0
  readonly property var results: launcherCoreRef ? LauncherUtils.field(launcherCoreRef, "results") : []
  readonly property var activeProvider: launcherCoreRef ? LauncherUtils.field(launcherCoreRef, "activeProvider") : null
  readonly property var currentProvider: launcherCoreRef ? LauncherUtils.field(launcherCoreRef, "currentProvider") : null
  readonly property bool isGridView: launcherCoreRef ? LauncherUtils.field(launcherCoreRef, "isGridView") : false
  readonly property int gridColumns: launcherCoreRef ? LauncherUtils.field(launcherCoreRef, "gridColumns") : 5

  function setSearchText(text: string): void {
    if (launcherCoreRef)
      LauncherUtils.setSearchText(launcherCoreRef, text);
  }

  // Preview panel support
  readonly property bool previewActive: {
    if (!launcherCoreRef)
      return false;
    var provider = root.activeProvider;
    if (!provider || !LauncherUtils.field(provider, "hasPreview"))
      return false;
    if (!Settings.data.appLauncher.enableClipPreview)
      return false;
    return selectedIndex >= 0 && results && !!results[selectedIndex];
  }
  readonly property int previewPanelWidth: Math.round(400 * Style.uiScaleRatio)

  // Panel sizing
  readonly property int listPanelWidth: Math.round(500 * Style.uiScaleRatio)
  readonly property int totalBaseWidth: listPanelWidth + Style.margin2L

  preferredWidth: totalBaseWidth
  preferredHeight: Math.round(600 * Style.uiScaleRatio)
  preferredWidthRatio: 0.25
  preferredHeightRatio: 0.5

  // Positioning
  readonly property string screenBarPosition: Settings.getBarPositionForScreen(screen?.name)
  readonly property string panelPosition: {
    if (Settings.data.appLauncher.position === "follow_bar") {
      if (screenBarPosition === "left" || screenBarPosition === "right") {
        return `center_${screenBarPosition}`;
      } else {
        return `${screenBarPosition}_center`;
      }
    } else {
      return Settings.data.appLauncher.position;
    }
  }
  panelAnchorHorizontalCenter: !root.useButtonPosition && (panelPosition === "center" || panelPosition.endsWith("_center"))
  panelAnchorVerticalCenter: !root.useButtonPosition && panelPosition === "center"
  panelAnchorLeft: !root.useButtonPosition && panelPosition !== "center" && panelPosition.endsWith("_left")
  panelAnchorRight: !root.useButtonPosition && panelPosition !== "center" && panelPosition.endsWith("_right")
  panelAnchorBottom: !root.useButtonPosition && panelPosition.startsWith("bottom_")
  panelAnchorTop: !root.useButtonPosition && panelPosition.startsWith("top_")

  panelContent: Rectangle {
    id: ui
    color: "transparent"
    opacity: launcherCore.resultsReady ? 1.0 : 0.0

    Component.onCompleted: root.launcherCoreRef = launcherCore

    Behavior on opacity {
      NumberAnimation {
        duration: Style.animationFast
        easing.type: Easing.OutCirc
      }
    }

    // Preview Panel (external) - uses provider's preview component
    NDropShadow {
      source: previewBox
      anchors.fill: previewBox
      autoPaddingEnabled: true
      visible: previewBox.visible
      z: previewBox.z - 1
    }

    NBox {
      id: previewBox
      visible: root.previewActive
      width: root.previewPanelWidth
      height: Math.round(400 * Style.uiScaleRatio)
      forceOpaque: true // no blur for now
      x: root.panelAnchorRight ? -(root.previewPanelWidth + Style.marginM) : ui.width + Style.marginM
      y: {
        var view = launcherCore.resultsView;
        if (!view)
          return Style.marginL;
        var row = launcherCore.isGridView ? Math.floor(launcherCore.selectedIndex / launcherCore.gridColumns) : launcherCore.selectedIndex;
        var gridCellSize = Math.floor((root.listPanelWidth - Style.margin2XS - ((launcherCore.targetGridColumns - 1) * Style.marginS)) / launcherCore.targetGridColumns);
        var itemHeight = launcherCore.isGridView ? (gridCellSize + Style.marginXXS) : (launcherCore.entryHeight + (LauncherUtils.field(view, "spacing") || 0));
        var yPos = row * itemHeight - (LauncherUtils.field(view, "contentY") || 0);
        var mapped = view.mapToItem(ui, 0, yPos);
        return Math.max(Style.marginL, Math.min(mapped.y, ui.height - previewBox.height - Style.marginL));
      }
      z: -1

      opacity: visible ? 1.0 : 0.0
      Behavior on opacity {
        NumberAnimation {
          duration: Style.animationFast
        }
      }
      Behavior on y {
        NumberAnimation {
          duration: Style.animationFast
          easing.type: Easing.OutCubic
        }
      }

      Loader {
        id: previewLoader
        anchors.fill: parent
        active: root.previewActive
        source: {
          if (!active)
            return "";
          var provider = launcherCore.activeProvider;
          if (provider && LauncherUtils.field(provider, "previewComponentPath"))
            return LauncherUtils.field(provider, "previewComponentPath");
          return "";
        }

        onLoaded: updatePreviewItem()
        onItemChanged: updatePreviewItem()

        function updatePreviewItem() {
          if (!item || launcherCore.selectedIndex < 0 || !launcherCore.results[launcherCore.selectedIndex])
            return;
          var provider = launcherCore.activeProvider;
          var previewData = launcherCore.results[launcherCore.selectedIndex];
          if (provider && LauncherUtils.field(provider, "getPreviewData"))
            previewData = LauncherUtils.previewData(provider, previewData);
          LauncherUtils.setCurrentItem(item, previewData);
        }
      }
    }

    // Core launcher (state, providers, UI)
    LauncherCore {
      id: launcherCore
      anchors.fill: parent
      screen: root.screen
      isOpen: root.isPanelOpen
      onRequestClose: root.close()
      // Defer so the signal emission completes before SmartPanel
      // sets isPanelOpen=false and the contentLoader destroys us.
      onRequestCloseImmediately: Qt.callLater(root.closeImmediately)
    }

    // Update preview when selection changes
    Connections {
      target: launcherCore
      function onSelectedIndexChanged() {
        if (previewLoader.item)
          previewLoader.updatePreviewItem();
      }
    }
  }
}
