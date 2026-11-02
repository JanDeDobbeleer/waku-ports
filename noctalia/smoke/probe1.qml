import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
ShellRoot {
  id: root
  Timer { interval: 300; running: true; onTriggered: {
    function keys(o) { var k = []; for (var p in o) k.push(p); return k.sort().join(","); }
    function tryType(name, imp) {
      try { var o = Qt.createQmlObject("import QtQuick; import Quickshell; import Quickshell.Wayland; import Quickshell.Hyprland; " + name + " {}", root, "probe_" + name);
            console.log("PROBE|TYPE|" + name + "|" + keys(o)); o.destroy(); }
      catch (e) { console.log("PROBE|NOTYPE|" + name + "|" + String(e).substring(0, 160)); }
    }
    tryType("PopupWindow"); tryType("PanelWindow"); tryType("IdleInhibitor"); tryType("FloatingWindow");
    tryType("ToplevelManager"); tryType("WlrLayershell"); tryType("Region"); tryType("ScriptModel");
    console.log("PROBE|HYPRLAND|" + keys(Hyprland));
    console.log("PROBE|QUICKSHELL|" + keys(Quickshell));
    console.log("PROBE|DONE");
  } }
}
