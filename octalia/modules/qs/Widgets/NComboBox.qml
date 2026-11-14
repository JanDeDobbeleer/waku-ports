pragma ComponentBehavior: Bound

import "NComboBoxUtils.js" as ComboUtils

import QtQuick 6.10
import QtQuick.Controls.Basic
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

RowLayout {
  id: root

  property real minimumWidth: 200
  property real popupHeight: 180

  property string label: ""
  property string description: ""
  property var model
  property string currentKey: ""
  property string placeholder: ""
  property var defaultValue: undefined
  property string settingsPath: ""
  property real baseSize: 1.0

  readonly property real preferredHeight: Math.round(Style.baseWidgetSize * 1.1 * root.baseSize)
  readonly property var comboBox: combo

  signal selected(string key)

  spacing: Style.marginL

  // Less strict comparison with != (instead of !==) so it can properly compare int vs string (ex for FPS: 30 and "30")
  readonly property bool isValueChanged: (defaultValue !== undefined) && (currentKey != defaultValue)

  function itemCount(): var {
    return ComboUtils.itemCount(root);
  }

  function getItem(index: var): var {
    return ComboUtils.getItem(index, root);
  }

  function findIndexByKey(key: var): int {
    return ComboUtils.findIndexByKey(key, root);
  }

  NLabel {
    label: root.label
    description: root.description
    showIndicator: root.isValueChanged
  }

  ComboBox {
    id: combo

    opacity: enabled ? 1.0 : 0.6
    Layout.margins: Style.borderS
    Layout.minimumWidth: Math.round(root.minimumWidth * Style.uiScaleRatio)
    Layout.preferredHeight: Math.round(root.preferredHeight * Style.uiScaleRatio)
    implicitWidth: Layout.minimumWidth
    model: root.model
    textRole: "name"
    currentIndex: root.findIndexByKey(root.currentKey)

    onActivated: {
      ComboUtils.select(combo.currentIndex, root);
    }

    Keys.onUpPressed: event => {
                        if (combo.popup.visible) {
                          if (listView.currentIndex > 0) {
                            listView.currentIndex--;
                            listView.positionViewAtIndex(listView.currentIndex, ListView.Contain);
                          }
                          event.accepted = true;
                        } else {
                          event.accepted = false;
                        }
                      }

    Keys.onDownPressed: event => {
                          if (combo.popup.visible) {
                            if (listView.currentIndex < root.itemCount() - 1) {
                              listView.currentIndex++;
                              listView.positionViewAtIndex(listView.currentIndex, ListView.Contain);
                            }
                            event.accepted = true;
                          } else {
                            event.accepted = false;
                          }
                        }

    Keys.onReturnPressed: event => {
                            if (combo.popup.visible) {
                              if (ComboUtils.select(listView.currentIndex, root)) {
                                combo.currentIndex = listView.currentIndex;
                                ComboUtils.closePopup(combo.popup);
                              }
                              event.accepted = true;
                            } else {
                              event.accepted = false;
                            }
                          }

    Keys.onEnterPressed: event => {
                           combo.Keys.returnPressed(event);
                         }

    background: Rectangle {
      implicitWidth: Math.round(Style.baseWidgetSize * 3.75 * Style.uiScaleRatio)
      implicitHeight: Math.round(root.preferredHeight * Style.uiScaleRatio)
      color: Color.mSurface
      border.color: combo.activeFocus ? Color.mSecondary : Color.mOutline
      border.width: Style.borderS
      radius: Style.iRadiusM

      Behavior on border.color {
        ColorAnimation {
          duration: Style.animationFast
        }
      }
    }

    contentItem: NText {
      leftPadding: Style.marginL
      rightPadding: combo.indicator.width + Style.marginL
      pointSize: Style.fontSizeM
      verticalAlignment: Text.AlignVCenter
      elide: Text.ElideRight
      color: combo.currentIndex >= 0 ? Color.mOnSurface : Color.mOnSurfaceVariant
      text: {
        if (combo.currentIndex >= 0 && combo.currentIndex < root.itemCount()) {
          return ComboUtils.currentText(combo.currentIndex, root);
        }
        return root.placeholder;
      }
    }

    indicator: NIcon {
      x: combo.width - width - Style.marginM
      y: combo.topPadding + (combo.availableHeight - height) / 2
      icon: "caret-down"
      pointSize: Style.fontSizeL
    }

    popup: Popup {
      y: combo.height + Style.marginS
      implicitWidth: combo.width
      implicitHeight: Math.min(Math.round(root.popupHeight * Style.uiScaleRatio), listView.contentHeight + Style.margin2M)
      padding: Style.marginM

      onOpened: {
        listView.currentIndex = combo.currentIndex;
        listView.positionViewAtIndex(combo.currentIndex, ListView.Beginning);
      }

      contentItem: NListView {
        id: listView
        property var comboBox: combo
        model: combo.popup.visible ? root.model : null
        highlightMoveDuration: 0
        //showGradientMasks: false

        delegate: Rectangle {
          id: delegateRect
          required property int index
          property bool isHighlighted: listView.currentIndex === index

          width: listView.availableWidth
          height: delegateText.implicitHeight + Style.margin2S
          radius: Style.iRadiusS
          color: isHighlighted ? Color.mHover : "transparent"

          NText {
            id: delegateText
            anchors.fill: parent
            anchors.leftMargin: Style.marginM
            anchors.rightMargin: Style.marginM
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            pointSize: Style.fontSizeM
            color: delegateRect.isHighlighted ? Color.mOnHover : Color.mOnSurface
            text: {
              return ComboUtils.delegateText(delegateRect.index, root);
            }
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onContainsMouseChanged: {
              if (containsMouse) {
                listView.currentIndex = delegateRect.index;
              }
            }
            onClicked: {
              if (ComboUtils.select(delegateRect.index, root)) {
                combo.currentIndex = delegateRect.index;
                ComboUtils.closePopup(combo.popup);
              }
            }
          }
        }
      }

      background: Rectangle {
        color: Color.mSurfaceVariant
        border.color: Color.mOutline
        border.width: Style.borderS
        radius: Style.iRadiusM
      }
    }

    Connections {
      target: root
      function onCurrentKeyChanged() {
        combo.currentIndex = root.findIndexByKey(root.currentKey);
      }
      function onModelChanged() {
        combo.currentIndex = root.findIndexByKey(root.currentKey);
      }
    }
  }
}
