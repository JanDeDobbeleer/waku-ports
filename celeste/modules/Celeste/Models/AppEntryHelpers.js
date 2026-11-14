.pragma library

function field(entry, name) {
    if (!entry)
        return "";
    const value = entry[name];
    return value === undefined || value === null ? "" : String(value);
}

function joinProperty(entry, name) {
    if (!entry)
        return "";
    const value = entry[name];
    if (Array.isArray(value))
        return value.join(" ");
    return value ? String(value) : "";
}
