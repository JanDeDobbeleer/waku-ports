.pragma library

function thumbState(cards) {
    const output = [];
    for (let i = 0; i < cards.count; i++) {
        const card = cards.itemAt(i);
        if (!card)
            continue;
        const thumb = card.thumb;
        const position = thumb.mapToItem(null, 0, 0);
        output.push(card.hwnd + " " + thumb.available + " " + thumb.sourceWidth + " " + thumb.sourceHeight + " " + Math.round(position.x) + "," + Math.round(position.y) + "," + Math.round(thumb.width) + "," + Math.round(thumb.height));
    }
    return output.join("; ");
}
