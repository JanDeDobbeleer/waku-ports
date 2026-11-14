pragma ComponentBehavior: Bound

import QtQuick 6.10
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Commons
import qs.Widgets
import "./LauncherDelegateUtils.js" as LauncherDelegateUtils

NBox {
  id: entry

  required property var modelData
  required property int index
  required property var launcher

  property bool isSelected: (!LauncherDelegateUtils.field(launcher, "ignoreMouseHover") && mouseArea.containsMouse) || (index === LauncherDelegateUtils.field(launcher, "selectedIndex"))

  width: ListView.view.width
  implicitHeight: LauncherDelegateUtils.field(launcher, "entryHeight")
  clip: true
  color: entry.isSelected ? Color.mHover : Color.mSurfaceVariant
  forceOpaque: entry.isSelected

  // Prepare item when it becomes visible (e.g., decode images)
  Component.onCompleted: LauncherDelegateUtils.prepareItem(modelData)

  Behavior on color {
    ColorAnimation {
      duration: Style.animationFast
      easing.type: Easing.OutCirc
    }
  }

  ColumnLayout {
    id: contentLayout
    anchors.fill: parent
    anchors.margins: LauncherDelegateUtils.field(entry.launcher, "isCompactDensity") ? Style.marginXS : Style.marginM
    spacing: LauncherDelegateUtils.field(entry.launcher, "isCompactDensity") ? Style.marginXS : Style.marginM

    // Top row - Main entry content with action buttons
    RowLayout {
      Layout.fillWidth: true
      spacing: LauncherDelegateUtils.field(entry.launcher, "isCompactDensity") ? Style.marginS : Style.marginM

      // Icon badge or Image preview or Emoji
      Item {
        visible: !LauncherDelegateUtils.field(entry.modelData, "hideIcon")
        Layout.preferredWidth: LauncherDelegateUtils.field(entry.modelData, "hideIcon") ? 0 : LauncherDelegateUtils.field(entry.launcher, "badgeSize")
        Layout.preferredHeight: LauncherDelegateUtils.field(entry.modelData, "hideIcon") ? 0 : LauncherDelegateUtils.field(entry.launcher, "badgeSize")

        // Icon background
        Rectangle {
          anchors.fill: parent
          radius: Style.radiusXS
          color: Color.mSurface
          visible: Settings.data.appLauncher.showIconBackground && !LauncherDelegateUtils.field(entry.modelData, "isImage")
        }

        // Image preview - uses provider's getImageUrl if available
        NImageRounded {
          id: imagePreview
          anchors.fill: parent
          visible: !!LauncherDelegateUtils.field(entry.modelData, "isImage") && !LauncherDelegateUtils.field(entry.modelData, "displayString")
          radius: Style.radiusXS
          borderColor: Color.mOnSurface
          borderWidth: Style.borderM
          imageFillMode: Image.PreserveAspectCrop

          // Use provider's image revision for reactive updates
          readonly property int _rev: LauncherDelegateUtils.imageRevision(entry.modelData)

          // Get image URL from provider
          imagePath: LauncherDelegateUtils.imageUrl(entry.modelData, _rev)

          Rectangle {
            anchors.fill: parent
            visible: imagePreview.status === Image.Loading
            color: Color.mSurfaceVariant

            BusyIndicator {
              anchors.centerIn: parent
              running: true
              width: Style.baseWidgetSize * 0.5
              height: width
            }
          }

          onStatusChanged: {
            if (imagePreview.status === Image.Error) {
              iconLoader.visible = true;
              imagePreview.visible = false;
            }
          }
        }

        // Color swatch - shown for clipboard color entries
        Rectangle {
          anchors.fill: parent
          radius: Style.radiusXS
          color: LauncherDelegateUtils.field(entry.modelData, "colorHex") || "transparent"
          visible: !!LauncherDelegateUtils.field(entry.modelData, "colorHex")
          border.color: Color.mOnSurface
          border.width: Style.borderM
        }

        Loader {
          id: iconLoader
          anchors.fill: parent
          anchors.margins: Style.marginXS

          visible: (!LauncherDelegateUtils.field(entry.modelData, "isImage") && !LauncherDelegateUtils.field(entry.modelData, "displayString") && !LauncherDelegateUtils.field(entry.modelData, "colorHex")) || (!!LauncherDelegateUtils.field(entry.modelData, "isImage") && imagePreview.status === Image.Error)
          active: visible

          sourceComponent: Component {
            Loader {
              anchors.fill: parent
              sourceComponent: Settings.data.appLauncher.iconMode === "tabler" && LauncherDelegateUtils.field(entry.modelData, "isTablerIcon") ? tablerIconComponent : systemIconComponent
            }
          }

          Component {
            id: tablerIconComponent
            NIcon {
              icon: LauncherDelegateUtils.field(entry.modelData, "icon")
              pointSize: Style.fontSizeXXXL
              visible: LauncherDelegateUtils.field(entry.modelData, "icon") && !LauncherDelegateUtils.field(entry.modelData, "displayString")
              color: (entry.isSelected && !Settings.data.appLauncher.showIconBackground) ? Color.mOnHover : Color.mOnSurface
            }
          }

          Component {
            id: systemIconComponent
            IconImage {
              anchors.fill: parent
              source: LauncherDelegateUtils.field(entry.modelData, "icon") ? ThemeIcons.iconFromName(LauncherDelegateUtils.field(entry.modelData, "icon"), "application-x-executable") : ""
              visible: LauncherDelegateUtils.field(entry.modelData, "icon") && source !== "" && !LauncherDelegateUtils.field(entry.modelData, "displayString")
              asynchronous: true
            }
          }
        }

        // String display - takes precedence when displayString is present
        NText {
          id: stringDisplay
          anchors.centerIn: parent
          visible: !!LauncherDelegateUtils.field(entry.modelData, "displayString") || (!imagePreview.visible && !iconLoader.visible)
          text: LauncherDelegateUtils.field(entry.modelData, "displayString") ? LauncherDelegateUtils.field(entry.modelData, "displayString") : (LauncherDelegateUtils.field(entry.modelData, "name") ? LauncherDelegateUtils.firstLetter(LauncherDelegateUtils.field(entry.modelData, "name")) : "?")
          pointSize: LauncherDelegateUtils.field(entry.modelData, "displayString") ? (LauncherDelegateUtils.field(entry.modelData, "displayStringSize") || Style.fontSizeXXXL) : Style.fontSizeXXL
          font.weight: Style.fontWeightBold
          color: LauncherDelegateUtils.field(entry.modelData, "displayString") ? Color.mOnSurface : Color.mOnPrimary
        }

        // Image type indicator overlay
        Rectangle {
          visible: !!LauncherDelegateUtils.field(entry.modelData, "isImage") && imagePreview.visible
          anchors.bottom: parent.bottom
          anchors.right: parent.right
          anchors.margins: 2
          width: formatLabel.width + Style.marginXS
          height: formatLabel.height + Style.marginXXS
          color: Color.mSurfaceVariant
          radius: Style.radiusXXS
          NText {
            id: formatLabel
            anchors.centerIn: parent
            text: {
              if (!LauncherDelegateUtils.field(entry.modelData, "isImage"))
                return "";
              const desc = LauncherDelegateUtils.field(entry.modelData, "description") || "";
              const parts = desc.split(" \u2022 ");
              return parts[0] || "IMG";
            }
            pointSize: Style.fontSizeXXS
            color: Color.mOnSurfaceVariant
          }
        }

        // Badge icon overlay (generic indicator for any provider)
        Rectangle {
          visible: !!LauncherDelegateUtils.field(entry.modelData, "badgeIcon")
          anchors.bottom: parent.bottom
          anchors.right: parent.right
          anchors.margins: 2
          width: height
          height: Style.fontSizeM + Style.marginXS
          color: Color.mSurfaceVariant
          radius: Style.radiusXXS
          NIcon {
            anchors.centerIn: parent
            icon: LauncherDelegateUtils.field(entry.modelData, "badgeIcon") || ""
            pointSize: Style.fontSizeS
            color: Color.mOnSurfaceVariant
          }
        }
      }

      // Text content
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        NText {
          text: LauncherDelegateUtils.field(entry.modelData, "name") || "Unknown"
          pointSize: Style.fontSizeL
          font.weight: Style.fontWeightBold
          color: entry.isSelected ? Color.mOnHover : Color.mOnSurface
          elide: Text.ElideRight
          maximumLineCount: 1
          wrapMode: Text.Wrap
          clip: true
          Layout.fillWidth: true
        }

        NText {
          text: LauncherDelegateUtils.field(entry.modelData, "description") || ""
          pointSize: Style.fontSizeS
          color: entry.isSelected ? Color.mOnHover : Color.mOnSurfaceVariant
          elide: Text.ElideRight
          maximumLineCount: 1
          Layout.fillWidth: true
          visible: text !== "" && !LauncherDelegateUtils.field(entry.launcher, "isCompactDensity")
        }
      }

      // Action buttons row - dynamically populated from provider
      RowLayout {
        id: contentActions
        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
        spacing: Style.marginXS
        visible: entry.isSelected && LauncherDelegateUtils.arrayLength(itemActions) > 0

        property var itemActions: {
          return entry.isSelected ? LauncherDelegateUtils.itemActions(entry.modelData, entry.launcher) : [];
        }

        Repeater {
          model: contentActions.itemActions
          NIconButton {
            required property var modelData
            icon: LauncherDelegateUtils.field(modelData, "icon")
            baseSize: Style.baseWidgetSize * 0.75
            z: 1
            handleWheel: true
            onClicked: {
              LauncherDelegateUtils.runAction(modelData)
            }
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
      if (!LauncherDelegateUtils.field(entry.launcher, "ignoreMouseHover")) {
        LauncherDelegateUtils.setField(entry.launcher, "selectedIndex", entry.index);
      }
    }
    onClicked: mouse => {
                 if (mouse.button === Qt.LeftButton) {
                   LauncherDelegateUtils.setField(entry.launcher, "selectedIndex", entry.index);
                   LauncherDelegateUtils.activate(entry.launcher);
                   mouse.accepted = true;
                 }
               }
    acceptedButtons: Qt.LeftButton
  }
}
