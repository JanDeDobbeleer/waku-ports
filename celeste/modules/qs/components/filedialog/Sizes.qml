pragma Singleton

import QtQuick

// waku: Quickshell has no `Singleton` type here, so a plain QtObject singleton.
QtObject {
    final property int itemWidth: 103
    final property int sidebarWidth: 230
}
