import QtQuick

// One launcher entry of an AppDb: the DesktopEntry plus its launch count. Mirrors the strings
// upstream search keys read (id, name, comment, execString, startupClass, genericName,
// categories, keywords). Only AppDb creates these.
QtObject {
    id: root

    final property QtObject entry
    final property int frequency: 0

    // waku gap: a QML type cannot declare a property named `id`, so upstream `entry.id` is `appId`.
    readonly final property string appId: entry?.id ?? ""
    readonly final property string name: entry?.name ?? ""
    readonly final property string comment: entry?.comment ?? ""
    readonly final property string execString: entry?.execString ?? ""
    readonly final property string startupClass: entry?.startupClass ?? ""
    readonly final property string genericName: entry?.genericName ?? ""
    readonly final property string categories: {
        const c = entry?.categories;
        return Array.isArray(c) ? c.join(" ") : (c ? String(c) : "");
    }
    readonly final property string keywords: {
        const k = entry?.keywords;
        return Array.isArray(k) ? k.join(" ") : (k ? String(k) : "");
    }

    function incrementFrequency(): void {
        frequency++;
    }
}
