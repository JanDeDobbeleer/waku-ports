pragma ComponentBehavior: Bound

import "NReorderCheckboxesUtils.js" as ReorderUtils

import QtQuick 6.10
import QtQuick.Layouts
import qs.Commons

Item {
  id: root

  // Public API
  property var model: []
  property var disabledIds: []
  property color activeColor: Color.mPrimary
  property color activeOnColor: Color.mOnPrimary
  property color dragHandleColor: Color.mOutline
  property int baseSize: Style.baseWidgetSize * 0.7
  property int spacing: Style.marginM
  property int dragStartIndex: -1
  property int dragTargetIndex: -1

  signal itemToggled(int index, bool enabled)
  signal itemsReordered(int fromIndex, int toIndex)
  signal dragPotentialStarted
  signal dragPotentialEnded

  readonly property real itemHeight: root.baseSize
  readonly property real contentHeight: ReorderUtils.length(root.model) > 0 ? ReorderUtils.length(root.model) * itemHeight + (ReorderUtils.length(root.model) - 1) * root.spacing : 0
  implicitHeight: contentHeight

  function toggleItem(index: var): void {
    ReorderUtils.toggleItem(root, index);
  }

  function moveItem(fromIndex: var, toIndex: var): void {
    ReorderUtils.moveItem(root, fromIndex, toIndex);
  }

  Item {
    id: itemsContainer
    anchors.fill: parent
    clip: true

    Repeater {
      id: repeater
      model: root.model

      delegate: Item {
        id: delegateItem

        width: itemsContainer.width
        height: checkboxRow.height

        required property int index
        required property var modelData

        property string text: ReorderUtils.field(delegateItem.modelData, "text") || ""
        property bool itemEnabled: ReorderUtils.field(delegateItem.modelData, "enabled") || false
        property bool required: ReorderUtils.field(delegateItem.modelData, "required") || false
        readonly property bool isDisabled: (root.disabledIds || []).indexOf(ReorderUtils.field(delegateItem.modelData, "id")) !== -1
        readonly property bool canDrag: !delegateItem.isDisabled
        property bool dragging: false
        property int dragStartY: 0
        property int itemSpacing: root.spacing

        RowLayout {
          id: checkboxRow

          width: parent.width
          spacing: Style.marginS
          opacity: delegateItem.isDisabled ? 0.5 : 1.0

          // Drag handle
          Rectangle {
            id: dragHandle

            Layout.preferredWidth: root.baseSize
            Layout.preferredHeight: root.baseSize
            radius: Style.iRadiusXS
            color: dragHandleMouseArea.containsMouse ? Color.mSurfaceVariant : "transparent"

            Behavior on color {
              ColorAnimation {
                duration: Style.animationFast
              }
            }

            ColumnLayout {
              anchors.centerIn: parent
              spacing: Style.marginS

              Repeater {
                model: 3
                Rectangle {
                  Layout.preferredWidth: root.baseSize * 0.4
                  Layout.preferredHeight: 2
                  radius: 1
                  color: root.dragHandleColor
                }
              }
            }

            MouseArea {
              id: dragHandleMouseArea

              anchors.fill: parent
              cursorShape: delegateItem.canDrag ? Qt.SizeVerCursor : Qt.ArrowCursor
              hoverEnabled: true
              preventStealing: false
              enabled: delegateItem.canDrag
              z: 1000

              onPressed: mouse => {
                           if (!delegateItem.canDrag) {
                             return;
                           }
                           root.dragStartIndex = delegateItem.index;
                           root.dragTargetIndex = delegateItem.index;
                           delegateItem.dragStartY = delegateItem.y;
                           delegateItem.dragging = true;
                           delegateItem.z = 999;

                           // Signal that interaction started (prevents panel close)
                           preventStealing = true;
                           root.dragPotentialStarted();
                         }

              onPositionChanged: mouse => {
                var dy, newY, targetIndex;
                                   if (delegateItem.dragging) {
                                     dy = mouse.y - dragHandle.height / 2;
                                     newY = delegateItem.y + dy;

                                     // Constrain within bounds
                                     newY = Math.max(0, Math.min(newY, root.contentHeight - delegateItem.height));
                                     delegateItem.y = newY;

                                     // Calculate target index (but don't apply yet)
                                     targetIndex = Math.floor((newY + delegateItem.height / 2) / (delegateItem.height + delegateItem.itemSpacing));
                                     targetIndex = Math.max(0, Math.min(targetIndex, repeater.count - 1));

                                     root.dragTargetIndex = targetIndex;
                                   }
                                 }

              onReleased: {
                // Always signal end of interaction
                preventStealing = false;
                root.dragPotentialEnded();

                // Apply the model change now that drag is complete
                if (root.dragStartIndex !== -1 && root.dragTargetIndex !== -1 && root.dragStartIndex !== root.dragTargetIndex) {
                  root.moveItem(root.dragStartIndex, root.dragTargetIndex);
                }

                delegateItem.dragging = false;
                root.dragStartIndex = -1;
                root.dragTargetIndex = -1;
                delegateItem.z = 0;
              }

              onCanceled: {
                // Handle cancel (e.g., ESC key pressed during drag)
                preventStealing = false;
                root.dragPotentialEnded();

                delegateItem.dragging = false;
                root.dragStartIndex = -1;
                root.dragTargetIndex = -1;
                delegateItem.z = 0;
              }
            }
          }

          // Checkbox
          Rectangle {
            id: box

            Layout.preferredWidth: root.baseSize
            Layout.preferredHeight: root.baseSize
            radius: Style.iRadiusXS
            color: delegateItem.itemEnabled ? root.activeColor : Color.mSurface
            border.color: delegateItem.required ? root.activeColor : Color.mOutline
            border.width: Style.borderS
            opacity: delegateItem.required ? 0.7 : 1.0

            Behavior on color {
              ColorAnimation {
                duration: Style.animationFast
              }
            }

            Behavior on border.color {
              ColorAnimation {
                duration: Style.animationFast
              }
            }

            NIcon {
              visible: delegateItem.itemEnabled
              anchors.centerIn: parent
              anchors.horizontalCenterOffset: -1
              icon: "check"
              color: root.activeOnColor
              pointSize: Math.max(Style.fontSizeXS, root.baseSize * 0.5)
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: (!delegateItem.required && !delegateItem.isDisabled) ? Qt.PointingHandCursor : Qt.ArrowCursor
              enabled: !delegateItem.required && !delegateItem.isDisabled

              onClicked: {
                if (!delegateItem.required && !delegateItem.isDisabled) {
                  root.toggleItem(delegateItem.index);
                }
              }
            }
          }

          // Label
          NText {
            Layout.fillWidth: true
            text: delegateItem.text
            color: Color.mOnSurface
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
          }

          // Required indicator
          NText {
            visible: delegateItem.required
            text: I18n.tr("common.required")
            color: Color.mOnSurfaceVariant
            verticalAlignment: Text.AlignVCenter
          }
        }

        // Position binding for non-dragging state
        y: {
          var currentIndex;
          if (delegateItem.dragging) {
            return delegateItem.y;
          }

          // Check if any item is being dragged
          var draggedIndex = root.dragStartIndex;
          var targetIndex = root.dragTargetIndex;

          // If an item is being dragged, adjust positions
          if (draggedIndex !== -1 && targetIndex !== -1 && draggedIndex !== targetIndex) {
            currentIndex = delegateItem.index;

            if (draggedIndex < targetIndex) {
              // Dragging down: shift items up between draggedIndex and targetIndex
              if (currentIndex > draggedIndex && currentIndex <= targetIndex) {
                return (currentIndex - 1) * (delegateItem.height + delegateItem.itemSpacing);
              }
            } else {
              // Dragging up: shift items down between targetIndex and draggedIndex
              if (currentIndex >= targetIndex && currentIndex < draggedIndex) {
                return (currentIndex + 1) * (delegateItem.height + delegateItem.itemSpacing);
              }
            }
          }

          return delegateItem.index * (delegateItem.height + delegateItem.itemSpacing);
        }

        Behavior on y {
          enabled: !delegateItem.dragging
          NumberAnimation {
            duration: Style.animationNormal
            easing.type: Easing.OutQuad
          }
        }
      }
    }
  }
}
