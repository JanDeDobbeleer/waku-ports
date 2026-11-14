import QtQuick
import "RadioButtonHelpers.js" as RadioButtonHelpers

// Stand-in for QtQuick.Templates.RadioButton: radio buttons with the same parent exclude each other.
AbstractButton {
    id: radio

    checkable: true
    autoExclusive: true

    onCheckedChanged: RadioButtonHelpers.exclude(radio)
}
