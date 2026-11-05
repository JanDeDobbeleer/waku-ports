pragma Singleton
import QtQuick

// Design tokens of the Start12 look, measured from Stardock's published Start11 v3 screenshots
// (1920x1080, 100% scale). `measured` values come from pixels; `guessed` ones are noted.
QtObject {
    // Taskbar islands: 48 px tall, 3 px above the screen edge, 1 px light border. measured
    readonly property int islandHeight: 48
    readonly property int islandGap: 3
    readonly property int islandRadius: 8                 // guessed from the corner curve
    readonly property int barHeight: islandHeight + 2 * islandGap
    readonly property color island: "#e6141b30"            // fill #18223f over a wallpaper; alpha guessed
    readonly property color islandBorder: "#38ffffff"      // measured #2c3750 over #17233f

    // Start menu (Pro style): 725 x 586 in the screenshot. measured
    readonly property int menuWidth: 700
    readonly property int menuHeight: 580
    readonly property int menuLeftWidth: 450
    readonly property int menuRadius: 8
    readonly property int avatarSize: 86                   // measured
    readonly property color menu: "#f21b273b"              // measured #1b273b
    readonly property color menuRight: "#24000000"         // the right column reads slightly darker
    readonly property color menuBorder: "#26ffffff"        // guessed
    readonly property color field: "#000000"               // measured: the search field is pure black
    readonly property color tile: "#14ffffff"
    readonly property color hover: "#1fffffff"
    readonly property color pressed: "#14ffffff"

    readonly property color text: "#ffffff"
    readonly property color dim: "#b3ffffff"
    readonly property color faint: "#73ffffff"
    readonly property color accent: "#4cc2ff"              // guessed (Windows 11 dark accent)
    readonly property color warn: "#ff9d3b"                // the memory ring in the screenshot
    readonly property color good: "#2fb8a0"
    readonly property color net: "#9b6fd1"

    readonly property string font: "Segoe UI Variable Text"
    readonly property string display: "Segoe UI Variable Display"
    readonly property string iconFont: "Segoe Fluent Icons"
    readonly property int fontSize: 12
    readonly property int smallSize: 11
}
