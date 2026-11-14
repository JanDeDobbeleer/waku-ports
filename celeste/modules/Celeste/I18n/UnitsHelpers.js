.pragma library

function scaleBytes(bytes, referenceBytes, binary) {
    const units = binary ? ["B", "KiB", "MiB", "GiB", "TiB"] : ["B", "KB", "MB", "GB", "TB"];
    const base = binary ? 1024 : 1000;
    let value = isFinite(bytes) && bytes > 0 ? bytes : 0;
    let reference = isFinite(referenceBytes) && referenceBytes > 0 ? referenceBytes : 0;
    let index = 0;
    while (reference >= base && index < units.length - 1) {
        value /= base;
        reference /= base;
        index++;
    }
    return [value, units[index]];
}

function withDataUnit(value, unit, translation) {
    const labels = {
        "B": "%1 B", "KB": "%1 KB", "MB": "%1 MB", "GB": "%1 GB", "TB": "%1 TB",
        "KiB": "%1 KiB", "MiB": "%1 MiB", "GiB": "%1 GiB", "TiB": "%1 TiB",
        "B/s": "%1 B/s", "KB/s": "%1 KB/s", "MB/s": "%1 MB/s", "GB/s": "%1 GB/s", "TB/s": "%1 TB/s",
        "KiB/s": "%1 KiB/s", "MiB/s": "%1 MiB/s", "GiB/s": "%1 GiB/s", "TiB/s": "%1 TiB/s"
    };
    return translation.tr(labels[unit] || ("%1 " + unit)).arg(value);
}

function formatBytes(bytes, rate, binary, translation) {
    const scaled = scaleBytes(bytes, bytes, binary);
    const value = scaled[0];
    const unit = scaled[1];
    return withDataUnit(value.toFixed(value < 10 && unit !== "B" ? 1 : 0), unit + (rate ? "/s" : ""), translation);
}

function formatKibUsage(usedKib, totalKib, binary, translation) {
    const referenceBytes = totalKib * 1024;
    const used = scaleBytes(usedKib * 1024, referenceBytes, binary);
    const total = scaleBytes(referenceBytes, referenceBytes, binary);
    return translation.trCtx("%1 / %2", "used / total amount").arg(+used[0].toFixed(1)).arg(withDataUnit(+total[0].toFixed(1), total[1], translation));
}
