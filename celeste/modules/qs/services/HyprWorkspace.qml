import QtQuick

QtObject {
    final property int id: 0
    final property string key: ""
    final property string name: ""
    final property HyprMonitor monitor: null
    final property bool active: false
    final property bool focused: false
    // HyprToplevel objects.
    final property var toplevels: []
}
