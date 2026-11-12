import QtQuick 6.10
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Commons
import qs.Widgets

NBox {
  id: entry

  required property var modelData
  required property int index
  required property var launcher

  property bool isSelected: (!launcher.ignoreMouseHover && mouseArea.containsMouse) || (index === launcher.selectedIndex)

  width: ListView.view.width
  implicitHeight: launcher.entryHeight
  clip: true
  color: entry.isSelected ? Color.mHover : Color.mSurfaceVariant
  forceOpaque: entry.isSelected

  // Prepare item when it becomes visible (e.g., decode images)
  Component.onCompleted: {
    var provider = modelData.provider;
    if (provider && provider.prepareItem) {
      provider.prepareItem(modelData);
    }
  }

  Behavior on color {
    ColorAnimation {
      duration: Style.animationFast
      easing.type: Easing.OutCirc
    }
  }

  ColumnLayout {
    id: contentLayout
    anchors.fill: parent
    anchors.margins: entry.launcher.isCompactDensity ? Style.marginXS : Style.marginM
    spacing: entry.launcher.isCompactDensity ? Style.marginXS : Style.marginM

    // Top row - Main entry content with action buttons
    RowLayout {
      Layout.fillWidth: true
      spacing: entry.launcher.isCompactDensity ? Style.marginS : Style.marginM

      // Icon badge or Image preview or Emoji
      Item {
        visible: !entry.modelData.hideIcon
        Layout.preferredWidth: entry.modelData.hideIcon ? 0 : entry.launcher.badgeSize
        Layout.preferredHeight: entry.modelData.hideIcon ? 0 : entry.launcher.badgeSize

        // Icon background
        Rectangle {
          anchors.fill: parent
          radius: Style.radiusXS
          color: Color.mSurface
          visible: Settings.data.appLauncher.showIconBackground && !entry.modelData.isImage
        }

        // Image preview - uses provider's getImageUrl if available
        NImageRounded {
          id: imagePreview
          anchors.fill: parent
          visible: !!entry.modelData.isImage && !entry.modelData.displayString
          radius: Style.radiusXS
          borderColor: Color.mOnSurface
          borderWidth: Style.borderM
          imageFillMode: Image.PreserveAspectCrop

          // Use provider's image revision for reactive updates
          readonly property int _rev: entry.modelData.provider && entry.modelData.provider.imageRevision ? entry.modelData.provider.imageRevision : 0

          // Get image URL from provider
          imagePath: {
            _rev;
            var provider = entry.modelData.provider;
            if (provider && provider.getImageUrl) {
              return provider.getImageUrl(entry.modelData);
            }
            return "";
          }

          Rectangle {
            anchors.fill: parent
            visible: parent.status === Image.Loading
            color: Color.mSurfaceVariant

            BusyIndicator {
              anchors.centerIn: parent
              running: true
              width: Style.baseWidgetSize * 0.5
              height: width
            }
          }

          onStatusChanged: status => {
                             if (status === Image.Error) {
                               iconLoader.visible = true;
                               imagePreview.visible = false;
                             }
                           }
        }

        // Color swatch - shown for clipboard color entries
        Rectangle {
          anchors.fill: parent
          radius: Style.radiusXS
          color: entry.modelData.colorHex || "transparent"
          visible: !!entry.modelData.colorHex
          border.color: Color.mOnSurface
          border.width: Style.borderM
        }

        Loader {
          id: iconLoader
          anchors.fill: parent
          anchors.margins: Style.marginXS

          visible: (!entry.modelData.isImage && !entry.modelData.displayString && !entry.modelData.colorHex) || (!!entry.modelData.isImage && imagePreview.status === Image.Error)
          active: visible

          sourceComponent: Component {
            Loader {
              anchors.fill: parent
              sourceComponent: Settings.data.appLauncher.iconMode === "tabler" && modelData.isTablerIcon ? tablerIconComponent : systemIconComponent
            }
          }

          Component {
            id: tablerIconComponent
            NIcon {
              icon: modelData.icon
              pointSize: Style.fontSizeXXXL
              visible: modelData.icon && !modelData.displayString
              color: (entry.isSelected && !Settings.data.appLauncher.showIconBackground) ? Color.mOnHover : Color.mOnSurface
            }
          }

          Component {
            id: systemIconComponent
            IconImage {
              anchors.fill: parent
              source: modelData.icon ? ThemeIcons.iconFromName(modelData.icon, "application-x-executable") : ""
              visible: modelData.icon && source !== "" && !modelData.displayString
              asynchronous: true
            }
          }
        }

        // String display - takes precedence when displayString is present
        NText {
          id: stringDisplay
          anchors.centerIn: parent
          visible: !!entry.modelData.displayString || (!imagePreview.visible && !iconLoader.visible)
          text: entry.modelData.displayString ? entry.modelData.displayString : (entry.modelData.name ? entry.modelData.name.charAt(0).toUpperCase() : "?")
          pointSize: entry.modelData.displayString ? (entry.modelData.displayStringSize || Style.fontSizeXXXL) : Style.fontSizeXXL
          font.weight: Style.fontWeightBold
          color: entry.modelData.displayString ? Color.mOnSurface : Color.mOnPrimary
        }

        // Image type indicator overlay
        Rectangle {
          visible: !!entry.modelData.isImage && imagePreview.visible
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
              if (!entry.modelData.isImage)
                return "";
              const desc = entry.modelData.description || "";
              const parts = desc.split(" \u2022 ");
              return parts[0] || "IMG";
            }
            pointSize: Style.fontSizeXXS
            color: Color.mOnSurfaceVariant
          }
        }

        // Badge icon overlay (generic indicator for any provider)
        Rectangle {
          visible: !!entry.modelData.badgeIcon
          anchors.bottom: parent.bottom
          anchors.right: parent.right
          anchors.margins: 2
          width: height
          height: Style.fontSizeM + Style.marginXS
          color: Color.mSurfaceVariant
          radius: Style.radiusXXS
          NIcon {
            anchors.centerIn: parent
            icon: entry.modelData.badgeIcon || ""
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
          text: entry.modelData.name || "Unknown"
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
          text: entry.modelData.description || ""
          pointSize: Style.fontSizeS
          color: entry.isSelected ? Color.mOnHover : Color.mOnSurfaceVariant
          elide: Text.ElideRight
          maximumLineCount: 1
          Layout.fillWidth: true
          visible: text !== "" && !entry.launcher.isCompactDensity
        }
      }

      // Action buttons row - dynamically populated from provider
      RowLayout {
        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
        spacing: Style.marginXS
        visible: entry.isSelected && itemActions.length > 0

        property var itemActions: {
          if (!entry.isSelected)
            return [];
          var provider = entry.modelData.provider || entry.launcher.currentProvider;
          if (provider && provider.getItemActions) {
            return provider.getItemActions(entry.modelData);
          }
          return [];
        }

        Repeater {
          model: parent.itemActions
          NIconButton {
            required property var modelData
            icon: modelData.icon
            baseSize: Style.baseWidgetSize * 0.75
            z: 1
            handleWheel: true
            onClicked: {
              if (modelData.action) {
                modelData.action();
              }
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
      if (!entry.launcher.ignoreMouseHover) {
        entry.launcher.selectedIndex = entry.index;
      }
    }
    onClicked: mouse => {
                 if (mouse.button === Qt.LeftButton) {
                   entry.launcher.selectedIndex = entry.index;
                   entry.launcher.activate();
                   mouse.accepted = true;
                 }
               }
    acceptedButtons: Qt.LeftButton
  }
}
