.pragma library

function widthBinding(qt, slider, handle) {
    return qt.binding(function() {
        return (slider.width - handle.implicitWidth - handle.anchors.leftMargin) * slider.pos;
    });
}
function handleHeight(height, pressed, cutils) {
    const t = cutils.clamp((height - 12) / 16, 0, 1);
    const lowScale = pressed ? 3.5 : 3;
    const highScale = pressed ? 1.5 : 1.2;
    return height * (lowScale + (highScale - lowScale) * t);
}
