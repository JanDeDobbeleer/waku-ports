pragma ComponentBehavior: Bound

import QtQuick 6.10
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Commons
import qs.Widgets
import "./LauncherDelegateUtils.js" as LauncherDelegateUtils

Item {
  id: gridEntryContainer

  required property var modelData
  required property int index
  required property var launcher

  width: LauncherDelegateUtils.gridCellWidth(GridView.view)
  height: LauncherDelegateUtils.gridCellHeight(GridView.view)

  property bool isSelected: (!LauncherDelegateUtils.field(launcher, "ignoreMouseHover") && mouseArea.containsMouse) || (index === LauncherDelegateUtils.field(launcher, "selectedIndex"))

  // Prepare item when it becomes visible (e.g., decode images)
  Component.onCompleted: LauncherDelegateUtils.prepareItem(modelData)

  NBox {
    id: gridEntry
    anchors.fill: parent
    anchors.margins: Style.marginXXS
    color: gridEntryContainer.isSelected ? Color.mHover : Color.mSurfaceVariant
    forceOpaque: gridEntryContainer.isSelected

    Behavior on color {
      ColorAnimation {
        duration: Style.animationFast
        easing.type: Easing.OutCirc
      }
    }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: LauncherDelegateUtils.field(gridEntryContainer.launcher, "isCompactDensity") ? Style.marginXS : Style.marginS
      anchors.bottomMargin: LauncherDelegateUtils.field(gridEntryContainer.launcher, "isCompactDensity") ? Style.marginXS : Style.marginS
      spacing: LauncherDelegateUtils.field(gridEntryContainer.launcher, "isCompactDensity") ? 0 : Style.marginXXS

      // Icon badge or Image preview or Emoji
      Item {
        // Size image at 65% of cell dimensions.
        Layout.preferredWidth: Math.round(gridEntry.width * 0.65)
        Layout.preferredHeight: Math.round(gridEntry.height * 0.65)
        Layout.alignment: Qt.AlignHCenter

        // Icon background
        Rectangle {
          anchors.fill: parent
          radius: Style.radiusM
          color: Color.mSurface
          visible: Settings.data.appLauncher.showIconBackground && !LauncherDelegateUtils.field(gridEntryContainer.modelData, "isImage")
        }

        // Image preview - uses provider's getImageUrl if available
        NImageRounded {
          id: gridImagePreview
          anchors.fill: parent
          visible: !!LauncherDelegateUtils.field(gridEntryContainer.modelData, "isImage") && !LauncherDelegateUtils.field(gridEntryContainer.modelData, "displayString")
          radius: Style.radiusM

          // Use provider's image revision for reactive updates
          readonly property int _rev: LauncherDelegateUtils.imageRevision(gridEntryContainer.modelData)

          // Get image URL from provider
          imagePath: LauncherDelegateUtils.imageUrl(gridEntryContainer.modelData, _rev)

          Rectangle {
            anchors.fill: parent
            visible: gridImagePreview.status === Image.Loading
            color: Color.mSurfaceVariant

            BusyIndicator {
              anchors.centerIn: parent
              running: true
              width: Style.baseWidgetSize * 0.5
              height: width
            }
          }

          onStatusChanged: {
            if (gridImagePreview.status === Image.Error) {
              gridIconLoader.visible = true;
              gridImagePreview.visible = false;
            }
          }
        }

        Loader {
          id: gridIconLoader
          anchors.fill: parent
          anchors.margins: Style.marginXS

          visible: (!LauncherDelegateUtils.field(gridEntryContainer.modelData, "isImage") && !LauncherDelegateUtils.field(gridEntryContainer.modelData, "displayString")) || (!!LauncherDelegateUtils.field(gridEntryContainer.modelData, "isImage") && gridImagePreview.status === Image.Error)
          active: visible

          sourceComponent: Settings.data.appLauncher.iconMode === "tabler" && LauncherDelegateUtils.field(gridEntryContainer.modelData, "isTablerIcon") ? gridTablerIconComponent : gridSystemIconComponent

          Component {
            id: gridTablerIconComponent
            NIcon {
              icon: LauncherDelegateUtils.field(gridEntryContainer.modelData, "icon")
              pointSize: Style.fontSizeXXXL
              visible: LauncherDelegateUtils.field(gridEntryContainer.modelData, "icon") && !LauncherDelegateUtils.field(gridEntryContainer.modelData, "displayString")
              color: (gridEntryContainer.isSelected && !Settings.data.appLauncher.showIconBackground) ? Color.mOnHover : Color.mOnSurface
            }
          }

          Component {
            id: gridSystemIconComponent
            IconImage {
              anchors.fill: parent
              source: LauncherDelegateUtils.field(gridEntryContainer.modelData, "icon") ? ThemeIcons.iconFromName(LauncherDelegateUtils.field(gridEntryContainer.modelData, "icon"), "application-x-executable") : ""
              visible: LauncherDelegateUtils.field(gridEntryContainer.modelData, "icon") && source !== "" && !LauncherDelegateUtils.field(gridEntryContainer.modelData, "displayString")
              asynchronous: true
            }
          }
        }

        // String display
        NText {
          id: gridStringDisplay
          anchors.centerIn: parent
          visible: !!LauncherDelegateUtils.field(gridEntryContainer.modelData, "displayString") || (!gridImagePreview.visible && !gridIconLoader.visible)
          text: LauncherDelegateUtils.field(gridEntryContainer.modelData, "displayString") ? LauncherDelegateUtils.field(gridEntryContainer.modelData, "displayString") : (LauncherDelegateUtils.field(gridEntryContainer.modelData, "name") ? LauncherDelegateUtils.firstLetter(LauncherDelegateUtils.field(gridEntryContainer.modelData, "name")) : "?")
          pointSize: {
            if (LauncherDelegateUtils.field(gridEntryContainer.modelData, "displayString")) {
              // Use custom size if provided, otherwise default scaling
              if (LauncherDelegateUtils.field(gridEntryContainer.modelData, "displayStringSize")) {
                return LauncherDelegateUtils.field(gridEntryContainer.modelData, "displayStringSize") * Style.uiScaleRatio;
              }
              if (LauncherDelegateUtils.field(gridEntryContainer.launcher, "providerHasDisplayString")) {
                // Scale with cell width but cap at reasonable maximum
                const cellBasedSize = gridEntry.width * 0.4;
                const maxSize = Style.fontSizeXXXL * Style.uiScaleRatio;
                return Math.min(cellBasedSize, maxSize);
              }
              return Style.fontSizeXXL * 2 * Style.uiScaleRatio;
            }
            // Scale font size relative to cell width for low res, but cap at maximum
            const cellBasedSize = gridEntry.width * 0.25;
            const baseSize = Style.fontSizeXL * Style.uiScaleRatio;
            const maxSize = Style.fontSizeXXL * Style.uiScaleRatio;
            return Math.min(Math.max(cellBasedSize, baseSize), maxSize);
          }
          font.weight: Style.fontWeightBold
          color: LauncherDelegateUtils.field(gridEntryContainer.modelData, "displayString") ? Color.mOnSurface : Color.mOnPrimary
        }

        // Badge icon overlay (generic indicator for any provider)
        Rectangle {
          visible: !!LauncherDelegateUtils.field(gridEntryContainer.modelData, "badgeIcon")
          anchors.bottom: parent.bottom
          anchors.right: parent.right
          anchors.margins: 2
          width: height
          height: Style.fontSizeM + Style.marginXS
          color: Color.mSurfaceVariant
          radius: Style.radiusXXS
          NIcon {
            anchors.centerIn: parent
            icon: LauncherDelegateUtils.field(gridEntryContainer.modelData, "badgeIcon") || ""
            pointSize: Style.fontSizeS
            color: Color.mOnSurfaceVariant
          }
        }
      }

      // Text content (hidden when hideLabel is true)
      NText {
        visible: !LauncherDelegateUtils.field(gridEntryContainer.modelData, "hideLabel")
        text: LauncherDelegateUtils.field(gridEntryContainer.modelData, "name") || "Unknown"
        pointSize: {
          if (LauncherDelegateUtils.field(gridEntryContainer.launcher, "providerHasDisplayString") && LauncherDelegateUtils.field(gridEntryContainer.modelData, "displayString")) {
            return Style.fontSizeS * Style.uiScaleRatio;
          }
          // Scale font size relative to cell width for low res, but cap at maximum
          const cellBasedSize = gridEntry.width * 0.1;
          const baseSize = Style.fontSizeXS * Style.uiScaleRatio;
          const maxSize = Style.fontSizeS * Style.uiScaleRatio;
          return Math.min(Math.max(cellBasedSize, baseSize), maxSize);
        }
        font.weight: Style.fontWeightSemiBold
        color: gridEntryContainer.isSelected ? Color.mOnHover : Color.mOnSurface
        elide: Text.ElideRight
        Layout.fillWidth: true
        Layout.maximumWidth: gridEntry.width - 8
        Layout.leftMargin: (LauncherDelegateUtils.field(gridEntryContainer.launcher, "providerHasDisplayString") && LauncherDelegateUtils.field(gridEntryContainer.modelData, "displayString")) ? Style.marginS : 0
        Layout.rightMargin: (LauncherDelegateUtils.field(gridEntryContainer.launcher, "providerHasDisplayString") && LauncherDelegateUtils.field(gridEntryContainer.modelData, "displayString")) ? Style.marginS : 0
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.NoWrap
        maximumLineCount: 1
      }
    }

    // Action buttons (overlay in top-right corner) - dynamically populated from provider
    Row {
      id: gridItemActionsRow
      visible: gridEntryContainer.isSelected && LauncherDelegateUtils.arrayLength(gridItemActions) > 0
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.margins: Style.marginXS
      z: 10
      spacing: Style.marginXXS

      property var gridItemActions: {
        return gridEntryContainer.isSelected ? LauncherDelegateUtils.itemActions(gridEntryContainer.modelData, gridEntryContainer.launcher) : [];
      }

      Repeater {
        model: gridItemActionsRow.gridItemActions
        NIconButton {
          required property var modelData
          icon: LauncherDelegateUtils.field(modelData, "icon")
          baseSize: Style.baseWidgetSize * 0.75
          z: 11
          handleWheel: true
          onClicked: {
            LauncherDelegateUtils.runAction(modelData)
          }
        }
      }
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    z: -1
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    enabled: !Settings.data.appLauncher.ignoreMouseInput

    onEntered: {
      if (!LauncherDelegateUtils.field(gridEntryContainer.launcher, "ignoreMouseHover")) {
        LauncherDelegateUtils.setField(gridEntryContainer.launcher, "selectedIndex", gridEntryContainer.index);
      }
    }
    onClicked: mouse => {
                 if (mouse.button === Qt.LeftButton) {
                   LauncherDelegateUtils.setField(gridEntryContainer.launcher, "selectedIndex", gridEntryContainer.index);
                   LauncherDelegateUtils.activate(gridEntryContainer.launcher);
                   mouse.accepted = true;
                 }
               }
    acceptedButtons: Qt.LeftButton
  }
}
