import QtQuick

// Stand-in for QtQuick.Templates.AbstractButton: text, checked, pressed, clicked and toggled.
Control {
    id: button

    final property string text
    final property font font
    final property bool checkable: false
    final property bool checked: false
    final property bool autoExclusive: false
    final property bool autoRepeat: false
    final property Item indicator
    readonly final property bool pressed: area.pressed
    readonly final property bool down: area.pressed
    readonly final property real implicitIndicatorWidth: indicator ? indicator.implicitWidth : 0
    readonly final property real implicitIndicatorHeight: indicator ? indicator.implicitHeight : 0

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
