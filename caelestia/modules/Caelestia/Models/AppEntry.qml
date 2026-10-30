import QtQuick

// One launcher entry of an AppDb: the DesktopEntry plus its launch count. Mirrors the strings
// upstream search keys read (id, name, comment, execString, startupClass, genericName,
// categories, keywords). Only AppDb creates these.
QtObject {
    id: root

    property QtObject entry
    property int frequency: 0

    // wabar gap: a QML type cannot declare a property named `id`, so upstream `entry.id` is `appId`.
    readonly property string appId: entry?.id ?? ""
    readonly property string name: entry?.name ?? ""
    readonly property string comment: entry?.comment ?? ""
    readonly property string execString: entry?.execString ?? ""
    readonly property string startupClass: entry?.startupClass ?? ""
    readonly property string genericName: entry?.genericName ?? ""
    readonly property string categories: {
        const c = entry?.categories;
        return Array.isArray(c) ? c.join(" ") : (c ? String(c) : "");
    }
    readonly property string keywords: {
        const k = entry?.keywords;
        return Array.isArray(k) ? k.join(" ") : (k ? String(k) : "");
    }

    function incrementFrequency(): void {
        frequency++;
    }
}
