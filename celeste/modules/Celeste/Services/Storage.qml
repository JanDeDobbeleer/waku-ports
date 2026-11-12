pragma Singleton

import QtQuick
import Celeste.Config
import waku.services as S
import "StorageHelpers.js" as StorageHelpers

// Port of celeste's Storage over waku's Disks source. disks is a list of plain objects with
// mount, used, total, free (KiB), perc (0..1) and hasRoot. manualPrimaryDisk takes one of them;
// it is kept by mount so a refresh does not drop the choice.
QtObject {
    id: root

    // Reference count driven by ServiceRef. The waku source polls only while something holds a ref.
    final property int refs: 0
    function ref(): void {
        refs++;
    }
    function unref(): void {
        refs = Math.max(0, refs - 1);
    }
    final property var manualPrimaryDisk: null
    final property string _manualMount: ""
    onManualPrimaryDiskChanged: _manualMount = StorageHelpers.mount(manualPrimaryDisk)

    // Port: the list is replaced on every poll. Anything built from it (the drive menu's items)
    // is torn down and rebuilt each time, which closes an open menu. So the list is replaced only
    // when the set of drives changes; the usage numbers are updated in place on the same objects.
    final property var disks: []
    readonly final property var _srcDisks: StorageHelpers.disks(src)
    function _refresh(): void {
        StorageHelpers.refresh(root, _srcDisks)
    }
    final property int usageTick: 0
    on_SrcDisksChanged: _refresh()
    Component.onCompleted: _refresh()
    // A copy, re-made on each usage update (usageTick), so bindings that read its numbers refresh.
    readonly final property var primaryDisk: StorageHelpers.primaryDisk(disks, _manualMount, usageTick)
    readonly final property real percentage: StorageHelpers.percentage(primaryDisk)

    readonly final property S.Disks src: S.Disks {
        active: root.refs > 0
        interval: Math.max(5000, GlobalConfig.dashboard.resourceUpdateInterval)
    }
}
