pragma Singleton

import QtQuick

// Port of upstream RuntimeState: values that live until the shell exits (upstream keeps them in a
// runtime dir so other processes can read them; the port keeps them in memory).
QtObject {
    final property bool gameMode: false
    final property bool inhibitIdle: false
    final property real inhibitingIdleSince: -1
}
