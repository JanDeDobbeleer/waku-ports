import QtQuick
import Quickshell
import Quickshell.Widgets
import waku
import waku.services as S

// The Start menu, Pro style: the user and a search box on top, pinned apps and a widgets page on the
// left (two pages, paged with the dots), folders, Settings, Run and power on the right.
// It opens from the Start button, from `wakuc surface toggle startmenu` and from the key in keys.conf.
PanelWindow {
    id: menu

    // When the menu last closed. A click on the Start button first closes the menu (it loses focus),
    // then toggles; the guard stops that toggle from opening it again.
    property double hiddenAt: 0
    property string view: "pages"       // "pages" or "all"
    property int page: 0                // 0 pinned, 1 widgets
    readonly property int pageCount: 2
    property var contextEntry: null

    name: "startmenu"
    visible: false
    anchors.bottom: true
    margins.bottom: Style.barHeight + 6
    implicitWidth: Style.menuWidth
    implicitHeight: Style.menuHeight + Style.avatarSize / 2
    exclusionMode: ExclusionMode.Ignore
    layer: WlrLayer.Overlay
    keyboardFocus: WlrKeyboardFocus.OnDemand
    dismissOnEscape: true
    dismissOnBlur: true
    hideDelay: 100
    color: "transparent"

    function toggle() {
        if (visible)
            visible = false;
        else if (Date.now() - hiddenAt > 300)
            visible = true;
    }

    function close() {
        visible = false;
    }

    function launch(entry) {
        S.AppsService.launch(entry.id);
        close();
    }

    function openContext(entry, point) {
        contextEntry = entry;
        appMenu.x = Math.min(point.x, scene.width - appMenu.width - 8);
        appMenu.y = Math.min(point.y, scene.height - appMenu.height - 8);
        appMenu.visible = true;
    }

    function open(args) {
        Quickshell.execDetached(args);
        close();
    }

    onVisibleChanged: {
        if (visible) {
            search.text = "";
            view = "pages";
            page = 0;
            appMenu.visible = false;
            powerMenu.visible = false;
            search.forceActiveFocus();
        } else {
            hiddenAt = Date.now();
        }
    }

    Item {
        id: scene
        anchors.fill: parent

        Rectangle {
            id: card
            y: Style.avatarSize / 2
            width: parent.width
            height: Style.menuHeight
            radius: Style.menuRadius
            color: Style.menu
            border.color: Style.menuBorder
            border.width: 1

            // ---- left: search and pages ----
            Item {
                id: left
                width: Style.menuLeftWidth
                height: parent.height

                Rectangle {
                    id: field
                    x: 24
                    y: 28
                    width: parent.width - 48
                    height: 40
                    radius: 20
                    color: Style.field

                    Glyph {
                        x: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: ""
                        size: 14
                    }
                    TextInput {
                        id: search
                        x: 42
                        width: parent.width - 56
                        anchors.verticalCenter: parent.verticalCenter
                        color: Style.text
                        selectionColor: Style.accent
                        font.family: Style.font
                        font.pixelSize: Style.fontSize
                        clip: true
                        onAccepted: if (results.first)
                            menu.launch(results.first)
                    }
                    Text {
                        x: 42
                        anchors.verticalCenter: parent.verticalCenter
                        visible: search.text === ""
                        text: "Search apps"
                        color: Style.faint
                        font.family: Style.font
                        font.pixelSize: Style.fontSize
                    }
                }

                Item {
                    id: area
                    x: 24
                    y: 84
                    width: parent.width - 48
                    height: parent.height - 84 - 44

                    PinnedPage {
                        anchors.fill: parent
                        visible: search.text === "" && menu.view === "pages" && menu.page === 0
                        onLaunch: entry => menu.launch(entry)
                        onContext: (entry, point) => menu.openContext(entry, point)
                        onShowAll: menu.view = "all"
                    }
                    Loader {
                        anchors.fill: parent
                        active: menu.visible && menu.page === 1
                        visible: search.text === "" && menu.view === "pages" && menu.page === 1
                        sourceComponent: WidgetsPage {
                            onRan: menu.close()
                        }
                    }
                    AllAppsList {
                        anchors.fill: parent
                        visible: search.text === "" && menu.view === "all"
                        onLaunch: entry => menu.launch(entry)
                        onContext: (entry, point) => menu.openContext(entry, point)
                        onBack: menu.view = "pages"
                    }
                    SearchResults {
                        id: results
                        anchors.fill: parent
                        visible: search.text !== ""
                        query: search.text
                        onLaunch: entry => menu.launch(entry)
                        onContext: (entry, point) => menu.openContext(entry, point)
                    }
                }

                // The pager: previous, one dot per page, next.
                Row {
                    visible: search.text === "" && menu.view === "pages"
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height - 34
                    spacing: 8

                    IconButton {
                        size: 20
                        glyphSize: 8
                        glyph: ""
                        opacity: menu.page > 0 ? 1 : 0.35
                        onClicked: menu.page = Math.max(0, menu.page - 1)
                    }
                    Repeater {
                        model: menu.pageCount
                        Rectangle {
                            required property int index
                            anchors.verticalCenter: parent.verticalCenter
                            width: index === menu.page ? 8 : 6
                            height: width
                            radius: width / 2
                            color: index === menu.page ? Style.text : Style.faint
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -4
                                onClicked: menu.page = parent.index
                            }
                        }
                    }
                    IconButton {
                        size: 20
                        glyphSize: 8
                        glyph: ""
                        opacity: menu.page < menu.pageCount - 1 ? 1 : 0.35
                        onClicked: menu.page = Math.min(menu.pageCount - 1, menu.page + 1)
                    }
                }
            }

            // ---- right: the user and the shortcuts ----
            Rectangle {
                id: right
                x: left.width
                width: parent.width - left.width
                height: parent.height
                color: Style.menuRight
                topRightRadius: Style.menuRadius
                bottomRightRadius: Style.menuRadius

                Text {
                    id: userName
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: Style.avatarSize / 2 + 18
                    text: S.ControlCenter.userName
                    color: Style.text
                    font.family: Style.display
                    font.pixelSize: 22
                }

                Flickable {
                    x: 8
                    y: userName.y + 52
                    width: parent.width - 16
                    height: parent.height - y - 64
                    contentHeight: shortcuts.implicitHeight
                    clip: true
                    interactive: contentHeight > height

                    Column {
                        id: shortcuts
                        width: parent.width

                        ShortcutRow {
                            width: parent.width
                            glyph: ""
                            label: "Documents"
                            onClicked: menu.open(["explorer.exe", "shell:Personal"])
                        }
                        ShortcutRow {
                            width: parent.width
                            glyph: ""
                            label: "Downloads"
                            onClicked: menu.open(["explorer.exe", "shell:Downloads"])
                        }
                        ShortcutRow {
                            width: parent.width
                            glyph: ""
                            label: "Music"
                            onClicked: menu.open(["explorer.exe", "shell:My Music"])
                        }
                        ShortcutRow {
                            width: parent.width
                            glyph: ""
                            label: "Pictures"
                            onClicked: menu.open(["explorer.exe", "shell:My Pictures"])
                        }
                        ShortcutRow {
                            width: parent.width
                            glyph: ""
                            label: S.ControlCenter.userName
                            onClicked: menu.open(["explorer.exe", "shell:Profile"])
                        }
                        ShortcutRow {
                            width: parent.width
                            glyph: ""
                            label: "Control Panel"
                            onClicked: menu.open(["control.exe"])
                        }
                        ShortcutRow {
                            width: parent.width
                            glyph: ""
                            label: "Settings"
                            onClicked: menu.open(["cmd.exe", "/c", "start", "", "ms-settings:"])
                        }
                        ShortcutRow {
                            width: parent.width
                            glyph: ""
                            label: "Run…"
                            onClicked: menu.open(["rundll32.exe", "shell32.dll,#61"])
                        }
                    }
                }

                IconButton {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height - 52
                    size: 36
                    glyphSize: 18
                    glyph: ""
                    onClicked: powerMenu.visible = !powerMenu.visible
                }
            }
        }

        // The avatar sits on the top edge of the card, over both columns.
        ClippingRectangle {
            id: avatar
            x: left.width + (Style.menuWidth - left.width) / 2 - width / 2
            y: 0
            width: Style.avatarSize
            height: Style.avatarSize
            radius: width / 2
            color: Style.accent

            Image {
                anchors.fill: parent
                visible: source != ""
                source: S.ControlCenter.avatarUrl
                fillMode: Image.PreserveAspectCrop
                smooth: true
            }
            Text {
                anchors.centerIn: parent
                visible: S.ControlCenter.avatarUrl === ""
                text: S.ControlCenter.userName.charAt(0).toUpperCase()
                color: "#0b1b2b"
                font.family: Style.display
                font.pixelSize: 36
            }
        }

        // A click outside an open menu closes it.
        MouseArea {
            anchors.fill: parent
            visible: appMenu.visible || powerMenu.visible
            onClicked: {
                appMenu.visible = false;
                powerMenu.visible = false;
            }
        }

        AppMenu {
            id: appMenu
            visible: false
            entry: menu.contextEntry
            onDone: visible = false
        }

        PowerMenu {
            id: powerMenu
            visible: false
            x: scene.width - width - 16
            y: card.y + card.height - 62 - height
            onDone: {
                visible = false;
                menu.close();
            }
        }
    }
}
