pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Celeste
import Celeste.Config
import waku.services as S

// Port of celeste's Storage over waku's Disks source. disks is a list of plain objects with
// mount, used, total, free (KiB), perc (0..1) and hasRoot. manualPrimaryDisk takes one of them;
// it is kept by mount so a refresh does not drop the choice.
QtObject {
    id: root

    // Reference count driven by ServiceRef. The waku source polls only while something holds a ref.
    property int refs: 0
    function ref(): void {
        refs++;
    }
    function unref(): void {
        refs = Math.max(0, refs - 1);
    }
    property var manualPrimaryDisk: null
    property string _manualMount: ""
    onManualPrimaryDiskChanged: _manualMount = manualPrimaryDisk ? manualPrimaryDisk.mount : ""

    // Port: the list is replaced on every poll. Anything built from it (the drive menu's items)
    // is torn down and rebuilt each time, which closes an open menu. So the list is replaced only
    // when the set of drives changes; the usage numbers are updated in place on the same objects.
    property var disks: []
    readonly property var _srcDisks: src.disks
    function _refresh(): void {
        const list = _srcDisks ?? [];
        const same = list.length === disks.length && list.every((d, i) => d.mount === disks[i].mount && d.hasRoot === disks[i].hasRoot);
        if (!same) {
            disks = list.map(d => ({
                        mount: d.mount,
                        used: d.used / 1024,
                        total: d.total / 1024,
                        free: d.free / 1024,
                        perc: d.perc / 100,
                        hasRoot: d.hasRoot
                    }));
            return;
        }
        list.forEach((d, i) => {
            disks[i].used = d.used / 1024;
            disks[i].total = d.total / 1024;
            disks[i].free = d.free / 1024;
            disks[i].perc = d.perc / 100;
        });
        usageTick++;
    }
    property int usageTick: 0
    on_SrcDisksChanged: _refresh()
    Component.onCompleted: _refresh()
    // A copy, re-made on each usage update (usageTick), so bindings that read its numbers refresh.
    readonly property var primaryDisk: {
        usageTick;
        const d = disks.find(d => d.mount === _manualMount) ?? disks.find(d => d.hasRoot) ?? disks[0];
        return d ? Object.assign({}, d) : null;
    }
    readonly property real percentage: primaryDisk ? primaryDisk.perc : 0

    readonly property var src: S.Disks {
        active: root.refs > 0
        interval: Math.max(5000, GlobalConfig.dashboard.resourceUpdateInterval)
    }
}
