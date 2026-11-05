import QtQuick

// Port of celeste's C++ ButtonRow: lays children out in a row, shares the height, and gives
// children with `fillWidth` the remaining width. Children may expose `shapeMorphExpansion`
// (a pressed button grows and pushes its neighbours). `signature` reads every input the layout
// depends on, so a change in a child's implicitWidth, implicitHeight, visible, fillWidth or
// shapeMorphExpansion, or in this item's width or spacing, schedules one relayout (like polish).
Item {
    id: root

    property real spacing: 0

    readonly property string signature: {
        let s = `${width}|${spacing}`;
        for (let i = 0; i < children.length; i++) {
            const c = children[i];
            s += `|${c.visible}:${c.implicitWidth}:${c.implicitHeight}:${c.fillWidth}:${c.shapeMorphExpansion}`;
        }
        return s;
    }

    onSignatureChanged: Qt.callLater(relayout)
    Component.onCompleted: Qt.callLater(relayout)

    function isRepeater(item: Item): bool {
        return item.delegate !== undefined && item.model !== undefined && item.count !== undefined;
    }

    function morph(item: Item): real {
        return item.shapeMorphExpansion ?? 0;
    }

    function relayout(): void {
        const kids = [];
        for (let i = 0; i < children.length; i++) {
            const c = children[i];
            if (c.visible && !isRepeater(c))
                kids.push(c);
        }
        const n = kids.length;
        const totalSpacing = (n - 1) * spacing;

        let reserved = 0, unreserved = 0, fillCount = 0, maxHeight = 0;
        for (const c of kids) {
            maxHeight = Math.max(maxHeight, c.implicitHeight);
            if (c.fillWidth === undefined)
                continue;
            if (c.fillWidth) {
                fillCount++;
                unreserved += c.implicitWidth;
            } else {
                reserved += c.implicitWidth;
            }
        }
        if (fillCount === 0)
            fillCount = 1;
        const perItem = (width - totalSpacing - reserved) / fillCount;

        const base = kids.map(c => c.fillWidth ? perItem : c.implicitWidth);
        let acc = 0;
        for (let i = 0; i < n; i++) {
            let prev = i > 0 ? morph(kids[i - 1]) : 0;
            let next = i < n - 1 ? morph(kids[i + 1]) : 0;
            // Items at the edges push by the full amount, items in the middle by half.
            if (i > 1)
                prev /= 2;
            if (i < n - 2)
                next /= 2;
            const c = kids[i];
            c.width = base[i] + morph(c) - prev - next;
            c.height = maxHeight;
            c.x = acc;
            c.y = 0;
            acc += c.width + spacing;
        }
        implicitWidth = reserved + unreserved + totalSpacing;
        implicitHeight = maxHeight;
    }
}
