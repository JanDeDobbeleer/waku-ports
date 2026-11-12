.pragma library

function visibleSize(flickable) { return flickable.visibleArea.heightRatio; }
function visiblePosition(flickable) { return flickable.visibleArea.yPosition; }
function isMoving(flickable) { return flickable ? flickable.moving : false; }
function currentPosition(flickable) {
    if (!flickable)
        return 0;
    const contentHeight = flickable.contentHeight;
    const height = flickable.height;
    return contentHeight > height ? Math.max(0, Math.min(1, flickable.contentY / (contentHeight - height))) : 0;
}
function setContentPosition(flickable, size, position) {
    if (!flickable)
        return;
    const contentHeight = flickable.contentHeight;
    const height = flickable.height;
    if (contentHeight > height) {
        const maxContentY = contentHeight - height;
        const maxPosition = 1 - size;
        const contentY = maxPosition > 0 ? (position / maxPosition) * maxContentY : 0;
        flickable.contentY = Math.max(0, Math.min(maxContentY, contentY));
    }
}
