import QtQuick

// A wired adapter, as {name, type, connected}.
QtObject {
    property string name: ""
    readonly property int type: DeviceType.Wired
    property bool connected: false
    readonly property var networks: ({ values: [] })
    property bool scannerEnabled: false
}
