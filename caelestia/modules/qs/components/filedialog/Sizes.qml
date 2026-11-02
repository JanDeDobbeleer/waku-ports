pragma Singleton

import QtQuick

// waku: Quickshell has no `Singleton` type here, so a plain QtObject singleton.
QtObject {
    property int itemWidth: 103
    property int sidebarWidth: 230
}
