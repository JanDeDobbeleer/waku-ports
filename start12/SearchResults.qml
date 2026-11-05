import QtQuick
import waku.services as S

// Apps matching the search text, best first. Enter in the search box starts the first one.
Item {
    id: root

    property string query: ""
    readonly property var results: query === "" ? [] : S.AppsService.search(query, 40)
    readonly property var first: results.length > 0 ? results[0] : null

    signal launch(var entry)
    signal context(var entry, var point)

    Text {
        text: root.results.length > 0 ? "Best match" : "No apps match"
        color: Style.text
        font.family: Style.font
        font.pixelSize: Style.smallSize
        font.weight: Font.DemiBold
    }

    ListView {
        y: 28
        width: parent.width
        height: parent.height - 28
        clip: true
        model: root.results

        delegate: AppRow {
            required property var modelData
            required property int index
            width: ListView.view.width
            entry: modelData
            highlighted: index === 0
            onActivated: root.launch(modelData)
            onContextRequested: point => root.context(modelData, point)
        }
    }
}
