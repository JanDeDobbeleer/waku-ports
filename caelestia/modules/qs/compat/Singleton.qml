import QtQml

// Quickshell's `Singleton`: a QObject whose default property takes child objects (Timer, Process,
// Connections, ...). The wabar engine has no such type in its Quickshell module, so the port
// supplies it. A file that uses it as its root declares `pragma Singleton` itself.
QtObject {
    default property list<QtObject> data
}
