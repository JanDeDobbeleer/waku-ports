pragma Singleton

import QtQuick

// SMOKE STUB: no player. Replaced by the real qs.services Players in work package 4.
QtObject {
    readonly property var active: null

    function getArtUrl(player: var): string {
        return "";
    }
}
