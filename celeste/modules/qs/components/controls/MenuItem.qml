import QtQuick

QtObject {
    required final property string text
    final property string icon
    final property string trailingIcon
    final property string activeIcon: icon
    final property string activeText: text
    final property var value

    signal clicked
}
