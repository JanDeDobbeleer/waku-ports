import QtQuick

// One moving segment of a LinearIndicatorManager. Only the manager writes it.
QtObject {
    property real startFraction: 0
    property real endFraction: 0
    property int gapSize: 4
}
