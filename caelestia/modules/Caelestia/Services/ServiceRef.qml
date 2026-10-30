import QtQuick

// Port of caelestia's ServiceRef: holds a reference on a stat service while this object lives.
// The services start polling on the first reference and stop on the last.
QtObject {
    id: root

    property var service
    property var _held: null

    onServiceChanged: {
        if (_held && _held.unref)
            _held.unref();
        _held = service ?? null;
        if (_held && _held.ref)
            _held.ref();
    }

    Component.onDestruction: {
        if (_held && _held.unref)
            _held.unref();
        _held = null;
    }
}
