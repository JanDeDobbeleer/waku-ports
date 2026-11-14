import QtQuick 6.10
import Quickshell
import Quickshell.Wayland
import qs.Services.Compositor
import qs.Services.UI
import qs.Modules.Bar.Extras
import qs.Widgets
import qs.compat
import "../Bar/Extras/TrayMenuHelpers.js" as TrayMenuHelpers

// Generic full-screen popup window for menus and context menus
// This is a top-level PanelWindow (sibling to MainScreen, not nested inside it)
// Provides click-outside-to-close functionality for any popup content
// Loads TrayMenu by default but can show context menus via showContextMenu()
PanelWindow {
  id: root

  property string windowType: "popupmenu"  // Used for namespace and registration

  // Content item to display (set by the popup that uses this window)
  property var popupItem: null

  // Expose the trayMenu Loader directly (for backward compatibility)
  readonly property alias trayMenuLoader: defaultTrayMenuLoader

  // Dynamic context menu callback for items in other windows (e.g., desktop widgets)
  property var dynamicMenuCallback: null

  anchors.top: true
  anchors.left: true
  anchors.right: true
  anchors.bottom: true
  visible: false
  color: "transparent"

  // Use Top layer for proper event handling, but on labwc use Bottom
  // to avoid stealing input from popups while still catching outside clicks.
  // However, when a dialog is open, always use Top so dialogs appear above apps.
  WlrLayershell.layer: (CompositorService.isLabwc && !hasDialog) ? WlrLayer.Bottom : WlrLayer.Top
  WlrLayershell.keyboardFocus: hasDialog ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
  WlrLayershell.namespace: "octalia-" + windowType + "-" + (screen?.name || "unknown")
  WlrLayershell.exclusionMode: ExclusionMode.Ignore

  // Track if a dialog is currently open (needed for keyboard focus)
  property bool hasDialog: false

  // Register with PanelService so widgets can find this window
  Component.onCompleted: {
    objectName = "popupMenuWindow-" + (screen?.name || "unknown");
    PanelService.registerPopupMenuWindow(screen, root);
  }

  Component.onDestruction: {
    PanelService.unregisterPopupMenuWindow(screen);
  }

  // Load TrayMenu as the default content
  Loader {
    id: defaultTrayMenuLoader
    source: ShellUrl.dir + "/modules/qs/Modules/Bar/Extras/TrayMenu.qml"
    onLoaded: {
      if (item) {
        const trayMenu = item as TrayMenu;
        TrayMenuHelpers.setMenuScreen(trayMenu, root.screen);
        // Set the loaded item as default content
        root.popupItem = trayMenu;
      }
    }
  }

  // Dynamic context menu - created as child of this window (Top layer) so input works correctly
  // Used for items in other windows like desktop widgets (bottom layer)
  NPopupContextMenu {
    id: dynamicMenu
    visible: false
    targetScreen: root.screen
    minWidth: 180

    onTriggered: (action, item) => {
      var handled;
                   if (root.dynamicMenuCallback) {
                     // Callback returns true if it will handle closing (e.g., opening a dialog)
                     handled = TrayMenuHelpers.callDynamicMenuCallback(root, action);
                     if (!handled) {
                       root.close();
                     }
                   } else {
                     root.close();
                   }
                 }
  }

  function open() {
    visible = true;
    BarService.popupOpen = true;
  }

  // Show a context menu (temporarily replaces TrayMenu as content)
  function showContextMenu(menu: var): void {
    if (menu) {
      popupItem = menu;
      open();
    }
  }

  // Show a dynamic context menu with model and callback at screen coordinates
  // Used for items in other window layers (e.g., desktop widgets in bottom layer)
  function showDynamicContextMenu(model: var, screenX: real, screenY: real, callback: var): void {
    dynamicMenu.model = model;
    dynamicMenuCallback = callback;

    // Use the anchor point item for positioning at absolute coordinates
    dynamicMenu.anchorItem = anchorPoint;
    anchorPoint.x = screenX;
    anchorPoint.y = screenY;

    popupItem = dynamicMenu;
    dynamicMenu.visible = true;
    open();
  }

  // Invisible anchor point for dynamic menu positioning
  Item {
    id: anchorPoint
    width: 1
    height: 1
  }

  // Hide just the dynamic menu without closing the popup window
  // Used when transitioning from context menu to a dialog
  function hideDynamicMenu() {
    dynamicMenu.visible = false;
  }

  function close() {
    visible = false;
    BarService.popupOpen = false;
    // Call close/hide method on current content
    if (popupItem)
      TrayMenuHelpers.closePopupItem(popupItem);
    // Hide dynamic menu
    dynamicMenu.visible = false;
    dynamicMenuCallback = null;
    // Restore TrayMenu as default content
    if (TrayMenuHelpers.strictField(trayMenuLoader, "item")) {
      popupItem = TrayMenuHelpers.strictField(trayMenuLoader, "item");
    }
  }

  // Full-screen click catcher - click anywhere outside content closes the window
  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    onClicked: root.close()
  }

  // Container for dialogs that need a full-screen Item parent (e.g., Qt Popup)
  Item {
    id: dialogContainer
    anchors.fill: parent
  }

  // Expose the dialog container for external use
  readonly property alias dialogParent: dialogContainer
}
