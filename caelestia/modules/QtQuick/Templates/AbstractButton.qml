import QtQuick

// Stand-in for QtQuick.Templates.AbstractButton: text, checked, pressed, clicked and toggled.
Control {
    id: button

    property string text
    property font font
    property bool checkable: false
    property bool checked: false
    property bool autoExclusive: false
    property bool autoRepeat: false
    property Item indicator
    readonly property bool pressed: area.pressed
    readonly property bool down: area.pressed
    readonly property real implicitIndicatorWidth: indicator ? indicator.implicitWidth : 0
    readonly property real implicitIndicatorHeight: indicator ? indicator.implicitHeight : 0

    signal clicked
    signal toggled
    signal canceled

    function toggle(): void {
        checked = !checked;
    }

    function click(): void {
        if (checkable && !(checked && autoExclusive))
            toggle();
        if (checkable)
            toggled();
        clicked();
    }

    onIndicatorChanged: {
        if (indicator)
            indicator.parent = button;
    }

    MouseArea {
        id: area

        anchors.fill: parent
        z: -0.5
        enabled: button.enabled
        onClicked: button.click()
    }
}
