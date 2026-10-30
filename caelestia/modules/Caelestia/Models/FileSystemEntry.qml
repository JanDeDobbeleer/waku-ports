import QtQuick

// One file or folder of a FileSystemModel. Only the model creates these.
QtObject {
    property string path
    property string relativePath
    property string name
    property string baseName
    property string parentDir
    property string suffix
    property real size
    property bool isDir
    property bool isImage
    property string mimeType
}
