import QtQuick

// One file or folder of a FileSystemModel. Only the model creates these.
QtObject {
    final property string path
    final property string relativePath
    final property string name
    final property string baseName
    final property string parentDir
    final property string suffix
    final property real size
    final property bool isDir
    final property bool isImage
    final property string mimeType
}
