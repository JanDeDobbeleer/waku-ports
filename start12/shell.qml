// Start12: a Start11-style taskbar and Start menu for waku. See README.md.
import QtQuick
import waku

ShellRoot {
    StartMenu {
        id: startMenu
    }

    BarWindow {
        startMenu: startMenu
    }
}
