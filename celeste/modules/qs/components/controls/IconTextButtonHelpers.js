.pragma library
function iconFont(font) {
    var result = Qt.font(font);
    result.pointSize = Math.round(result.pointSize * 1.2);
    return result;
}
