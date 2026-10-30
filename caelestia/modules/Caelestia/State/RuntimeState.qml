pragma Singleton

import QtQuick

// Port of upstream RuntimeState: values that live until the shell exits (upstream keeps them in a
// runtime dir so other processes can read them; the port keeps them in memory).
QtObject {
    property bool gameMode: false
    property bool inhibitIdle: false
    property real inhibitingIdleSince: -1
}
