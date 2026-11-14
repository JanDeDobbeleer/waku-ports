import QtQuick
import "RefHelpers.js" as RefHelpers

QtObject {
    required final property var service

    Component.onCompleted: RefHelpers.increment(service)
    Component.onDestruction: RefHelpers.decrement(service)
}
