.pragma library

function unregisterComponent(registered, componentId) {
  delete registered[componentId];
}

function maxHistory(history) {
  return Math.max(...history);
}

function readDisks(root) {
    const percents = {};
    const avail = {};
    const used = {};
    const free = {};
    const size = {};
    const disks = root._diskSource ? (root._diskSource.disks || []) : [];
    const put = (key, d) => {
      percents[key] = d.percent;
      avail[key] = 100 - d.percent;
      used[key] = d.used / root._gib;
      free[key] = d.free / root._gib;
      size[key] = d.total / root._gib;
    };
    for (const d of disks)
      put(d.mount, d);
    const primary = root._diskSource ? root._diskSource.primaryDisk : null;
    if (primary && primary.mount !== undefined)
      put("/", primary);
    root.diskPercents = percents;
    root.diskAvailPercents = avail;
    root.diskUsedGb = used;
    root.diskAvailableGb = free;
    root.diskSizeGb = size;
    root.pushDiskHistory();
}

function formatSpeed(bytesPerSecond) {
    const units = ["KB", "MB", "GB"];
    let value = bytesPerSecond / 1000;
    let unitIndex = 0;

    while (value >= 1000 && unitIndex < units.length - 1) {
      value /= 1000;
      unitIndex++;
    }

    const unit = units[unitIndex];
    const shortUnit = unit[0];
    const numStr = value < 10 ? value.toFixed(1) : Math.round(value).toString();

    return (numStr + unit).length > 5 ? numStr + shortUnit : numStr + unit;
}

function formatGigabytesDisplay(root, memGb, maxGb = null) {
    const value = root.formatGigabytes(memGb === null ? 0 : memGb);
    if (maxGb !== null) {
      const padding = Math.max(4, root.formatGigabytes(maxGb).length);
      return value.padStart(padding, " ");
    }
    return value;
}

function formatPercentageDisplay(root, value, padding = false) {
    return `${Math.round(value === null ? 0 : value)}%`.padStart(padding ? 4 : 0, " ");
}

function formatDiskDisplay(root, diskPath, { percent = false, available = false, padding = false } = {}) {
    if (percent) {
      const raw = available ? root.diskAvailPercents[diskPath] : root.diskPercents[diskPath];
      return root.formatPercentageDisplay(raw, padding);
    } else {
      const rawGb = available ? root.diskAvailableGb[diskPath] : root.diskUsedGb[diskPath];
      const maxGb = padding ? root.diskSizeGb[diskPath] : null;
      return root.formatGigabytesDisplay(rawGb, maxGb);
    }
}

function formatRamDisplay(root, { swap = false, percent = false, padding = false } = {}) {
    if (percent) {
      const raw = swap ? root.swapPercent : root.memPercent;
      return root.formatPercentageDisplay(raw, padding);
    } else {
      const rawGb = swap ? root.swapGb : root.memGb;
      const maxGb = padding ? (swap ? root.swapTotalGb : root.memTotalGb) : null;
      return root.formatGigabytesDisplay(rawGb, maxGb);
    }
}

function lockScreenActive(lockScreen) {
  return lockScreen?.active ?? false;
}

function isDiskWarning(root, diskPath, available = false) {
  return available ? (root.diskAvailPercents[diskPath] || 0) <= root.diskAvailWarningThreshold : (root.diskPercents[diskPath] || 0) >= root.diskWarningThreshold;
}

function isDiskCritical(root, diskPath, available = false) {
  return available ? (root.diskAvailPercents[diskPath] || 0) <= root.diskAvailCriticalThreshold : (root.diskPercents[diskPath] || 0) >= root.diskCriticalThreshold;
}

function getDiskColor(root, Color, diskPath, available = false) {
  return root.isDiskCritical(diskPath, available) ? root.criticalColor : (root.isDiskWarning(diskPath, available) ? root.warningColor : Color.mPrimary);
}
