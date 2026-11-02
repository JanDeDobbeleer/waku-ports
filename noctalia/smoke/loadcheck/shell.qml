import QtQuick
import Quickshell
ShellRoot {
  property var files: [
"file:///D:/waku-ports/noctalia/modules/qs/Modules/Panels/SetupWizard/SetupAppearanceStep.qml",
"file:///D:/waku-ports/noctalia/modules/qs/Modules/Panels/SetupWizard/SetupCustomizeStep.qml",
"file:///D:/waku-ports/noctalia/modules/qs/Modules/Panels/SetupWizard/SetupDockStep.qml",
"file:///D:/waku-ports/noctalia/modules/qs/Modules/Panels/SetupWizard/SetupWallpaperStep.qml",
"file:///D:/waku-ports/noctalia/modules/qs/Modules/Panels/SetupWizard/SetupWizard.qml"
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