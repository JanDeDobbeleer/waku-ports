pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Celeste.Config

// The tray icons the bar shows: the visible ones of SystemTray.items, or, in a test, `debugFake`
// fake items (see DebugIpc) so the layout can be checked without Explorer's hook.
Singleton {
    id: root

    // TEST ONLY: number of fake items that replace the real ones; 0 uses SystemTray.
    final property int debugFake: 0
    final property string lastAction: ""

    readonly final property var fakeNames: ["folder", "mail", "chat", "cloud", "headphones", "shield", "update", "bluetooth"]
    readonly final property var fakeItems: Array.from({
        length: debugFake
    }, (_, i) => fakeComp.createObject(root, {
            fakeIndex: i
        }))

    readonly final property var items: debugFake > 0 ? fakeItems : SystemTray.items.values.filter(i => i.status !== Status.Passive && !GlobalConfig.bar.tray.hiddenIcons.includes(i.id))
    readonly final property int count: items.length

    Component {
        id: fakeComp

        QtObject {
            required final property int fakeIndex
            readonly final property string id: `fake${fakeIndex}.exe`
            readonly final property string title: `Fake app ${fakeIndex + 1}`
            readonly final property string tooltipTitle: `Fake app ${fakeIndex + 1} tooltip`
            readonly final property string icon: ""
            readonly final property string fakeGlyph: root.fakeNames[fakeIndex % root.fakeNames.length]
            readonly final property int status: Status.Active

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
