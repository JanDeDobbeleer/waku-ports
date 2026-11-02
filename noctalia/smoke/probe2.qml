import QtQuick
import Quickshell
import Quickshell.Hyprland
ShellRoot {
  id: root
  Timer { interval: 500; running: true; onTriggered: {
    function keys(o) { var k = []; for (var p in o) k.push(p); return k.sort().join(","); }
    var t = Hyprland.toplevels; 
    console.log("PROBE|TOPLEVELS|" + keys(t) + "|n=" + (t && t.values ? t.values.length : "novalues"));
    var v = t && t.values ? t.values : [];
    if (v.length) console.log("PROBE|TOP0|" + keys(v[0]) + "|" + v[0].title + "|" + v[0].appId + "|" + v[0].class);
    console.log("PROBE|ACTIVE|" + (Hyprland.activeToplevel ? keys(Hyprland.activeToplevel) : "null"));
    var w = Hyprland.workspaces; console.log("PROBE|WS|" + keys(w) + "|n=" + (w && w.values ? w.values.length : "?"));
    if (w && w.values && w.values.length) console.log("PROBE|WS0|" + keys(w.values[0]));
    var m = Hyprland.monitors; if (m && m.values && m.values.length) console.log("PROBE|MON0|" + keys(m.values[0]));
    console.log("PROBE|DONE");
  } }
}
