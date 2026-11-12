import QtQuick

QtObject {
    final property string name: ""
    final property int id: 0
    final property real handle: 0
    final property bool focused: false
    final property HyprWorkspace activeWorkspace: null
    // waku has no special workspaces.
    readonly final property string specialName: ""
    readonly final property int specialId: 0
}
