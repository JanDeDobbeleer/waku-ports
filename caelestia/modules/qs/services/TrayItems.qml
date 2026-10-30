pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Caelestia.Config

// The tray icons the bar shows: the visible ones of SystemTray.items, or, in a test, `debugFake`
// fake items (see DebugIpc) so the layout can be checked without Explorer's hook.
Singleton {
    id: root

    // TEST ONLY: number of fake items that replace the real ones; 0 uses SystemTray.
    property int debugFake: 0
    property string lastAction: ""

    readonly property var fakeNames: ["folder", "mail", "chat", "cloud", "headphones", "shield", "update", "bluetooth"]
    readonly property var fakeItems: Array.from({
        length: debugFake
    }, (_, i) => fakeComp.createObject(root, {
            fakeIndex: i
        }))

    readonly property var items: debugFake > 0 ? fakeItems : SystemTray.items.values.filter(i => i.status !== Status.Passive && !GlobalConfig.bar.tray.hiddenIcons.includes(i.id))
    readonly property int count: items.length

    Component {
        id: fakeComp

        QtObject {
            required property int fakeIndex
            readonly property string id: `fake${fakeIndex}.exe`
            readonly property string title: `Fake app ${fakeIndex + 1}`
            readonly property string tooltipTitle: `Fake app ${fakeIndex + 1} tooltip`
            readonly property string icon: ""
            readonly property string fakeGlyph: root.fakeNames[fakeIndex % root.fakeNames.length]
            readonly property int status: Status.Active

            function activate(): void {
                root.lastAction = `activate ${id}`;
            }
            function secondaryActivate(): void {
                root.lastAction = `secondaryActivate ${id}`;
            }
            function display(win: var, x: real, y: real): void {
                root.lastAction = `display ${id}`;
            }
        }
    }
}
