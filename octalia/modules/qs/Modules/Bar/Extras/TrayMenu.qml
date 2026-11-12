pragma ComponentBehavior: Bound

import QtQuick 6.10
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets
import "TrayMenuHelpers.js" as TrayMenuHelpers

PopupWindow {
  id: root

  property ShellScreen menuScreen: null

  property var trayItem: null
  property Item anchorItem: null
  property real anchorX
  property real anchorY
  property bool isSubMenu: false
  property string widgetSection: ""
  property int widgetIndex: -1

  // Derive menu from trayItem (only used for non-submenus)
  readonly property var menu: isSubMenu ? null : (trayItem ? TrayMenuHelpers.field(trayItem, "menu") : null)

  // Compute if current tray item is pinned
  readonly property bool isPinned: TrayMenuHelpers.isTrayItemPinned(trayItem, root.menuScreen?.name, widgetSection, widgetIndex, Settings)

  readonly property int menuWidth: 220

  implicitWidth: menuWidth

  // Use the content height of the Flickable for implicit height
  implicitHeight: Math.min(menuScreen?.height * 0.9, flickable.contentHeight + Style.margin2S)

  // When implicitHeight changes (menu content loads), force anchor recalculation
  onImplicitHeightChanged: {
    if (visible && anchorItem) {
      Qt.callLater(() => {
                     TrayMenuHelpers.updateAnchor(root.anchor);
                   });
    }
  }

  visible: false
  color: "transparent"
  anchor.item: anchorItem
  anchor.rect.x: {
    if (anchorItem && menuScreen) {
      let baseX = anchorX;

      // Calculate position relative to current screen
      let menuScreenX;
      if (isSubMenu && anchorItem.Window && anchorItem.Window.window) {
        const posInPopupX = TrayMenuHelpers.mappedCoordinate(anchorItem, "x");
        const parentWindow = anchorItem.Window.window;
        const windowXOnScreen = TrayMenuHelpers.strictField(parentWindow, "x") - menuScreen.x;
        menuScreenX = windowXOnScreen + posInPopupX + baseX;
      } else {
        const anchorScreenX = TrayMenuHelpers.mappedCoordinate(anchorItem, "x");
        menuScreenX = anchorScreenX + baseX;
      }

      const menuRight = menuScreenX + implicitWidth;
      const screenRight = menuScreen.width;
      const menuLeft = menuScreenX;

      // Only adjust if menu would clip off screen boundaries
      // Don't adjust if the positioning is intentional (e.g., negative offset for right bar)
      if (menuRight > screenRight && menuLeft < screenRight) {
        // Clipping on right edge - shift left
        const overflow = menuRight - screenRight;
        return baseX - overflow - Style.marginS;
      } else if (menuLeft < 0 && menuRight > 0) {
        // Clipping on left edge - shift right
        return baseX - menuLeft + Style.marginS;
      }

      return baseX;
    }
    return anchorX;
  }
  anchor.rect.y: {
    if (anchorItem && menuScreen) {
      const barPosition = Settings.getBarPositionForScreen(root.menuScreen?.name);

      let baseY = anchorY;

      // Only apply bottom bar special positioning if:
      // 1. Not a submenu
      // 2. Bar is at bottom
      // 3. anchorY is not already negative (if negative, it's pre-calculated from drawer)
      const shouldApplyBottomBarLogic = !isSubMenu && barPosition === "bottom" && anchorY >= 0;

      if (shouldApplyBottomBarLogic) {
        // For bottom bar from the bar itself, position menu above the anchor with margin
        baseY = -(implicitHeight + Style.marginS);
      } else if (barPosition === "top" && !isSubMenu && anchorY >= 0) {
        // For top bar: position menu below bar with margin
        const barHeight = Style.getBarHeightForScreen(root.menuScreen?.name);
        baseY = barHeight + Style.marginS;
      }

      // Use a robust way to get screen coordinates
      const posInWindowY = TrayMenuHelpers.mappedCoordinate(anchorItem, "y");
      const parentWindow = anchorItem.Window.window;

      // Calculate screen-relative Y of the window
      let windowYOnScreen = (parentWindow && menuScreen) ? (TrayMenuHelpers.strictField(parentWindow, "y") - menuScreen.y) : 0;

      // If window reported 0 but bar is at bottom, assume it's at screen bottom
      if (windowYOnScreen === 0 && barPosition === "bottom" && menuScreen) {
        windowYOnScreen = menuScreen.height - (parentWindow ? TrayMenuHelpers.strictField(parentWindow, "height") : Style.getBarHeightForScreen(menuScreen.name));
      }

      // Calculate the screen Y of the menu top
      // Use a small guess for height if implicitHeight is 0 to avoid covering the bar on the first frame
      const effectiveHeight = implicitHeight > 0 ? implicitHeight : 200;
      const effectiveBaseY = shouldApplyBottomBarLogic ? -(effectiveHeight + Style.marginS) : baseY;

      const menuScreenY = windowYOnScreen + posInWindowY + effectiveBaseY;
      const menuBottom = menuScreenY + (implicitHeight > 0 ? implicitHeight : effectiveHeight);
      const screenHeight = menuScreen ? menuScreen.height : 1080;

      // Adjust the final baseY (the actual value returned to anchor.rect.y)
      let finalBaseY = shouldApplyBottomBarLogic ? -(implicitHeight + Style.marginS) : baseY;

      // Adjust if menu would clip off the bottom
      if (menuBottom > screenHeight) {
        const overflow = menuBottom - screenHeight;
        finalBaseY -= (overflow + Style.marginS);
      }

      // Adjust if menu would clip off the top
      // menuScreenY < 0 means it's above the screen edge
      if (menuScreenY < 0) {
        finalBaseY -= (menuScreenY - Style.marginS);
      }

      return finalBaseY;
    }

    // Fallback if no anchor/screen
    if (isSubMenu) {
      return anchorY;
    }
    return anchorY + (Settings.getBarPositionForScreen(root.menuScreen?.name) === "bottom" ? -implicitHeight : Style.getBarHeightForScreen(root.menuScreen?.name));
  }

  function showAt(item: Item, x: real, y: real): void {
    if (!item) {
      Logger.w("TrayMenu", "anchorItem is undefined, won't show menu.");
      return;
    }

    if (!opener.children || opener.children.values.length === 0) {
      //Logger.w("TrayMenu", "Menu not ready, delaying show")
      Qt.callLater(() => showAt(item, x, y));
      return;
    }

    anchorItem = item;
    anchorX = x;
    anchorY = y;

    visible = true;
    TrayMenuHelpers.focusItem(root.contentItem);

    // Force update after showing.
    Qt.callLater(() => {
                   TrayMenuHelpers.updateAnchor(root.anchor);
                 });
  }

  function hideMenu(): void {
    visible = false;

    // Clean up all submenus recursively
    TrayMenuHelpers.closeSubMenus(columnLayout.children, null);
  }

  Item {
    anchors.fill: parent
    Keys.onEscapePressed: root.hideMenu()
  }

  QsMenuOpener {
    id: opener
    menu: root.menu
  }

  Rectangle {
    anchors.fill: parent
    color: Color.mSurface
    border.color: Color.mOutline
    border.width: Math.max(1, Style.borderS)
    radius: Style.radiusM

    // Fade-in animation
    opacity: root.visible ? 1.0 : 0.0

    Behavior on opacity {
      NumberAnimation {
        duration: Style.animationNormal
        easing.type: Easing.OutQuad
      }
    }
  }

  Flickable {
    id: flickable
    anchors.fill: parent
    anchors.margins: Style.marginS
    contentHeight: columnLayout.implicitHeight
    interactive: true

    // Fade-in animation
    opacity: root.visible ? 1.0 : 0.0

    Behavior on opacity {
      NumberAnimation {
        duration: Style.animationNormal
        easing.type: Easing.OutQuad
      }
    }

    // Use a ColumnLayout to handle menu item arrangement
    ColumnLayout {
      id: columnLayout
      width: flickable.width
      spacing: 0

      Repeater {
        model: TrayMenuHelpers.copyChildren(opener.children)

        delegate: Rectangle {
          id: entry
          required property var modelData

          Layout.preferredWidth: parent.width
          Layout.preferredHeight: {
            if (TrayMenuHelpers.field(entry.modelData, "isSeparator")) {
              return 8;
            } else {
              // Calculate based on text content
              const textHeight = text.contentHeight || (Style.fontSizeS * 1.2);
              return Math.max(28, textHeight + Style.margin2S);
            }
          }

          color: "transparent"
          property TrayMenu subMenu: null

          NDivider {
            anchors.centerIn: parent
            width: parent.width - Style.margin2M
            visible: TrayMenuHelpers.field(entry.modelData, "isSeparator") ?? false
          }

          Rectangle {
            id: innerRect
            anchors.fill: parent
            color: mouseArea.containsMouse ? Color.mHover : "transparent"
            radius: Style.radiusS
            visible: !(TrayMenuHelpers.field(entry.modelData, "isSeparator") ?? false)

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: Style.marginM
              anchors.rightMargin: Style.marginM
              spacing: Style.marginS

              // Indicator Container
              Item {
                id: indicatorContainer
                visible: (TrayMenuHelpers.field(entry.modelData, "buttonType") ?? QsMenuButtonType.None) !== QsMenuButtonType.None

                implicitWidth: Math.round(Style.baseWidgetSize * 0.5)
                implicitHeight: Math.round(Style.baseWidgetSize * 0.5)
                Layout.alignment: Qt.AlignVCenter

                // Helper properties
                readonly property int type: TrayMenuHelpers.field(entry.modelData, "buttonType") ?? QsMenuButtonType.None
                readonly property bool isRadio: type === QsMenuButtonType.RadioButton
                readonly property bool isChecked: TrayMenuHelpers.field(entry.modelData, "checkState") === Qt.Checked || (TrayMenuHelpers.field(entry.modelData, "checked") ?? false)

                // Color Logic
                readonly property color activeColor: mouseArea.containsMouse ? Color.mOnHover : Color.mPrimary
                readonly property color checkMarkColor: mouseArea.containsMouse ? Color.mHover : Color.mOnPrimary
                readonly property color borderColor: isChecked ? activeColor : (mouseArea.containsMouse ? Color.mOnHover : Color.mOnSurface)

                // Checkbox Visuals
                Rectangle {
                  visible: !indicatorContainer.isRadio
                  anchors.centerIn: parent
                  width: Math.round(Style.baseWidgetSize * 0.5)
                  height: Math.round(Style.baseWidgetSize * 0.5)
                  radius: Style.iRadiusXS
                  color: "transparent" // Transparent to match RadioButton style
                  border.color: indicatorContainer.borderColor
                  border.width: Style.borderM

                  Behavior on border.color {
                    ColorAnimation {
                      duration: Style.animationFast
                    }
                  }

                  NIcon {
                    visible: indicatorContainer.isChecked
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: -1
                    icon: "check"
                    color: indicatorContainer.activeColor
                    pointSize: Math.max(Style.fontSizeXXS, parent.width * 0.6)
                  }
                }

                // RadioButton Visuals
                Rectangle {
                  visible: indicatorContainer.isRadio
                  anchors.centerIn: parent
                  width: Style.toOdd(Style.baseWidgetSize * 0.5)
                  height: Style.toOdd(Style.baseWidgetSize * 0.5)
                  radius: width / 2
                  color: "transparent"
                  border.color: indicatorContainer.borderColor
                  border.width: Style.borderM // Slightly thicker for radio look

                  Behavior on border.color {
                    ColorAnimation {
                      duration: Style.animationFast
                    }
                  }

                  Rectangle {
                    visible: indicatorContainer.isChecked
                    anchors.centerIn: parent
                    width: Style.toOdd(parent.width * 0.5)
                    height: Style.toOdd(parent.height * 0.5)
                    radius: width / 2
                    color: indicatorContainer.activeColor

                    Behavior on color {
                      ColorAnimation {
                        duration: Style.animationFast
                      }
                    }
                  }
                }
              }

              NText {
                id: text
                Layout.fillWidth: true
                color: (TrayMenuHelpers.field(entry.modelData, "enabled") ?? true) ? (mouseArea.containsMouse ? Color.mOnHover : Color.mOnSurface) : Color.mOnSurfaceVariant
                text: TrayMenuHelpers.menuText(entry.modelData)
                pointSize: Style.fontSizeS
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
              }

              Image {
                Layout.preferredWidth: Style.marginL
                Layout.preferredHeight: Style.marginL
                source: TrayMenuHelpers.field(entry.modelData, "icon") ?? ""
                visible: (TrayMenuHelpers.field(entry.modelData, "icon") ?? "") !== ""
                fillMode: Image.PreserveAspectFit
              }

              NIcon {
                icon: TrayMenuHelpers.field(entry.modelData, "hasChildren") ? "menu" : ""
                pointSize: Style.fontSizeS
                applyUiScale: false
                verticalAlignment: Text.AlignVCenter
                visible: TrayMenuHelpers.field(entry.modelData, "hasChildren") ?? false
                color: (mouseArea.containsMouse ? Color.mOnTertiary : Color.mOnSurface)
              }
            }

            MouseArea {
              id: mouseArea
              anchors.fill: parent
              hoverEnabled: true
              enabled: (TrayMenuHelpers.field(entry.modelData, "enabled") ?? true) && !(TrayMenuHelpers.field(entry.modelData, "isSeparator") ?? false) && root.visible
              acceptedButtons: Qt.LeftButton | Qt.RightButton

              onClicked: mouse => {
                var i;
                           if (entry.modelData && !TrayMenuHelpers.field(entry.modelData, "isSeparator")) {
                             if (TrayMenuHelpers.field(entry.modelData, "hasChildren")) {
                               // Click on items with children toggles submenu
                               if (entry.subMenu) {
                                 // Close existing submenu
                                 TrayMenuHelpers.closeAndDestroyMenu(entry.subMenu);
                                 entry.subMenu = null;
                               } else {
                                 // Close any other open submenus first
                                 TrayMenuHelpers.closeSubMenus(columnLayout.children, entry);

                                 // Determine submenu opening direction
                                 let openLeft = false;
                                 const barPosition = Settings.getBarPositionForScreen(root.menuScreen?.name);
                                 const globalPos = entry.mapToItem(null, 0, 0);

                                 if (barPosition === "right") {
                                   openLeft = true;
                                 } else if (barPosition === "left") {
                                   openLeft = false;
                                 } else {
                                   openLeft = (root.widgetSection === "right");
                                 }

                                 // Open new submenu
                                 entry.subMenu = TrayMenuHelpers.createSubMenu(Qt.createComponent("TrayMenu.qml"), root, entry.modelData, root.menuScreen) as TrayMenu;

                                 if (entry.subMenu) {
                                   const overlap = 60;
                                   TrayMenuHelpers.positionSubMenu(entry.subMenu, entry, openLeft ? -overlap : overlap);
                                   // Force anchor update with new position
                                   Qt.callLater(() => {
                                                  TrayMenuHelpers.updateAnchor(TrayMenuHelpers.field(entry.subMenu, "anchor"));
                                                });
                                 }
                               }
                             } else {
                               // Click on regular items triggers them
                               entry.modelData.triggered();
                               root.hideMenu();

                               // Close the drawer if it's open
                               if (root.menuScreen) {
                                 const panel = PanelService.getPanel("trayDrawerPanel", root.menuScreen);
                                 if (PanelService.isPanelVisible(panel)) {
                                   PanelService.invokePanel(panel, "close", []);
                                 }
                               }
                             }
                           }
                         }
            }
          }

          Component.onDestruction: {
            if (subMenu) {
              TrayMenuHelpers.destroyItem(subMenu);
              subMenu = null;
            }
          }
        }
      }

      // PIN / UNPIN
      Rectangle {
        visible: {
          if (root.widgetSection === "" || root.widgetIndex < 0)
            return false;
          var widgets = Settings.getBarWidgetsForScreen(root.menuScreen?.name)[root.widgetSection];
          if (!widgets || root.widgetIndex >= widgets.length)
            return false;
          var widgetSettings = widgets[root.widgetIndex];
          if (!widgetSettings)
            return false;
          return widgetSettings.drawerEnabled ?? false;
        }
        Layout.preferredWidth: parent.width
        Layout.preferredHeight: 28
        color: pinUnpinMouseArea.containsMouse ? Qt.alpha(Color.mPrimary, 0.2) : Qt.alpha(Color.mPrimary, 0.08)
        radius: Style.radiusS
        border.color: Qt.alpha(Color.mPrimary, pinUnpinMouseArea.containsMouse ? 0.4 : 0.2)
        border.width: Style.borderS

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: Style.marginM
          anchors.rightMargin: Style.marginM
          spacing: Style.marginS

          NIcon {
            icon: root.isPinned ? "unpin" : "pin"
            pointSize: Style.fontSizeS
            applyUiScale: false
            verticalAlignment: Text.AlignVCenter
            color: Color.mPrimary
          }

          NText {
            Layout.fillWidth: true
            color: Color.mPrimary
            text: root.isPinned ? I18n.tr("panels.bar.tray-unpin-application") : I18n.tr("panels.bar.tray-pin-application")
            pointSize: Style.fontSizeS
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
          }
        }

        MouseArea {
          id: pinUnpinMouseArea
          anchors.fill: parent
          hoverEnabled: true

          onClicked: {
            if (root.isPinned) {
              root.removeFromPinned();
            } else {
              root.addToPinned();
            }
          }
        }
      }
    }
  }

  function addToPinned(): void {
    var overrideWidgets;
    if (!trayItem || widgetSection === "" || widgetIndex < 0) {
      Logger.w("TrayMenu", "Cannot pin: missing tray item or widget info");
      return;
    }
    const itemName = TrayMenuHelpers.trayItemName(trayItem);
    if (!itemName) {
      Logger.w("TrayMenu", "Cannot pin: tray item has no name");
      return;
    }
    var screenName = root.menuScreen?.name || "";
    var widgets = Settings.getBarWidgetsForScreen(screenName)[widgetSection];
    if (!widgets || widgetIndex >= widgets.length) {
      Logger.w("TrayMenu", "Cannot pin: invalid widget index");
      return;
    }
    var widgetSettings = widgets[widgetIndex];
    if (!widgetSettings || widgetSettings.id !== "Tray") {
      Logger.w("TrayMenu", "Cannot pin: widget is not a Tray widget");
      return;
    }
    var pinnedList = widgetSettings.pinned || [];
    var newPinned = pinnedList.slice();
    newPinned.push(itemName);
    var newSettings = Object.assign({}, widgetSettings);
    newSettings.pinned = newPinned;
    widgets[widgetIndex] = newSettings;

    // Write to the correct location: screen override or global
    if (Settings.hasScreenOverride(screenName, "widgets")) {
      overrideWidgets = Settings.getBarWidgetsForScreen(screenName);
      overrideWidgets[widgetSection] = widgets;
      Settings.setScreenOverride(screenName, "widgets", overrideWidgets);
    } else {
      Settings.data.bar.widgets[widgetSection] = widgets;
    }
    Settings.saveImmediate();

    // Close drawer when pinning (drawer needs to resize)
    if (root.menuScreen) {
      const panel = PanelService.getPanel("trayDrawerPanel", root.menuScreen);
      if (panel)
        panel.close();
    }
  }

  function removeFromPinned(): void {
    var overrideWidgets;
    if (!trayItem || widgetSection === "" || widgetIndex < 0) {
      Logger.w("TrayMenu", "Cannot unpin: missing tray item or widget info");
      return;
    }
    const itemName = TrayMenuHelpers.trayItemName(trayItem);
    if (!itemName) {
      Logger.w("TrayMenu", "Cannot unpin: tray item has no name");
      return;
    }
    var screenName = root.menuScreen?.name || "";
    var widgets = Settings.getBarWidgetsForScreen(screenName)[widgetSection];
    if (!widgets || widgetIndex >= widgets.length) {
      Logger.w("TrayMenu", "Cannot unpin: invalid widget index");
      return;
    }
    var widgetSettings = widgets[widgetIndex];
    if (!widgetSettings || widgetSettings.id !== "Tray") {
      Logger.w("TrayMenu", "Cannot unpin: widget is not a Tray widget");
      return;
    }
    var pinnedList = widgetSettings.pinned || [];
    var newPinned = TrayMenuHelpers.withoutItem(pinnedList, itemName);
    var newSettings = Object.assign({}, widgetSettings);
    newSettings.pinned = newPinned;
    widgets[widgetIndex] = newSettings;

    // Write to the correct location: screen override or global
    if (Settings.hasScreenOverride(screenName, "widgets")) {
      overrideWidgets = Settings.getBarWidgetsForScreen(screenName);
      overrideWidgets[widgetSection] = widgets;
      Settings.setScreenOverride(screenName, "widgets", overrideWidgets);
    } else {
      Settings.data.bar.widgets[widgetSection] = widgets;
    }
    Settings.saveImmediate();
  }
}
