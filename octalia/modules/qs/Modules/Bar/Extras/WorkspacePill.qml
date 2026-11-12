pragma ComponentBehavior: Bound

import QtQuick 6.10
import qs.Commons
import "../BarWidgetHelpers.js" as BarWidgetHelpers
import qs.Services.Compositor
import qs.Widgets

Item {
  id: pillContainer

  required property var workspace
  required property bool isVertical

  // These must be provided by the parent Workspace widget
  required property real baseDimensionRatio
  required property real capsuleHeight
  required property real barHeight
  required property string labelMode
  required property int fontWeight
  required property int characterCount
  required property real textRatio
  required property bool showLabelsOnlyWhenOccupied
  required property string focusedColor
  required property string occupiedColor
  required property string emptyColor
  required property real masterProgress
  required property bool effectsActive
  required property color effectColor
  required property var getWorkspaceWidth
  required property var getWorkspaceHeight

  // Fixed dimension (cross-axis) for visual pill
  readonly property real fixedDimension: Style.toOdd(capsuleHeight * baseDimensionRatio)

  // Animated pill dimensions (for visual pill, not container)
  property real pillWidth: isVertical ? fixedDimension : BarWidgetHelpers.callWithTwoArguments(pillContainer, "getWorkspaceWidth", pillContainer.workspace, false)
  property real pillHeight: isVertical ? BarWidgetHelpers.callWithTwoArguments(pillContainer, "getWorkspaceHeight", pillContainer.workspace, false) : fixedDimension

  // Container uses full barHeight on cross-axis for larger click area
  width: isVertical ? barHeight : BarWidgetHelpers.callWithTwoArguments(pillContainer, "getWorkspaceWidth", pillContainer.workspace, false)
  height: isVertical ? BarWidgetHelpers.callWithTwoArguments(pillContainer, "getWorkspaceHeight", pillContainer.workspace, false) : barHeight

  states: [
    State {
      name: "active"
      when: BarWidgetHelpers.readProperty(pillContainer.workspace, "isActive")
      PropertyChanges {
        pillContainer.width: pillContainer.isVertical ? pillContainer.barHeight : BarWidgetHelpers.callWithTwoArguments(pillContainer, "getWorkspaceWidth", pillContainer.workspace, true)
        pillContainer.height: pillContainer.isVertical ? BarWidgetHelpers.callWithTwoArguments(pillContainer, "getWorkspaceHeight", pillContainer.workspace, true) : pillContainer.barHeight
        pillContainer.pillWidth: pillContainer.isVertical ? pillContainer.fixedDimension : BarWidgetHelpers.callWithTwoArguments(pillContainer, "getWorkspaceWidth", pillContainer.workspace, true)
        pillContainer.pillHeight: pillContainer.isVertical ? BarWidgetHelpers.callWithTwoArguments(pillContainer, "getWorkspaceHeight", pillContainer.workspace, true) : pillContainer.fixedDimension
      }
    }
  ]

  transitions: [
    Transition {
      from: "inactive"
      to: "active"
      NumberAnimation {
        properties: pillContainer.isVertical ? "height,pillHeight" : "width,pillWidth"
        duration: Style.animationNormal
        easing.type: Easing.OutBack
      }
    },
    Transition {
      from: "active"
      to: "inactive"
      NumberAnimation {
        properties: pillContainer.isVertical ? "height,pillHeight" : "width,pillWidth"
        duration: Style.animationNormal
        easing.type: Easing.OutBack
      }
    }
  ]

  Rectangle {
    id: pill
    width: pillContainer.pillWidth
    height: pillContainer.pillHeight
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)
    radius: Style.radiusM
    z: 0

    color: {
      if (pillMouseArea.containsMouse)
        return Color.mHover;
      if (BarWidgetHelpers.readProperty(pillContainer.workspace, "isFocused"))
        return Color.resolveColorKey(pillContainer.focusedColor);
      if (BarWidgetHelpers.readProperty(pillContainer.workspace, "isUrgent"))
        return Color.mError;
      if (BarWidgetHelpers.readProperty(pillContainer.workspace, "isOccupied"))
        return Color.resolveColorKey(pillContainer.occupiedColor);
      return Qt.alpha(Color.resolveColorKey(pillContainer.emptyColor), 0.3);
    }

    Loader {
      active: (pillContainer.labelMode !== "none") && (!pillContainer.showLabelsOnlyWhenOccupied || BarWidgetHelpers.readProperty(pillContainer.workspace, "isOccupied") || BarWidgetHelpers.readProperty(pillContainer.workspace, "isFocused"))
      anchors.fill: parent
      sourceComponent: Component {
        NText {
          text: BarWidgetHelpers.workspaceLabel(pillContainer.workspace, pillContainer.labelMode, pillContainer.isVertical, pillContainer.characterCount)
          family: Settings.data.ui.fontFixed
          // Size based on the fixed dimension (cross-axis) of the visual pill
          pointSize: (pillContainer.isVertical ? pillContainer.pillWidth : pillContainer.pillHeight) * pillContainer.textRatio
          applyUiScale: false
          font.capitalization: Font.AllUppercase
          font.weight: pillContainer.fontWeight
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          wrapMode: Text.Wrap
          color: {
            if (pillMouseArea.containsMouse)
              return Color.mOnHover;
            if (BarWidgetHelpers.readProperty(pillContainer.workspace, "isFocused"))
              return Color.resolveOnColorKey(pillContainer.focusedColor);
            if (BarWidgetHelpers.readProperty(pillContainer.workspace, "isUrgent"))
              return Color.mOnError;
            if (BarWidgetHelpers.readProperty(pillContainer.workspace, "isOccupied"))
              return Color.resolveOnColorKey(pillContainer.occupiedColor);
            return Color.resolveOnColorKey(pillContainer.emptyColor);
          }

          Behavior on color {
            enabled: !Color.isTransitioning
            ColorAnimation {
              duration: Style.animationFast
              easing.type: Easing.InOutQuad
            }
          }
        }
      }
    }

    // Material 3-inspired smooth animations
    Behavior on scale {
      NumberAnimation {
        duration: Style.animationNormal
        easing.type: Easing.OutBack
      }
    }
    Behavior on color {
      enabled: !Color.isTransitioning
      ColorAnimation {
        duration: Style.animationFast
        easing.type: Easing.InOutQuad
      }
    }
    Behavior on opacity {
      NumberAnimation {
        duration: Style.animationFast
        easing.type: Easing.InOutCubic
      }
    }
    Behavior on radius {
      NumberAnimation {
        duration: Style.animationNormal
        easing.type: Easing.OutBack
      }
    }
  }

  Behavior on width {
    NumberAnimation {
      duration: Style.animationNormal
      easing.type: Easing.OutBack
    }
  }
  Behavior on height {
    NumberAnimation {
      duration: Style.animationNormal
      easing.type: Easing.OutBack
    }
  }
  Behavior on pillWidth {
    NumberAnimation {
      duration: Style.animationNormal
      easing.type: Easing.OutBack
    }
  }
  Behavior on pillHeight {
    NumberAnimation {
      duration: Style.animationNormal
      easing.type: Easing.OutBack
    }
  }

  // Full-height click area
  MouseArea {
    id: pillMouseArea
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    hoverEnabled: true
    onClicked: {
      CompositorService.switchToWorkspace(pillContainer.workspace);
    }
  }

  // Burst effect overlay for focused pill
  Rectangle {
    id: pillBurst
    anchors.centerIn: pill
    width: pillContainer.pillWidth + 18 * pillContainer.masterProgress * scale
    height: pillContainer.pillHeight + 18 * pillContainer.masterProgress * scale
    radius: width / 2
    color: "transparent"
    border.color: pillContainer.effectColor
    border.width: Math.max(1, Math.round((2 + 6 * (1.0 - pillContainer.masterProgress))))
    opacity: pillContainer.effectsActive && BarWidgetHelpers.readProperty(pillContainer.workspace, "isFocused") ? (1.0 - pillContainer.masterProgress) * 0.7 : 0
    visible: pillContainer.effectsActive && BarWidgetHelpers.readProperty(pillContainer.workspace, "isFocused")
    z: 1
  }
}
