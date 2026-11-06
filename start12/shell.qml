// Start12: a Start11-style taskbar and Start menu for waku. See README.md.
import QtQuick
import waku
import waku.services as S

ShellRoot {
    // The built-in waku tiler is the default on every port (keys.conf drives it). It tiles inside the
    // work area, which the taskbar's exclusive zone keeps clear.
    Component.onCompleted: {
        S.Tiling.layout = "mainStack";
        S.Tiling.gap = 8;
        S.Tiling.ratio = 0.5;
        S.Tiling.enabled = true;
    }

    StartMenu {
        id: startMenu
    }

    BarWindow {
        startMenu: startMenu
    }
}
