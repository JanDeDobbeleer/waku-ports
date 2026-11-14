pragma ComponentBehavior: Bound

import QtQuick 6.10
import QtQuick.Layouts
import Quickshell.Bluetooth

import qs.Commons
import qs.Services.Hardware
import qs.Services.Networking
import qs.Services.System
import qs.Widgets
import "BluetoothSubTab.js" as BluetoothData
import "../../SettingsValue.js" as SettingsValue

Item {
  id: root
  Layout.fillWidth: true
  implicitHeight: mainLayout.implicitHeight

  // Configuration for shared use (e.g. by BluetoothPanel)
  property bool showOnlyLists: false

  readonly property bool isScanningActive: BluetoothService.scanningActive
  readonly property bool isDiscoverable: BluetoothService.discoverable

  // Device lists with local filtering logic
  readonly property var connectedDevices: BluetoothData.connectedDevices(BluetoothService.adapter, BluetoothService)
  readonly property var pairedDevices: BluetoothData.pairedDevices(BluetoothService.adapter, BluetoothService)
  readonly property var unnamedAvailableDevices: BluetoothData.unnamedAvailableDevices(BluetoothService.adapter, BluetoothService)
  readonly property var availableDevices: BluetoothData.availableDevices(unnamedAvailableDevices, Settings.data.network.bluetoothHideUnnamedDevices, BluetoothService)

  // For managing expanded device details
  property string expandedDeviceKey: ""
  property bool detailsGrid: (Settings.data.network.bluetoothDetailsViewMode === "grid")

  // Combined visibility check: tab must be visible AND the window must be visible
  readonly property bool effectivelyVisible: root.visible && Window.window && SettingsValue.windowIsVisible(Window.window)

  Connections {
    target: BluetoothService
    function onEnabledChanged() {
      stateChangeDebouncer.restart();
    }
    function onDiscoverableChanged() {
      stateChangeDebouncer.restart();
    }
  }

  onEffectivelyVisibleChanged: stateChangeDebouncer.restart()

  Timer {
    id: stateChangeDebouncer
    interval: 100 // 100ms debounce
    repeat: false
    onTriggered: root._updateScanningState()
  }

  function _updateScanningState() {
    if (effectivelyVisible && BluetoothService.enabled && !showOnlyLists) {
      Logger.d("BluetoothPrefs", "Panel/tab active");
      if (!isScanningActive) {
        BluetoothService.setScanActive(true);
      }
      if (!Settings.data.network.disableDiscoverability && !isDiscoverable) {
        BluetoothService.setDiscoverable(true);
      }
    } else {
      Logger.d("BluetoothPrefs", "Panel/tab inactive");
      if (isScanningActive && !showOnlyLists) {
        BluetoothService.setScanActive(false);
      }
      if (isDiscoverable && !showOnlyLists) {
        BluetoothService.setDiscoverable(false);
      }
    }
  }

  Component.onDestruction: {
    // Ensure scanning is stopped when component is closed
    if (isScanningActive && !showOnlyLists) {
      BluetoothService.setScanActive(false);
    }
    // Ensure discoverable is disabled when component is closed
    if (isDiscoverable && !showOnlyLists) {
      BluetoothService.setDiscoverable(false);
    }
    Logger.d("BluetoothPrefs", "Panel closed");
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
            label: I18n.tr("common.bluetooth")
            icon: BluetoothService.enabled ? "bluetooth" : "bluetooth-off"
            checked: BluetoothService.enabled
            enabled: !NetworkService.airplaneModeEnabled && BluetoothService.bluetoothAvailable && !BluetoothService.blocked
            onToggled: checked => BluetoothService.setBluetoothEnabled(checked)
            Layout.alignment: Qt.AlignVCenter
          }
        }

        NDivider {
          Layout.fillWidth: true
          visible: BluetoothService.enabled && root.isDiscoverable
        }

        NText {
          visible: BluetoothService.enabled && root.isDiscoverable
          Layout.fillWidth: true
          text: I18n.trArgs("panels.connections.bluetooth-discoverable", {
                          hostName: HostService.hostName
                        })
          color: Color.mOnSurfaceVariant
          richTextEnabled: true
          wrapMode: Text.WordWrap
          horizontalAlignment: Text.AlignHCenter
        }
      }
    }

    Item {
      visible: !root.showOnlyLists
      Layout.fillWidth: true
    }

    // Device List [1] (Connected)
    NBox {
      id: connectedDevicesBox
      visible: BluetoothData.length(root.connectedDevices) > 0 && BluetoothService.enabled
      Layout.fillWidth: true
      Layout.preferredHeight: connectedDevicesCol.implicitHeight + Style.margin2M
      border.color: root.showOnlyLists ? Style.boxBorderColor : "transparent"
      color: root.showOnlyLists ? Color.mSurfaceVariant : "transparent"

      ColumnLayout {
        id: connectedDevicesCol
        anchors.fill: parent
        anchors.topMargin: Style.marginM
        anchors.bottomMargin: Style.marginM
        anchors.leftMargin: root.showOnlyLists ? Style.marginL : 0
        anchors.rightMargin: root.showOnlyLists ? Style.marginL : 0
        spacing: Style.marginM

        NLabel {
          label: I18n.tr("bluetooth.panel.connected-devices")
          Layout.fillWidth: true
          Layout.leftMargin: Style.marginS
        }

        Repeater {
          model: root.connectedDevices
          delegate: nboxDelegate
        }
      }
    }

    // Devices List [2] (Paired)
    NBox {
      id: pairedDevicesBox
      visible: BluetoothData.length(root.pairedDevices) > 0 && BluetoothService.enabled
      Layout.fillWidth: true
      Layout.preferredHeight: pairedDevicesCol.implicitHeight + Style.margin2M
      border.color: root.showOnlyLists ? Style.boxBorderColor : "transparent"
      color: root.showOnlyLists ? Color.mSurfaceVariant : "transparent"

      ColumnLayout {
        id: pairedDevicesCol
        anchors.fill: parent
        anchors.topMargin: Style.marginM
        anchors.bottomMargin: Style.marginM
        anchors.leftMargin: root.showOnlyLists ? Style.marginL : 0
        anchors.rightMargin: root.showOnlyLists ? Style.marginL : 0
        spacing: Style.marginM

        NLabel {
          label: I18n.tr("bluetooth.panel.paired-devices")
          Layout.fillWidth: true
          Layout.leftMargin: Style.marginS
        }

        Repeater {
          model: root.pairedDevices
          delegate: nboxDelegate
        }
      }
    }

    // Device List [3] (Available)
    NBox {
      id: availableDevicesBox
      visible: !root.showOnlyLists && BluetoothData.length(root.unnamedAvailableDevices) > 0 && BluetoothService.enabled
      Layout.fillWidth: true
      Layout.preferredHeight: availableDevicesCol.implicitHeight + Style.margin2M
      border.color: "transparent"
      color: root.showOnlyLists ? Color.mSurfaceVariant : "transparent"

      ColumnLayout {
        id: availableDevicesCol
        anchors.fill: parent
        anchors.topMargin: Style.marginM
        anchors.bottomMargin: Style.marginM
        spacing: Style.marginM

        RowLayout {
          Layout.fillWidth: true
          Layout.leftMargin: Style.marginS
          spacing: Style.marginS

          NLabel {
            label: I18n.tr("bluetooth.panel.available-devices")
            description: BluetoothService.scanningActive ? I18n.tr("bluetooth.panel.scanning") : ""
            Layout.fillWidth: true
          }
        }

        Repeater {
          model: root.availableDevices
          delegate: nboxDelegate
        }

        NText {
          visible: BluetoothData.length(root.availableDevices) === 0 && BluetoothData.length(root.unnamedAvailableDevices) > 0
          text: I18n.tr("panels.connections.bluetooth-devices-unnamed")
          pointSize: Style.fontSizeS
          color: Color.mOnSurfaceVariant
          horizontalAlignment: Text.AlignHCenter
          Layout.fillWidth: true
          Layout.margins: Style.marginL
        }
      }
    }

    Item {
      visible: !root.showOnlyLists
      Layout.fillWidth: true
    }

    NBox {
      id: miscSettingsBox
      visible: !root.showOnlyLists && BluetoothService.enabled
      Layout.fillWidth: true
      Layout.preferredHeight: miscSettingsCol.implicitHeight + Style.margin2XL
      color: Color.mSurface

      ColumnLayout {
        id: miscSettingsCol
        anchors.fill: parent
        anchors.margins: Style.marginXL
        spacing: Style.marginM

        NToggle {
          label: I18n.tr("panels.connections.bluetooth-auto-connect-label")
          description: I18n.tr("panels.connections.bluetooth-auto-connect-description")
          checked: Settings.data.network.bluetoothAutoConnect
          onToggled: checked => Settings.data.network.bluetoothAutoConnect = checked
        }

        NToggle {
          label: I18n.tr("panels.connections.hide-unnamed-devices-label")
          description: I18n.tr("panels.connections.hide-unnamed-devices-description")
          checked: Settings.data.network.bluetoothHideUnnamedDevices
          onToggled: checked => Settings.data.network.bluetoothHideUnnamedDevices = checked
        }

        NToggle {
          label: I18n.tr("panels.connections.disable-discoverability-label")
          description: I18n.tr("panels.connections.disable-discoverability-description")
          checked: Settings.data.network.disableDiscoverability
          onToggled: checked => {
                       Settings.data.network.disableDiscoverability = checked;
                       BluetoothService.setDiscoverable(!checked);
                     }
        }
      }
    }
  }

  // Shared Delegate
  Component {
    id: nboxDelegate
    NBox {
      required property var modelData
      id: device

      readonly property var devicePairing: BluetoothData.read(modelData, "pairing")
      readonly property var deviceState: BluetoothData.read(modelData, "state")
      readonly property var deviceConnected: BluetoothData.read(modelData, "connected")
      readonly property var deviceBlocked: BluetoothData.read(modelData, "blocked")
      readonly property var devicePaired: BluetoothData.read(modelData, "paired")
      readonly property var deviceTrusted: BluetoothData.read(modelData, "trusted")
      readonly property var deviceName: BluetoothData.deviceName(modelData)
      readonly property var deviceBatteryAvailable: BluetoothData.read(modelData, "batteryAvailable")
      readonly property var deviceAddress: BluetoothData.deviceAddress(modelData)

      readonly property bool canConnect: BluetoothService.canConnect(device.modelData)
      readonly property bool canDisconnect: BluetoothService.canDisconnect(device.modelData)
      readonly property bool canPair: BluetoothService.canPair(device.modelData)
      readonly property bool isBusy: BluetoothService.isDeviceBusy(device.modelData)
      readonly property bool isExpanded: root.expandedDeviceKey === BluetoothService.deviceKey(device.modelData)

      function getContentColors(defaultColors: list<color>): list<color> {
        return BluetoothData.contentColors(modelData, defaultColors, BluetoothDeviceState.Connecting, BluetoothDeviceState.Disconnecting, [Color.mPrimary, Color.mOnPrimary], [Color.mError, Color.mOnError]);
      }

      Layout.fillWidth: true
      Layout.preferredHeight: deviceColumn.implicitHeight + (Style.marginXL)
      radius: Style.radiusM
      clip: true
      forceOpaque: true
      color: device.getContentColors([Color.mSurface, Color.mOnSurface])[0]

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
            icon: BluetoothService.getDeviceIcon(device.modelData)
            pointSize: Style.fontSizeXXL
            color: device.getContentColors([Color.mSurface, Color.mOnSurface])[1]
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.marginXXS

            NText {
              text: device.deviceName
              pointSize: Style.fontSizeM
              font.weight: device.deviceConnected ? Style.fontWeightBold : Style.fontWeightMedium
              elide: Text.ElideRight
              color: device.getContentColors([Color.mSurface, Color.mOnSurface])[1]
              Layout.fillWidth: true
            }

            NText {
              text: {
                const k = BluetoothService.getStatusKey(device.modelData);
                if (k === "pairing")
                  return I18n.tr("common.pairing");
                if (k === "blocked")
                  return I18n.tr("bluetooth.panel.blocked");
                if (k === "connecting")
                  return I18n.tr("common.connecting");
                if (k === "disconnecting")
                  return I18n.tr("common.disconnecting");
                return "";
              }
              visible: text !== ""
              pointSize: Style.fontSizeXS
              color: Qt.alpha(device.getContentColors([Color.mSurfaceVariant, Color.mOnSurfaceVariant])[1], Style.opacityHeavy)
            }

            RowLayout {
              visible: device.deviceBatteryAvailable
              spacing: Style.marginS
              NIcon {
                icon: {
                  var b = BluetoothService.getBatteryPercent(device.modelData);
                  return BatteryService.getIcon(b !== null ? b : 0, false, false, b !== null);
                }
                pointSize: Style.fontSizeXS
                color: Qt.alpha(device.getContentColors([Color.mSurface, Color.mOnSurface])[1], Style.opacityHeavy)
              }
              NText {
                text: {
                  var b = BluetoothService.getBatteryPercent(device.modelData);
                  return b === null ? "-" : (b + "%");
                }
                pointSize: Style.fontSizeXS
                color: Qt.alpha(device.getContentColors([Color.mSurfaceVariant, Color.mOnSurfaceVariant])[1], Style.opacityHeavy)
              }
            }
          }

          Item {
            Layout.fillWidth: true
          }

          RowLayout {
            spacing: Style.marginS

            NBusyIndicator {
              visible: device.isBusy
              running: visible && root.effectivelyVisible
              color: device.getContentColors([Color.mSurface, Color.mOnSurface])[1]
              size: Style.baseWidgetSize * 0.5
            }

            NIconButton {
              visible: device.deviceConnected && device.deviceState !== BluetoothDeviceState.Disconnecting
              icon: "info"
              baseSize: Style.baseWidgetSize * 0.75
              colorBg: Color.mSurfaceVariant
              colorFg: Color.mOnSurface
              colorBorder: "transparent"
              colorBorderHover: "transparent"
              onClicked: {
                const key = BluetoothService.deviceKey(device.modelData);
                root.expandedDeviceKey = (root.expandedDeviceKey === key) ? "" : key;
              }
            }

            NIconButton {
              visible: !root.showOnlyLists && (device.devicePaired || device.deviceTrusted) && !device.deviceConnected && !device.isBusy && !device.deviceBlocked
              icon: "trash"
              baseSize: Style.baseWidgetSize * 0.75
              colorBg: Color.mPrimary
              colorFg: Color.mOnPrimary
              colorBorder: "transparent"
              colorBorderHover: "transparent"
              onClicked: BluetoothService.unpairDevice(device.modelData)
            }

            NButton {
              id: button
              visible: device.deviceState !== BluetoothDeviceState.Connecting && device.deviceState !== BluetoothDeviceState.Disconnecting
              enabled: (device.canConnect || device.canDisconnect || (root.showOnlyLists ? false : device.canPair)) && !device.isBusy
              fontSize: Style.fontSizeS
              backgroundColor: device.deviceConnected ? Color.mSurfaceVariant : Color.mPrimary
              textColor: device.deviceConnected ? Color.mOnSurface : Color.mOnPrimary
              text: {
                if (device.devicePairing)
                  return I18n.tr("common.pairing");
                if (device.deviceBlocked)
                  return I18n.tr("bluetooth.panel.blocked");
                if (device.deviceConnected)
                  return I18n.tr("common.disconnect");
                if (!root.showOnlyLists && device.canPair)
                  return I18n.tr("common.pair");
                return I18n.tr("common.connect");
              }
              onClicked: {
                if (device.deviceConnected) {
                  BluetoothService.disconnectDevice(device.modelData);
                } else {
                  if (!root.showOnlyLists && device.canPair) {
                    BluetoothService.pairDevice(device.modelData);
                  } else {
                    BluetoothService.connectDeviceWithTrust(device.modelData);
                  }
                }
              }
            }
          }
        }

        // Expanded info section
        Rectangle {
          visible: device.isExpanded
          Layout.fillWidth: true
          implicitHeight: infoColumn.implicitHeight + Style.margin2S
          radius: Style.radiusXS
          color: Color.mSurfaceVariant
          border.width: Style.borderS
          border.color: Style.boxBorderColor
          clip: true

          NIconButton {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: Style.marginS
            icon: root.detailsGrid ? "layout-list" : "layout-grid"
            baseSize: Style.baseWidgetSize * 0.65
            onClicked: {
              root.detailsGrid = !root.detailsGrid;
              Settings.data.network.bluetoothDetailsViewMode = root.detailsGrid ? "grid" : "list";
            }
            z: 1
          }

          GridLayout {
            id: infoColumn
            anchors.fill: parent
            anchors.margins: Style.marginS
            flow: root.detailsGrid ? GridLayout.TopToBottom : GridLayout.LeftToRight
            rows: root.detailsGrid ? 3 : 5
            columns: root.detailsGrid ? 2 : 1
            columnSpacing: Style.marginM
            rowSpacing: Style.marginXS

            // --- Item 2: Battery ---
            RowLayout {
              Layout.fillWidth: true
              Layout.preferredWidth: 1
              spacing: Style.marginXS
              NIcon {
                icon: {
                  var b = BluetoothService.getBatteryPercent(device.modelData);
                  return BatteryService.getIcon(b !== null ? b : 0, false, false, b !== null);
                }
                pointSize: Style.fontSizeXS
                color: Color.mOnSurface
              }
              NText {
                text: {
                  var b = BluetoothService.getBatteryPercent(device.modelData);
                  return b === null ? "-" : (b + "%");
                }
                pointSize: Style.fontSizeXS
                color: Color.mOnSurface
                Layout.fillWidth: true
              }
            }
            // --- Item 3: Pair state ---
            RowLayout {
              Layout.fillWidth: true
              Layout.preferredWidth: 1
              spacing: Style.marginXS
              NIcon {
                icon: "link"
                pointSize: Style.fontSizeXS
                color: Color.mOnSurface
              }
              NText {
                text: device.devicePaired ? I18n.tr("common.yes") : I18n.tr("common.no")
                pointSize: Style.fontSizeXS
                color: Color.mOnSurface
                Layout.fillWidth: true
              }
            }
            // --- Item 4: Trust state ---
            RowLayout {
              Layout.fillWidth: true
              Layout.preferredWidth: 1
              spacing: Style.marginXS
              NIcon {
                icon: "shield-check"
                pointSize: Style.fontSizeXS
                color: Color.mOnSurface
              }
              NText {
                text: device.deviceTrusted ? I18n.tr("common.yes") : I18n.tr("common.no")
                pointSize: Style.fontSizeXS
                color: Color.mOnSurface
                Layout.fillWidth: true
              }
            }
            // --- Item 5: Address ---
            RowLayout {
              Layout.fillWidth: true
              Layout.preferredWidth: 1
              spacing: Style.marginXS
              NIcon {
                icon: "hash"
                pointSize: Style.fontSizeXS
                color: Color.mOnSurface
              }
              NText {
                text: device.deviceAddress || "-"
                pointSize: Style.fontSizeXS
                color: Color.mOnSurface
                Layout.fillWidth: true
              }
            }
            // --- Item 6: Auto-connect ---
            RowLayout {
              Layout.fillWidth: true
              Layout.preferredWidth: 1
              Layout.topMargin: -Style.marginXXS
              spacing: Style.marginXS
              visible: Settings.data.network.bluetoothAutoConnect
              NIcon {
                icon: BluetoothService.getDeviceAutoConnect(device.modelData) ? "repeat" : "repeat-off"
                pointSize: Style.fontSizeXS
              }
              NCheckbox {
                label: I18n.tr("common.auto-connect")
                labelSize: Style.fontSizeXS
                baseSize: Style.baseWidgetSize * 0.5
                checked: BluetoothService.getDeviceAutoConnect(device.modelData)
                onToggled: checked => BluetoothService.setDeviceAutoConnect(device.modelData, checked)
              }
            }
          }
        }
      }
    }
  }
}
