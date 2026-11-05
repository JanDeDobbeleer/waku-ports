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

    readonly property var disks: {
        const list = src.disks ?? [];
        return list.map(d => ({
                    mount: d.mount,
                    used: d.used / 1024,
                    total: d.total / 1024,
                    free: d.free / 1024,
                    perc: d.perc / 100,
                    hasRoot: d.hasRoot
                }));
    }
    readonly property var primaryDisk: disks.find(d => d.mount === _manualMount) ?? disks.find(d => d.hasRoot) ?? disks[0] ?? null
    readonly property real percentage: primaryDisk ? primaryDisk.perc : 0

    readonly property var src: S.Disks {
        active: root.refs > 0
        interval: Math.max(5000, GlobalConfig.dashboard.resourceUpdateInterval)
    }
}
