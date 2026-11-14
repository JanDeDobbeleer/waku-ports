import QtQuick
import "ToastHelpers.js" as ToastHelpers

// Port of upstream Toast. Made by Toaster.toast(); stays queued until it is closed and every
// holder released its lock (a toast delegate locks it while it plays its close animation).
QtObject {
    id: root

    enum Type {
        Info,
        Success,
        Warning,
        Error
    }

    final property bool closed: false
    final property string title: ""
    final property string message: ""
    final property string icon: ""
    final property int timeout: 5000
    final property int type: Toast.Info

    signal finishedClose

    final property var _locks: []

    function close(): void { ToastHelpers.close(root); }
    function lock(sender: QtObject): void { ToastHelpers.lock(root, sender); }
    function unlock(sender: QtObject): void { ToastHelpers.unlock(root, sender); }

    final property Timer _timer: Timer {
        interval: root.timeout
        running: true
        onTriggered: root.close()
    }
}
