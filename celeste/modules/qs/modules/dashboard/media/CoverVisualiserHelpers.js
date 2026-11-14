.pragma library

function barIndices(count) {
    const result = [];
    for (let i = 0; i < count; i++)
        result.push(i);
    return result;
}
function edgeDistance(cover, angle, cutils, spacing, strokeWidth) {
    cutils.dependency(cover.shape.rotation);
    return cover.shape.distanceAtAngle(angle) + spacing + strokeWidth / 2;
}
