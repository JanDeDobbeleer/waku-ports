import QtQuick 6.10
import QtQuick.Controls.Basic
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "./SetupCustomizeStepUtils.js" as SetupCustomizeStepUtils

ColumnLayout {
  id: root

  property real selectedScaleRatio: 1.0
  property string selectedBarPosition: "top"

  signal scaleRatioChanged(real ratio)
  signal barPositionChanged(string position)

  spacing: Style.marginM

  // Beautiful header with icon
  RowLayout {
    Layout.fillWidth: true
    Layout.bottomMargin: Style.marginL
    spacing: Style.marginM

    Rectangle {
      Layout.preferredWidth: 40
      Layout.preferredHeight: 40
      radius: Style.radiusL
      color: Color.mSurfaceVariant
      opacity: 0.6

      NIcon {
        icon: "palette"
        pointSize: Style.fontSizeL
        color: Color.mPrimary
        anchors.centerIn: parent
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginXS

      NText {
        text: I18n.tr("setup.customize.header")
        pointSize: Style.fontSizeXL
        font.weight: Style.fontWeightBold
        color: Color.mPrimary
      }

      NText {
        text: I18n.tr("setup.customize.subheader")
        pointSize: Style.fontSizeM
        color: Color.mOnSurfaceVariant
      }
    }
  }

  NScrollView {
    id: customizeScrollView
    Layout.fillWidth: true
    Layout.fillHeight: true
    horizontalPolicy: ScrollBar.AlwaysOff
    verticalPolicy: ScrollBar.AsNeeded

    ColumnLayout {
      width: customizeScrollView.availableWidth
      spacing: Style.marginM

      // Bar Position section
      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.marginS

          Rectangle {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            radius: Style.radiusM
            color: Color.mSurface

            NIcon {
              icon: "layout-2"
              pointSize: Style.fontSizeL
              color: Color.mPrimary
              anchors.centerIn: parent
            }
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            NText {
              text: I18n.tr("panels.bar.appearance-position-label")
              pointSize: Style.fontSizeL
              font.weight: Style.fontWeightBold
              color: Color.mOnSurface
            }

            NText {
              text: I18n.tr("panels.bar.appearance-position-description")
              pointSize: Style.fontSizeS
              color: Color.mOnSurfaceVariant
            }
          }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.marginS

          Repeater {
            model: [
              {
                "key": "top",
                "name": I18n.tr("positions.top"),
                "icon": "arrow-up",
                "active": root.selectedBarPosition === "top",
                "select": function() { root.selectedBarPosition = "top"; root.barPositionChanged("top"); }
              },
              {
                "key": "bottom",
                "name": I18n.tr("positions.bottom"),
                "icon": "arrow-down",
                "active": root.selectedBarPosition === "bottom",
                "select": function() { root.selectedBarPosition = "bottom"; root.barPositionChanged("bottom"); }
              },
              {
                "key": "left",
                "name": I18n.tr("positions.left"),
                "icon": "arrow-left",
                "active": root.selectedBarPosition === "left",
                "select": function() { root.selectedBarPosition = "left"; root.barPositionChanged("left"); }
              },
              {
                "key": "right",
                "name": I18n.tr("positions.right"),
                "icon": "arrow-right",
                "active": root.selectedBarPosition === "right",
                "select": function() { root.selectedBarPosition = "right"; root.barPositionChanged("right"); }
              }
            ]
            delegate: Rectangle {
              id: positionOption
              required property var modelData
              Layout.fillWidth: true
              Layout.preferredHeight: 40
              radius: Style.radiusM
              border.width: Style.borderS

              property bool isActive: SetupCustomizeStepUtils.field(positionOption.modelData, "active")

              color: (barPositionHoverHandler.hovered || isActive) ? Color.mPrimary : Color.mSurfaceVariant
              border.color: (barPositionHoverHandler.hovered || isActive) ? Color.mPrimary : Color.mOutline
              opacity: (barPositionHoverHandler.hovered || isActive) ? 1.0 : 0.8

              NText {
                text: SetupCustomizeStepUtils.field(positionOption.modelData, "name")
                pointSize: Style.fontSizeM
                font.weight: (barPositionHoverHandler.hovered || positionOption.isActive) ? Style.fontWeightBold : Style.fontWeightMedium
                color: (barPositionHoverHandler.hovered || positionOption.isActive) ? Color.mOnPrimary : Color.mOnSurface
                anchors.centerIn: parent
              }

              HoverHandler {
                id: barPositionHoverHandler
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  SetupCustomizeStepUtils.select(positionOption.modelData);
                }
              }

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
              Behavior on opacity {
                NumberAnimation {
                  duration: Style.animationFast
                }
              }
            }
          }
        }
      }

      // Divider
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Color.mOutline
        opacity: 0.2
        Layout.topMargin: Style.marginS
        Layout.bottomMargin: Style.marginS
      }

      // Bar Density section
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        Rectangle {
          Layout.preferredWidth: 32
          Layout.preferredHeight: 32
          radius: Style.radiusM
          color: Color.mSurface
          NIcon {
            icon: "minimize"
            pointSize: Style.fontSizeL
            color: Color.mPrimary
            anchors.centerIn: parent
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 2
          NText {
            text: I18n.tr("panels.bar.appearance-density-label")
            pointSize: Style.fontSizeL
            font.weight: Style.fontWeightBold
            color: Color.mOnSurface
          }
          NText {
            text: I18n.tr("panels.bar.appearance-density-description")
            pointSize: Style.fontSizeS
            color: Color.mOnSurfaceVariant
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
          }
        }

        RowLayout {
          spacing: Style.marginS
          Repeater {
            model: [
              {
                "key": "mini",
                "name": I18n.tr("options.bar.density-mini")
              },
              {
                "key": "compact",
                "name": I18n.tr("options.bar.density-compact")
              },
              {
                "key": "default",
                "name": I18n.tr("options.bar.density-default")
              },
              {
                "key": "comfortable",
                "name": I18n.tr("options.bar.density-comfortable")
              },
              {
                "key": "spacious",
                "name": I18n.tr("options.bar.density-spacious")
              }
            ]
            delegate: Rectangle {
              id: densityOption
              required property var modelData
              radius: Style.radiusM
              border.width: Style.borderS
              Layout.preferredHeight: 32
              Layout.preferredWidth: Math.max(90, densityText.implicitWidth + Style.margin2XL)

              property bool isActive: Settings.data.bar.density === SetupCustomizeStepUtils.field(densityOption.modelData, "key")

              color: (densityHoverHandler.hovered || isActive) ? Color.mPrimary : Color.mSurfaceVariant
              border.color: (densityHoverHandler.hovered || isActive) ? Color.mPrimary : Color.mOutline
              opacity: (densityHoverHandler.hovered || isActive) ? 1.0 : 0.8

              NText {
                id: densityText
                text: SetupCustomizeStepUtils.field(densityOption.modelData, "name")
                pointSize: Style.fontSizeS
                font.weight: (densityHoverHandler.hovered || densityOption.isActive) ? Style.fontWeightBold : Style.fontWeightMedium
                color: (densityHoverHandler.hovered || densityOption.isActive) ? Color.mOnPrimary : Color.mOnSurface
                anchors.centerIn: parent
              }

              HoverHandler {
                id: densityHoverHandler
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  Settings.data.bar.density = SetupCustomizeStepUtils.field(densityOption.modelData, "key");
                }
              }

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
              Behavior on opacity {
                NumberAnimation {
                  duration: Style.animationFast
                }
              }
            }
          }
        }
      }

      // Divider
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Color.mOutline
        opacity: 0.2
        Layout.topMargin: Style.marginS
        Layout.bottomMargin: Style.marginS
      }

      // UI Scale section
      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.marginS
          Rectangle {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            radius: Style.radiusM
            color: Color.mSurface
            NIcon {
              icon: "maximize"
              pointSize: Style.fontSizeL
              color: Color.mPrimary
              anchors.centerIn: parent
            }
          }
          ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            NText {
              text: I18n.tr("panels.user-interface.scaling-label")
              pointSize: Style.fontSizeL
              font.weight: Style.fontWeightBold
              color: Color.mOnSurface
            }
            NText {
              text: I18n.tr("panels.user-interface.scaling-description")
              pointSize: Style.fontSizeS
              color: Color.mOnSurfaceVariant
            }
          }
        }

        NValueSlider {
          Layout.fillWidth: true
          from: 0.8
          to: 1.2
          stepSize: 0.05
          value: root.selectedScaleRatio
          onMoved: function (value) {
            root.selectedScaleRatio = value;
            root.scaleRatioChanged(value);
          }
          text: Math.floor(root.selectedScaleRatio * 100) + "%"
        }
      }

      // Divider
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Color.mOutline
        opacity: 0.2
        Layout.topMargin: Style.marginS
        Layout.bottomMargin: Style.marginS
      }

      // Bar Type section
      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.marginS

          Rectangle {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            radius: Style.radiusM
            color: Color.mSurface

            NIcon {
              icon: "layout-2"
              pointSize: Style.fontSizeL
              color: Color.mPrimary
              anchors.centerIn: parent
            }
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            NText {
              text: I18n.tr("panels.bar.appearance-type-label") ?? "Bar Type"
              pointSize: Style.fontSizeL
              font.weight: Style.fontWeightBold
              color: Color.mOnSurface
            }

            NText {
              text: I18n.tr("panels.bar.appearance-type-description") ?? "Choose the style of the bar: Simple, Floating or Framed"
              pointSize: Style.fontSizeS
              color: Color.mOnSurfaceVariant
            }
          }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.marginS

          Repeater {
            model: [
              {
                "key": "simple",
                "name": I18n.tr("options.bar.type-simple") ?? "Simple"
              },
              {
                "key": "floating",
                "name": I18n.tr("options.bar.type-floating") ?? "Floating"
              },
              {
                "key": "framed",
                "name": I18n.tr("options.bar.type-framed") ?? "Framed"
              }
            ]
            delegate: Rectangle {
              id: barTypeOption
              required property var modelData
              Layout.fillWidth: true
              Layout.preferredHeight: 40
              radius: Style.radiusM
              border.width: Style.borderS

              property bool isActive: Settings.data.bar.barType === SetupCustomizeStepUtils.field(barTypeOption.modelData, "key")

              color: (barTypeHoverHandler.hovered || isActive) ? Color.mPrimary : Color.mSurfaceVariant
              border.color: (barTypeHoverHandler.hovered || isActive) ? Color.mPrimary : Color.mOutline
              opacity: (barTypeHoverHandler.hovered || isActive) ? 1.0 : 0.8

              NText {
                text: SetupCustomizeStepUtils.field(barTypeOption.modelData, "name")
                pointSize: Style.fontSizeM
                font.weight: (barTypeHoverHandler.hovered || barTypeOption.isActive) ? Style.fontWeightBold : Style.fontWeightMedium
                color: (barTypeHoverHandler.hovered || barTypeOption.isActive) ? Color.mOnPrimary : Color.mOnSurface
                anchors.centerIn: parent
              }

              HoverHandler {
                id: barTypeHoverHandler
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  Settings.data.bar.barType = SetupCustomizeStepUtils.field(barTypeOption.modelData, "key");
                }
              }

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
              Behavior on opacity {
                NumberAnimation {
                  duration: Style.animationFast
                }
              }
            }
          }
        }
      }

      // Divider
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Color.mOutline
        opacity: 0.2
        Layout.topMargin: Style.marginS
        Layout.bottomMargin: Style.marginS
      }

      // Divider
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Color.mOutline
        opacity: 0.2
        Layout.topMargin: Style.marginS
        Layout.bottomMargin: Style.marginS
      }

      // Dim Desktop opacity
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM
        Rectangle {
          Layout.preferredWidth: 32
          Layout.preferredHeight: 32
          radius: Style.radiusM
          color: Color.mSurface
          NIcon {
            icon: "screen-share"
            pointSize: Style.fontSizeL
            color: Color.mPrimary
            anchors.centerIn: parent
          }
        }
        ColumnLayout {
          Layout.fillWidth: true
          spacing: 2
          NText {
            text: I18n.tr("panels.user-interface.dimmer-opacity-label")
            pointSize: Style.fontSizeL
            font.weight: Style.fontWeightBold
            color: Color.mOnSurface
          }
          NText {
            text: I18n.tr("panels.user-interface.dimmer-opacity-description")
            pointSize: Style.fontSizeS
            color: Color.mOnSurfaceVariant
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
          }
          NValueSlider {
            Layout.fillWidth: true
            Layout.topMargin: Style.marginXS
            from: 0
            to: 1
            stepSize: 0.01
            value: Settings.data.general.dimmerOpacity
            onMoved: value => Settings.data.general.dimmerOpacity = value
            text: Math.floor(Settings.data.general.dimmerOpacity * 100) + "%"
          }
        }
      }

      // Divider
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Color.mOutline
        opacity: 0.2
        Layout.topMargin: Style.marginS
        Layout.bottomMargin: Style.marginS
      }

      // Drop Shadows toggle
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM
        Rectangle {
          Layout.preferredWidth: 32
          Layout.preferredHeight: 32
          radius: Style.radiusM
          color: Color.mSurface
          NIcon {
            icon: "shadow"
            pointSize: Style.fontSizeL
            color: Color.mPrimary
            anchors.centerIn: parent
          }
        }
        ColumnLayout {
          Layout.fillWidth: true
          spacing: 2
          NText {
            text: I18n.tr("panels.user-interface.shadows-label")
            pointSize: Style.fontSizeL
            font.weight: Style.fontWeightBold
            color: Color.mOnSurface
          }
          NText {
            text: I18n.tr("panels.user-interface.shadows-description")
            pointSize: Style.fontSizeS
            color: Color.mOnSurfaceVariant
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
          }
        }
        NToggle {
          checked: Settings.data.general.enableShadows
          onToggled: checked => Settings.data.general.enableShadows = checked
        }
      }

      Item {
        Layout.fillWidth: true
        Layout.preferredHeight: Style.marginL
      }
    }
  }
}
