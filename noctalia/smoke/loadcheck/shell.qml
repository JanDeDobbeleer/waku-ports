import QtQuick
import Quickshell
ShellRoot {
  property var files: [
"file:///D:/waku-ports/noctalia/modules/qs/Services/UI/ImageCacheService.qml",
"file:///D:/waku-ports/noctalia/modules/qs/Services/UI/WallpaperService.qml"
  ]
  Timer { interval: 200; running: true; repeat: false; onTriggered: {
    var bad = 0;
    for (var i = 0; i < files.length; ++i) {
      var c = Qt.createComponent(files[i]);
      if (c.status === Component.Error) { bad++; console.log("LOADCHK|ERR|" + files[i] + "|" + c.errorString().replace(/\s*\n\s*/g, " ;; ")); }
      else if (c.status !== Component.Ready) { console.log("LOADCHK|PEND|" + files[i]); }
    }
    console.log("LOADCHK|DONE|" + files.length + "|" + bad);
  } }
}