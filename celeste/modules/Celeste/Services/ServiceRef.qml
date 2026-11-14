import QtQuick
import "ServiceRefHelpers.js" as ServiceRefHelpers

// Port of celeste's ServiceRef: holds a reference on a stat service while this object lives.
// The services start polling on the first reference and stop on the last.
QtObject {
    id: root

    final property var service
    final property var _held: null

    onServiceChanged: {
        ServiceRefHelpers.release(_held);
        _held = service ?? null;
        ServiceRefHelpers.acquire(_held);
    }

    Component.onDestruction: {
        ServiceRefHelpers.release(_held);
        _held = null;
    }
}
