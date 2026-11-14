.pragma library

function disks(source) {
    return source.disks;
}

function mount(disk) {
    return disk ? disk.mount : "";
}

function refresh(root, sourceDisks) {
    const list = sourceDisks || [];
    const disks = root.disks;
    let same = list.length === disks.length;
    for (let i = 0; same && i < list.length; i++)
        same = list[i].mount === disks[i].mount && list[i].hasRoot === disks[i].hasRoot;

    if (!same) {
        const updated = [];
        for (let i = 0; i < list.length; i++) {
            const disk = list[i];
            updated.push({
                mount: disk.mount,
                used: disk.used / 1024,
                total: disk.total / 1024,
                free: disk.free / 1024,
                perc: disk.perc / 100,
                hasRoot: disk.hasRoot
            });
        }
        root.disks = updated;
        return;
    }

    for (let i = 0; i < list.length; i++) {
        disks[i].used = list[i].used / 1024;
        disks[i].total = list[i].total / 1024;
        disks[i].free = list[i].free / 1024;
        disks[i].perc = list[i].perc / 100;
    }
    root.usageTick++;
}

function primaryDisk(disks, manualMount, usageTick) {
    if (usageTick < 0)
        return null;
    let disk = null;
    for (let i = 0; i < disks.length; i++) {
        if (disks[i].mount === manualMount) {
            disk = disks[i];
            break;
        }
    }
    if (!disk) {
        for (let i = 0; i < disks.length; i++) {
            if (disks[i].hasRoot) {
                disk = disks[i];
                break;
            }
        }
    }
    if (!disk)
        disk = disks[0];
    return disk ? Object.assign({}, disk) : null;
}

function percentage(disk) {
    return disk ? disk.perc : 0;
}
