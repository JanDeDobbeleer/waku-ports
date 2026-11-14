pragma ComponentBehavior: Bound

import "NContextMenuUtils.js" as MenuUtils

import QtQuick 6.10
import QtQuick.Controls.Basic
import QtQuick.Layouts
import qs.Commons

/*
* NContextMenu - Popup-based context menu for use inside panels and dialogs
*
* Use this component when you need a context menu inside:
* - Settings panels
* - Dialogs
* - Repeater delegates
* - Any nested component context
*
* For bar widgets and top-level window contexts, use NPopupContextMenu instead,
* which provides better screen boundary handling and compositor integration.
*
* Usage:
*   NContextMenu {
*     id: contextMenu
*     parent: Overlay.overlay
*     model: [
*       { "label": "Action 1", "action": "action1", "icon": "icon-name" },
*       { "label": "Action 2", "action": "action2" }
*     ]
*     onTriggered: action => { Logger.i("MyModule", "Selected:", action) }
*   }
*
*   MouseArea {
*     onClicked: contextMenu.openAtItem(parent, mouse.x, mouse.y)
*   }
*/
Popup {
  id: root

  property var model: []
  property real itemHeight: 36
  property real itemPadding: Style.marginM
  property int verticalPolicy: ScrollBar.AsNeeded
  property int horizontalPolicy: ScrollBar.AsNeeded
  // Optional: explicit item whose bounds the menu must stay within.
  // When unset, openAtItem auto-detects the nearest clipping ancestor.
  property Item constrainTo: null
  property Item _detectedConstraint: null

  signal triggered(string action)

  // Filter out hidden items to avoid spacing artifacts from zero-height items
  readonly property var filteredModel: MenuUtils.filteredModel(model)

  width: 180
  padding: Style.marginS

  background: Rectangle {
    color: Color.mSurfaceVariant
    border.color: Color.mOutline
    border.width: Style.borderS
    radius: Style.iRadiusM
  }

  contentItem: NListView {
    id: listView
    implicitHeight: Math.max(contentHeight, root.itemHeight)
    spacing: Style.marginXXS
    interactive: contentHeight > root.height
    verticalPolicy: root.verticalPolicy
    horizontalPolicy: root.horizontalPolicy
    reserveScrollbarSpace: false
    model: root.filteredModel

    delegate: ItemDelegate {
      id: menuItem
      required property var modelData
      required property int index
      width: listView.availableWidth
      height: root.itemHeight
      opacity: MenuUtils.field(menuItem.modelData, "enabled") !== false ? 1.0 : 0.5
      enabled: MenuUtils.field(menuItem.modelData, "enabled") !== false

      // Store reference to the popup
      property var popup: root

      background: Rectangle {
        color: menuItem.hovered && menuItem.enabled ? Color.mHover : "transparent"
        radius: Style.iRadiusS

        Behavior on color {
          ColorAnimation {
            duration: Style.animationFast
          }
        }
      }

      contentItem: RowLayout {
        spacing: Style.marginS

        // Optional icon
        NIcon {
          visible: MenuUtils.field(menuItem.modelData, "icon") !== undefined
          icon: MenuUtils.field(menuItem.modelData, "icon") || ""
          pointSize: Style.fontSizeM
          color: menuItem.hovered && menuItem.enabled ? Color.mOnHover : Color.mOnSurface
          Layout.leftMargin: root.itemPadding

          Behavior on color {
            ColorAnimation {
              duration: Style.animationFast
            }
          }
        }

        NText {
          text: MenuUtils.label(menuItem.modelData)
          pointSize: Style.fontSizeM
          color: menuItem.hovered && menuItem.enabled ? Color.mOnHover : Color.mOnSurface
          verticalAlignment: Text.AlignVCenter
          Layout.fillWidth: true
          Layout.leftMargin: MenuUtils.field(menuItem.modelData, "icon") === undefined ? root.itemPadding : 0

          Behavior on color {
            ColorAnimation {
              duration: Style.animationFast
            }
          }
        }
      }

      onClicked: {
        if (enabled) {
          popup.triggered(MenuUtils.action(menuItem.modelData, menuItem.index));
          popup.close();
        }
      }
    }
  }

  // Helper function to open at mouse position
  function openAt(x: var, y: var): void {
    MenuUtils.openAt(x, y, root, listView.spacing);
  }

  // Helper function to open at item
  function openAtItem(item: var, mouseX: var, mouseY: var): void {
    MenuUtils.openAtItem(item, mouseX, mouseY, root);
  }
}
