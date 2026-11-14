import QtQml

// Quickshell's `Singleton`: a QObject whose default property takes child objects (Timer, Process,
// Connections, ...). The waku engine has no such type in its Quickshell module, so the port
// supplies it. A file that uses it as its root declares `pragma Singleton` itself.
QtObject {
    default final property list<QtObject> data
}
