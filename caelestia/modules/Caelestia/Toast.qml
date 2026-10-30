import QtQuick

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

    property bool closed: false
    property string title: ""
    property string message: ""
    property string icon: ""
    property int timeout: 5000
    property int type: Toast.Info

    signal finishedClose

    property var _locks: []

    function close(): void {
        if (!closed)
            closed = true;
        if (_locks.length === 0)
            finishedClose();
    }

    function lock(sender: QtObject): void {
        if (_locks.includes(sender))
            return;
        _locks = [..._locks, sender];
        sender.destroyed.connect(() => unlock(sender));
    }

    function unlock(sender: QtObject): void {
        const had = _locks.includes(sender);
        _locks = _locks.filter(l => l !== sender);
        if (had && closed)
            close();
    }

    property Timer _timer: Timer {
        interval: root.timeout
        running: true
        onTriggered: root.close()
    }
}
