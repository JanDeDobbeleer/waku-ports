pragma ComponentBehavior: Bound

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Celeste.Config
import "TrayItemsHelpers.js" as TrayItemsHelpers

// The tray icons the bar shows: the visible ones of SystemTray.items, or, in a test, `debugFake`
// fake items (see DebugIpc) so the layout can be checked without Explorer's hook.
Singleton {
    id: root

    // TEST ONLY: number of fake items that replace the real ones; 0 uses SystemTray.
    final property int debugFake: 0
    final property string lastAction: ""

    readonly final property var fakeNames: ["folder", "mail", "chat", "cloud", "headphones", "shield", "update", "bluetooth"]
    readonly final property var fakeItems: TrayItemsHelpers.fakeItems(root, debugFake, fakeComp)

    readonly final property var items: TrayItemsHelpers.items(debugFake, fakeItems, SystemTray, GlobalConfig.bar.tray, Status.Passive)
    readonly final property int count: TrayItemsHelpers.count(items)

    Component {
        id: fakeComp

        QtObject {
            required final property int fakeIndex
            readonly final property string id: `fake${fakeIndex}.exe`
            readonly final property string title: `Fake app ${fakeIndex + 1}`
            readonly final property string tooltipTitle: `Fake app ${fakeIndex + 1} tooltip`
            readonly final property string icon: ""
            readonly final property string fakeGlyph: TrayItemsHelpers.fakeGlyph(root, fakeIndex)
            readonly final property int status: Status.Active

            function activate(): void {
                TrayItemsHelpers.record(root, id, "activate");
            }
            function secondaryActivate(): void {
                TrayItemsHelpers.record(root, id, "secondaryActivate");
            }
            function display(win: var, x: real, y: real): void {
                TrayItemsHelpers.record(root, id, "display");
            }
        }
    }
}
