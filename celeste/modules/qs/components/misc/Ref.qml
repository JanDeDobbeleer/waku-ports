import QtQuick

QtObject {
    required final property var service

    Component.onCompleted: service.refCount++
    Component.onDestruction: service.refCount--
}
