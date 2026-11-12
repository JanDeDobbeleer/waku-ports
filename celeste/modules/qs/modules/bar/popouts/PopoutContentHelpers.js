.pragma library

function activePopout(children) {
    for (var i = 0; i < children.length; i++) {
        if (children[i].shouldBeActive)
            return children[i];
    }
    return null;
}
function implicitWidth(popout, padding) { return popout ? popout.implicitWidth + padding * 2 : 0; }
function implicitHeight(popout, padding) { return popout ? popout.implicitHeight + padding * 2 : 0; }

function item(popout) { return popout ? popout.item : null; }
