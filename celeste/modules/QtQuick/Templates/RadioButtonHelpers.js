.pragma library

function exclude(radio) {
    if (!radio.checked || !radio.autoExclusive || !radio.parent)
        return;
    var siblings = radio.parent.children;
    for (var i = 0; i < siblings.length; i++) {
        var sibling = siblings[i];
        if (sibling !== radio && sibling.autoExclusive && sibling.checkable && sibling.checked && sibling.hasOwnProperty("text"))
            sibling.checked = false;
    }
}
