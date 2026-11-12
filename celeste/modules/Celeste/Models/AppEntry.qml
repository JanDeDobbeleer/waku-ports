import QtQuick
import "AppEntryHelpers.js" as AppEntryHelpers

// One launcher entry of an AppDb: the DesktopEntry plus its launch count. Mirrors the strings
// upstream search keys read (id, name, comment, execString, startupClass, genericName,
// categories, keywords). Only AppDb creates these.
QtObject {
    id: root

    final property QtObject entry
    final property int frequency: 0

    // waku gap: a QML type cannot declare a property named `id`, so upstream `entry.id` is `appId`.
    readonly final property string appId: AppEntryHelpers.field(entry, "id")
    readonly final property string name: AppEntryHelpers.field(entry, "name")
    readonly final property string comment: AppEntryHelpers.field(entry, "comment")
    readonly final property string execString: AppEntryHelpers.field(entry, "execString")
    readonly final property string startupClass: AppEntryHelpers.field(entry, "startupClass")
    readonly final property string genericName: AppEntryHelpers.field(entry, "genericName")
    readonly final property string categories: AppEntryHelpers.joinProperty(entry, "categories")
    readonly final property string keywords: AppEntryHelpers.joinProperty(entry, "keywords")

    function incrementFrequency(): void {
        frequency++;
    }
}
