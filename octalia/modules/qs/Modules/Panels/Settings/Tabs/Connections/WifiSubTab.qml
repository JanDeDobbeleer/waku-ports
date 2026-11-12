import QtQuick 6.10
import QtQuick.Layouts

import qs.Commons
import qs.Services.Networking
import qs.Services.System
import qs.Services.UI
import qs.Widgets
import qs.compat

Item {
  id: root
  Layout.fillWidth: true
  implicitHeight: mainLayout.implicitHeight

  // Configuration for shared use (e.g. by NetworkPanel)
  property bool showOnlyLists: false

  // State properties
  property string passwordSsid: ""
  property string infoSsid: ""
  property bool detailsGrid: (Settings.data && Settings.data.network && Settings.data.network.wifiDetailsViewMode === "grid")

  readonly property var activeNetworks: Object.values(NetworkService.networks)

  readonly property var connectedNetworks: {
    if (!NetworkService.wifiEnabled) {
      return [];
    }
    return activeNetworks.filter(n => n.connected).sort((a, b) => b.signal - a.signal);
  }

  readonly property var savedNetworks: {
    if (!NetworkService.wifiEnabled) {
      return [];
    }
    return activeNetworks.filter(n => !n.connected && n.existing).sort((a, b) => b.signal - a.signal);
  }

  readonly property var availableNetworks: {
    if (!NetworkService.wifiEnabled) {
      return [];
    }
    return activeNetworks.filter(n => !n.connected && !n.existing).sort((a, b) => b.signal - a.signal);
  }

  // Combined visibility check: tab must be visible AND the window must be visible
  readonly property bool effectivelyVisible: root.visible && Window.window && Window.window.visible

  onEffectivelyVisibleChanged: {
    if (effectivelyVisible) {
      SystemStatService.registerComponent("wifi-subtab");
      if (NetworkService.wifiEnabled && !NetworkService.scanningActive && !showOnlyLists) {
        NetworkService.scan();
        NetworkService.refreshActiveWifiDetails();
      }
    } else {
      SystemStatService.unregisterComponent("wifi-subtab");
    }
  }

  Component.onDestruction: {
    SystemStatService.unregisterComponent("wifi-subtab");
  }

  ColumnLayout {
    id: mainLayout
    anchors.left: parent.left
    anchors.right: parent.right
    spacing: root.showOnlyLists ? Style.marginM : Style.marginL

    // Master Control Section
    NBox {
      visible: !root.showOnlyLists
      Layout.fillWidth: true
      Layout.preferredHeight: masterControlCol.implicitHeight + Style.margin2L
      color: Color.mSurface

      ColumnLayout {
        id: masterControlCol
        anchors.fill: parent
        anchors.margins: Style.marginL
        spacing: Style.marginM

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.marginM

          NToggle {
            label: I18n.tr("common.wifi")
            icon: NetworkService.wifiEnabled ? "wifi" : "wifi-off"
            checked: NetworkService.wifiEnabled
            enabled: NetworkService.wifiAvailable
            onToggled: checked => NetworkService.setWifiEnabled(checked)
            Layout.alignment: Qt.AlignVCenter
          }
        }

        NDivider {
          Layout.fillWidth: true
          visible: NetworkService.wifiEnabled
        }

        NText {
          visible: !root.showOnlyLists && NetworkService.wifiEnabled
          Layout.fillWidth: true
          text: I18n.tr("panels.connections.wifi-header-text")
          color: Color.mOnSurfaceVariant
          richTextEnabled: true
          wrapMode: Text.WordWrap
          horizontalAlignment: Text.AlignHCenter
        }
      }
    }

    Item {
      visible: !showOnlyLists
      Layout.fillWidth: true
    }

    // Network List [1] (Connected)
    NBox {
      id: connectedBox
      visible: root.connectedNetworks.length > 0 && NetworkService.wifiEnabled
      Layout.fillWidth: true
      Layout.preferredHeight: connectedCol.implicitHeight + Style.margin2M
      border.color: showOnlyLists ? Style.boxBorderColor : "transparent"
      color: showOnlyLists ? Color.mSurfaceVariant : "transparent"

      ColumnLayout {
        id: connectedCol
        anchors.fill: parent
        anchors.topMargin: Style.marginM
        anchors.bottomMargin: Style.marginM
        anchors.leftMargin: showOnlyLists ? Style.marginL : 0
        anchors.rightMargin: showOnlyLists ? Style.marginL : 0
        spacing: Style.marginM

        NLabel {
          label: I18n.tr("common.connected")
          Layout.fillWidth: true
          Layout.leftMargin: Style.marginS
        }

        Repeater {
          model: root.connectedNetworks
          delegate: nboxDelegate
        }
      }
    }

    // Network List [2] (Saved)
    NBox {
      id: savedBox
      visible: root.savedNetworks.length > 0 && NetworkService.wifiEnabled
      Layout.fillWidth: true
      Layout.preferredHeight: savedCol.implicitHeight + Style.margin2M
      border.color: showOnlyLists ? Style.boxBorderColor : "transparent"
      color: showOnlyLists ? Color.mSurfaceVariant : "transparent"

      ColumnLayout {
        id: savedCol
        anchors.fill: parent
        anchors.topMargin: Style.marginM
        anchors.bottomMargin: Style.marginM
        anchors.leftMargin: showOnlyLists ? Style.marginL : 0
        anchors.rightMargin: showOnlyLists ? Style.marginL : 0
        spacing: Style.marginM

        NLabel {
          label: I18n.tr("wifi.panel.known-networks")
          Layout.fillWidth: true
          Layout.leftMargin: Style.marginS
        }

        Repeater {
          model: root.savedNetworks
          delegate: nboxDelegate
        }
      }
    }

    // Network List [3] (Available)
    NBox {
      id: availableBox
      visible: root.availableNetworks.length > 0 && NetworkService.wifiEnabled
      Layout.fillWidth: true
      Layout.preferredHeight: availableCol.implicitHeight + Style.margin2M
      border.color: showOnlyLists ? Style.boxBorderColor : "transparent"
      color: showOnlyLists ? Color.mSurfaceVariant : "transparent"

      ColumnLayout {
        id: availableCol
        anchors.fill: parent
        anchors.topMargin: Style.marginM
        anchors.bottomMargin: Style.marginM
        anchors.leftMargin: showOnlyLists ? Style.marginL : 0
        anchors.rightMargin: showOnlyLists ? Style.marginL : 0
        spacing: Style.marginM

        RowLayout {
          Layout.fillWidth: true
          Layout.leftMargin: Style.marginS
          spacing: Style.marginS

          NLabel {
            label: I18n.tr("wifi.panel.available-networks")
            description: "Not saved in Windows yet. Connect to them once in Windows' Wi-Fi settings."
            Layout.fillWidth: true
          }
        }

        Repeater {
          model: root.availableNetworks
          delegate: nboxDelegate
        }
      }
    }
  }

  // Shared Delegate
  Component {
    id: nboxDelegate
    NBox {
      id: networkItem

      readonly property bool isBusy: NetworkService.connectingTo === modelData.ssid || NetworkService.disconnectingFrom === modelData.ssid || NetworkService.forgettingNetwork === modelData.ssid
      readonly property bool isExpanded: root.infoSsid === modelData.ssid
      readonly property bool isEnterprise: NetworkService.isEnterprise(modelData.security)

      function getContentColors(defaultColors = [Color.mSurface, Color.mOnSurface]) {
        if (NetworkService.connectingTo === modelData.ssid) {
          return [Color.mPrimary, Color.mOnPrimary];
        }
        if (modelData.connected && NetworkService.internetConnectivity && NetworkService.disconnectingFrom !== modelData.ssid) {
          return [Color.mPrimary, Color.mOnPrimary];
        }
        if (NetworkService.disconnectingFrom === modelData.ssid || NetworkService.forgettingNetwork === modelData.ssid) {
          return [Color.mError, Color.mOnError];
        }
        if (modelData.connected && !NetworkService.internetConnectivity) {
          return [Color.mError, Color.mOnError];
        }
        return defaultColors;
      }

      Layout.fillWidth: true
      Layout.preferredHeight: deviceColumn.implicitHeight + (Style.marginXL)
      radius: Style.radiusM
      clip: true
      forceOpaque: true
      color: networkItem.getContentColors()[0]

      ColumnLayout {
        id: deviceColumn
        anchors.fill: parent
        anchors.margins: Style.marginM
        spacing: Style.marginS

        RowLayout {
          id: deviceLayout
          Layout.fillWidth: true
          spacing: Style.marginM
          Layout.alignment: Qt.AlignVCenter

          NIcon {
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            icon: NetworkService.getSignalInfo(modelData.signal, modelData.connected).icon
            pointSize: Style.fontSizeXXL
            color: networkItem.getContentColors()[1]
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.marginXXS

            NText {
              text: modelData.ssid
              pointSize: Style.fontSizeM
              font.weight: modelData.connected ? Style.fontWeightBold : Style.fontWeightMedium
              elide: Text.ElideRight
              color: networkItem.getContentColors()[1]
              Layout.fillWidth: true
            }

            RowLayout {
              spacing: Style.marginXS

              NIcon {
                icon: NetworkService.isSecured(modelData.security) ? "lock" : "lock-open"
                pointSize: Style.fontSizeXXS
                color: Qt.alpha(networkItem.getContentColors()[1], Style.opacityHeavy)
                visible: !modelData.connected && NetworkService.disconnectingFrom !== modelData.ssid && NetworkService.forgettingNetwork !== modelData.ssid
              }

              NText {
                text: {
                  if (NetworkService.disconnectingFrom === modelData.ssid) {
                    return I18n.tr("wifi.panel.disconnecting");
                  }
                  if (NetworkService.forgettingNetwork === modelData.ssid) {
                    return I18n.tr("wifi.panel.forgetting");
                  }
                  if (modelData.connected) {
                    switch (NetworkService.networkConnectivity) {
                    case "full":
                      return I18n.tr("common.connected");
                    case "limited":
                      return I18n.tr("wifi.panel.internet-limited");
                    case "portal":
                      return I18n.tr("wifi.panel.action-required");
                    default:
                      return NetworkService.networkConnectivity;
                    }
                  }
                  return NetworkService.isSecured(modelData.security) ? modelData.security : I18n.tr("wifi.panel.security-open");
                }
                pointSize: Style.fontSizeXXS
                color: Qt.alpha(networkItem.getContentColors()[1], Style.opacityHeavy)
              }

              // Network speed indicators (visible when connected and speed > 0)
              RowLayout {
                visible: (modelData.connected && NetworkService.networkConnectivity === "full") && (SystemStatService.rxSpeed > 0 || SystemStatService.txSpeed > 0)
                spacing: 2
                Layout.leftMargin: Style.marginXS
                Layout.fillWidth: false

                NIcon {
                  visible: SystemStatService.rxSpeed > 0
                  icon: "arrow-down"
                  pointSize: Style.fontSizeXXS
                  color: Qt.alpha(networkItem.getContentColors()[1], Style.opacityHeavy)
                }

                NText {
                  visible: SystemStatService.rxSpeed > 0
                  text: SystemStatService.formatSpeed(SystemStatService.rxSpeed)
                  pointSize: Style.fontSizeXXS
                  color: Qt.alpha(networkItem.getContentColors()[1], Style.opacityHeavy)
                  elide: Text.ElideNone
                }

                Item {
                  visible: SystemStatService.rxSpeed > 0 && SystemStatService.txSpeed > 0
                  width: Style.marginXS
                  height: 1
                }

                NIcon {
                  visible: SystemStatService.txSpeed > 0
                  icon: "arrow-up"
                  pointSize: Style.fontSizeXXS
                  color: Qt.alpha(networkItem.getContentColors()[1], Style.opacityHeavy)
                }

                NText {
                  visible: SystemStatService.txSpeed > 0
                  text: SystemStatService.formatSpeed(SystemStatService.txSpeed)
                  pointSize: Style.fontSizeXXS
                  color: Qt.alpha(networkItem.getContentColors()[1], Style.opacityHeavy)
                  elide: Text.ElideNone
                }
              }
            }
          }

          Item {
            Layout.fillWidth: true
          }

          RowLayout {
            spacing: Style.marginS

            NBusyIndicator {
              visible: networkItem.isBusy
              running: visible && root.effectivelyVisible
              color: networkItem.getContentColors()[1]
              size: Style.baseWidgetSize * 0.5
            }

            NIconButton {
              visible: modelData.connected && NetworkService.disconnectingFrom !== modelData.ssid
              icon: "info"
              baseSize: Style.baseWidgetSize * 0.75
              colorBg: Color.mSurfaceVariant
              colorFg: Color.mOnSurface
              colorBorder: "transparent"
              colorBorderHover: "transparent"
              onClicked: {
                if (root.infoSsid === modelData.ssid) {
                  root.infoSsid = "";
                } else {
                  root.infoSsid = modelData.ssid;
                  NetworkService.refreshActiveWifiDetails();
                }
              }
            }

            NButton {
              id: button
              visible: modelData.existing && !modelData.connected && NetworkService.connectingTo !== modelData.ssid
              enabled: !NetworkService.connecting && !networkItem.isBusy
              fontSize: Style.fontSizeS
              backgroundColor: Color.mPrimary
              textColor: Color.mOnPrimary
              text: I18n.tr("common.connect")
              onClicked: NetworkService.connect(modelData.ssid)
            }
          }
        }

        // Connection info details
        Rectangle {
          visible: networkItem.isExpanded
          Layout.fillWidth: true
          implicitHeight: infoColumn.implicitHeight + Style.margin2S
          radius: Style.radiusXS
          color: Color.mSurfaceVariant
          border.width: Style.borderS
          border.color: Style.boxBorderColor
          clip: true

          onVisibleChanged: {
            if (visible && infoColumn && infoColumn.forceLayout) {
              Qt.callLater(function () {
                infoColumn.forceLayout();
              });
            }
          }

          NIconButton {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: Style.marginS
            icon: root.detailsGrid ? "layout-list" : "layout-grid"
            baseSize: Style.baseWidgetSize * 0.65
            onClicked: {
              root.detailsGrid = !root.detailsGrid;
              Settings.data.network.wifiDetailsViewMode = root.detailsGrid ? "grid" : "list";
            }
            z: 1
          }

          GridLayout {
            id: infoColumn
            anchors.fill: parent
            anchors.margins: Style.marginS
            flow: root.detailsGrid ? GridLayout.TopToBottom : GridLayout.LeftToRight
            rows: root.detailsGrid ? 1 : 2
            columns: root.detailsGrid ? 2 : 1
            columnSpacing: Style.marginM
            rowSpacing: Style.marginXS
            onColumnsChanged: {
              if (infoColumn.forceLayout) {
                Qt.callLater(function () {
                  infoColumn.forceLayout();
                });
              }
            }

            // --- Item 1: Interface ---
            RowLayout {
              Layout.fillWidth: true
              Layout.preferredWidth: 1
              spacing: Style.marginXS
              NIcon {
                icon: "network"
                pointSize: Style.fontSizeXS
                color: Color.mOnSurface
              }
              NText {
                text: NetworkService.activeWifiIf || "-"
                pointSize: Style.fontSizeXS
                color: Color.mOnSurface
                Layout.fillWidth: true
                wrapMode: root.detailsGrid ? Text.NoWrap : Text.WrapAtWordBoundaryOrAnywhere
                elide: root.detailsGrid ? Text.ElideRight : Text.ElideNone
                maximumLineCount: root.detailsGrid ? 1 : 6
                clip: true

                MouseArea {
                  anchors.fill: parent
                  enabled: (NetworkService.activeWifiIf && NetworkService.activeWifiIf.length > 0)
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    const value = NetworkService.activeWifiIf || "";
                    if (value.length > 0) {
                      Os.copy(value);
                      ToastService.showNotice(I18n.tr("common.wifi"), I18n.tr("common.copied-to-clipboard"), "wifi");
                    }
                  }
                }
              }
            }
            // --- Item 4: IPv4 || IPv6 ---
            RowLayout {
              Layout.fillWidth: true
              Layout.preferredWidth: 1
              spacing: Style.marginXS
              NIcon {
                icon: "network"
                pointSize: Style.fontSizeXS
                color: Color.mOnSurface
              }
              NText {
                text: NetworkService.activeWifiDetails.ipv4 || "-"
                pointSize: Style.fontSizeXS
                color: Color.mOnSurface
                Layout.fillWidth: true

                MouseArea {
                  anchors.fill: parent
                  enabled: !!(NetworkService.activeWifiDetails.ipv4 && NetworkService.activeWifiDetails.ipv4.length > 0)
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    const value = NetworkService.activeWifiDetails.ipv4 || "";
                    if (value.length > 0) {
                      Os.copy(value);
                      ToastService.showNotice(I18n.tr("common.wifi"), I18n.tr("common.copied-to-clipboard"), "wifi");
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
