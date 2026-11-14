import QtQuick

// The windows of one application, for the apps list.
QtObject {
    final property string key: ""
    final property string exe: ""
    // HyprToplevel objects.
    final property var windows: []
    final property string icon: ""
    final property string iconUrl: ""
    final property string progressState: "none"
    final property real progress: 0
}
