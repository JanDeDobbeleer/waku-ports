import QtQuick

QtObject {
    final property string ssid: ""
    final property string bssid: ""
    final property int strength: 0
    final property int frequency: 0
    final property bool active: false
    final property string security: ""
    readonly final property bool isSecure: security.length > 0
}
