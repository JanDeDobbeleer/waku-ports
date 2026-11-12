import QtQuick

// One window, in the shape of Quickshell's HyprlandToplevel. `appClass` is the executable name
// without ".exe" (Hyprland's window class).
QtObject {
    final property string title: ""
    final property string address: ""
    final property string srcHwnd: ""
    final property int wsId: 0
    final property int monId: 0
    final property bool wsActive: false
    final property bool minimized: false
    final property string progressState: "none"
    final property real progress: 0
    final property HyprWorkspace workspace: null
    final property string iconUrl: ""
    final property string icon: ""
    final property string appClass: ""
    final property string windowClass: ""
    final property int fullscreen: 0
}
