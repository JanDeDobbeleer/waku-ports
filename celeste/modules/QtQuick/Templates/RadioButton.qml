import QtQuick

// Stand-in for QtQuick.Templates.RadioButton: radio buttons with the same parent exclude each other.
AbstractButton {
    id: radio

    checkable: true
    autoExclusive: true

    onCheckedChanged: {
        if (!checked || !autoExclusive || !parent)
            return;
        for (const sibling of parent.children) {
            if (sibling !== radio && sibling.autoExclusive && sibling.checkable && sibling.checked && sibling.hasOwnProperty("text"))
                sibling.checked = false;
        }
    }
}
