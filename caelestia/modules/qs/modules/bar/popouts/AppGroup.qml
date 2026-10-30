import QtQuick
import QtQuick.Layouts
import wabar
import Caelestia.Config
import qs.components
import qs.services

// Port: the flyout of an application in the bar's apps list (one window or several). One preview
// card per window: a live DWM thumbnail (`WindowThumbnail`), below it the app icon, the title and
// the workspace the window is on (a roman numeral). The focused window's card has a primary
// outline. A click on a card jumps to the window with the same flow as a click on an icon
// (`Hypr.activateToplevel`: its workspace first when it is on another one).
//
// The compositor draws a thumbnail above the whole window, so nothing sits on it: the title and the
// chip are below. The thumbnails are live only while the flyout has settled (open, not sliding,
// not resizing, not closing), so none lingers or pokes out of the clipped slide-in. A window with
// no preview (registration failed, source gone, cloaked) gets its icon on a plain surface.
//
// Layout: a horizontal strip when it fits in 60% of the screen width, else a wrapping grid.
Item {
    id: root

    required property PopoutState popouts

    readonly property var group: Hypr.appGroups.find(g => g.key === Hypr.hoverGroupKey) ?? null
    readonly property var windows: group?.windows ?? []

    // Thumbnails are live only while the flyout is open and has settled.
    readonly property bool live: popouts.hasCurrent && popouts.currentName === "appgroup" && popouts.settled

    readonly property real boxW: Tokens.px(240)
    readonly property real boxH: Tokens.px(150)
    readonly property real inset: Tokens.px(6)
    readonly property real cardPad: Tokens.padding.small
    readonly property real cardW: boxW + cardPad * 2
    readonly property real gap: Tokens.spacing.medium
    // The widest the flyout may be: 60% of the window (the screen), less the popout padding.
    readonly property real maxW: Math.max(cardW, (Window.window ? Window.window.width : 1920) * 0.6 - Tokens.padding.large * 2)
    readonly property int count: windows.length
    readonly property int cols: count <= 0 ? 1 : (count * cardW + (count - 1) * gap <= maxW ? count : Math.max(1, Math.floor((maxW + gap) / (cardW + gap))))

    // Per card: "<hwnd> <available> <sourceWidth> <sourceHeight> <x>,<y>,<w>,<h>" (test IPC; the
    // rectangle is in logical window coordinates).
    function thumbState(): string {
        const out = [];
        for (let i = 0; i < cards.count; i++) {
            const c = cards.itemAt(i);
            if (!c)
                continue;
            const t = c.thumb;
            const p = t.mapToItem(null, 0, 0);
            out.push(`${c.hwnd} ${t.available} ${t.sourceWidth} ${t.sourceHeight} ${Math.round(p.x)},${Math.round(p.y)},${Math.round(t.width)},${Math.round(t.height)}`);
        }
        return out.join("; ");
    }

    implicitWidth: group ? Math.min(grid.implicitWidth, maxW) : 0
    implicitHeight: grid.implicitHeight

    GridLayout {
        id: grid

        columns: root.cols
        columnSpacing: root.gap
        rowSpacing: root.gap

        Repeater {
            id: cards

            model: root.windows

            delegate: Item {
                id: card

                required property var modelData
                required property int index

                readonly property bool focused: modelData.address === Hypr.focusedHwnd
                // Fake windows (test IPC) borrow the preview of a real one (`srcHwnd`).
                readonly property real hwnd: Number(modelData.srcHwnd ?? modelData.address) || 0
                readonly property alias thumb: thumb

                implicitWidth: root.cardW
                implicitHeight: col.implicitHeight + root.cardPad * 2

                Rectangle {
                    anchors.fill: parent
                    radius: Tokens.rounding.medium
                    color: card.focused ? Colours.palette.m3primaryContainer : (mouse.containsMouse ? Colours.palette.m3surfaceContainerHighest : Colours.palette.m3surfaceContainerHigh)
                    border.width: card.focused ? Tokens.px(2) : 0
                    border.color: Colours.palette.m3primary
                }

                ColumnLayout {
                    id: col

                    anchors.fill: parent
                    anchors.margins: root.cardPad
                    spacing: Tokens.spacing.small

                    // The preview area: a rounded surface with the thumbnail inset in it, so the
                    // thumbnail's square corners stay inside the rounding.
                    Item {
                        id: box

                        Layout.preferredWidth: root.boxW
                        Layout.preferredHeight: root.boxH

                        Rectangle {
                            anchors.fill: parent
                            radius: Tokens.rounding.small
                            color: Colours.palette.m3surfaceContainerLowest
                        }

                        // Fallback: the app icon, whenever there is no live preview.
                        Image {
                            anchors.centerIn: parent
                            visible: !thumb.available && source.toString() !== ""
                            width: Tokens.px(48)
                            height: width
                            source: card.modelData.icon ?? ""
                            sourceSize: Qt.size(width * 2, height * 2)
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            smooth: true
                        }

                        MaterialIcon {
                            anchors.centerIn: parent
                            visible: !thumb.available && !card.modelData.icon
                            text: "desktop_windows"
                            color: Colours.palette.m3onSurfaceVariant
                            fontStyle: Tokens.font.icon.extraLarge
                        }

                        WindowThumbnail {
                            id: thumb

                            readonly property real availW: box.width - root.inset * 2
                            readonly property real availH: box.height - root.inset * 2
                            readonly property real ratio: sourceWidth > 0 && sourceHeight > 0 ? sourceWidth / sourceHeight : availW / availH

                            x: (box.width - width) / 2
                            y: (box.height - height) / 2
                            width: Math.min(availW, availH * ratio)
                            height: width / ratio
                            hwnd: card.hwnd
                            active: root.live && card.hwnd !== 0
                            fit: WindowThumbnail.PreserveAspectFit
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.small

                        Image {
                            Layout.preferredWidth: Tokens.px(16)
                            Layout.preferredHeight: Tokens.px(16)
                            source: card.modelData.icon ?? ""
                            sourceSize: Qt.size(width * 2, height * 2)
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            smooth: true
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: card.modelData.title
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            color: card.focused ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                        }

                        // The workspace the window is on; a window on another workspace gets the
                        // tertiary colours, as a hint that a click switches there.
                        StyledRect {
                            readonly property bool away: card.modelData.wsActive === false

                            implicitWidth: Math.max(implicitHeight, chip.implicitWidth + Tokens.px(10))
                            implicitHeight: chip.implicitHeight + Tokens.px(4)
                            radius: Tokens.rounding.full
                            color: away ? Colours.palette.m3tertiaryContainer : Colours.palette.m3surfaceContainer

                            StyledText {
                                id: chip

                                anchors.centerIn: parent
                                text: Hypr.workspaceLabel(card.modelData)
                                color: parent.away ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.label.medium
                            }
                        }
                    }
                }

                MouseArea {
                    id: mouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hypr.activateToplevel(card.modelData)
                }
            }
        }
    }
}
