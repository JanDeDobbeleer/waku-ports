.pragma library

function percentage(disk) { return disk ? disk.perc : 0; }
function usageText(disk, units, translation) {
    return disk ? units.formatKibUsage(disk.used, disk.total) : translation.tr("No disks detected");
}
function hasDisks(disks) { return disks.length > 0; }
function activeItem(items, primaryDisk) {
    const primaryMount = primaryDisk ? primaryDisk.mount : "";
    for (let i = 0; i < items.length; i++) {
        if (items[i].modelData.mount === primaryMount)
            return items[i];
    }
    return items.length > 0 ? items[0] : null;
}
function selectDisk(storage, item) { storage.manualPrimaryDisk = item.modelData; }
function diskIcon(disk, primaryDisk) {
    return primaryDisk && disk.mount === primaryDisk.mount ? "check" : "";
}
function mount(disk) { return disk.mount; }
