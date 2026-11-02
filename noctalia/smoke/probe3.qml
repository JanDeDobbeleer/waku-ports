import QtQuick
import Quickshell
import waku.services as S
ShellRoot {
  id: root
  Window { id: w; visible: true; width: 10; height: 10 }
  S.TaskbarModel { id: tm; service: S.TaskbarService; grouping: false; window: w }
  Instantiator { id: rows; model: tm; delegate: QtObject {
    property string key: model.key !== undefined ? model.key : ""
  } }
  property var mons: S.Workspaces.monitors
  property bool conn: S.Workspaces.connected
  Timer { interval: 7000; running: true; onTriggered: {
    function keys(o) { var k = []; for (var p in o) k.push(p); return k.sort().join(","); }
    console.log("PROBE|WS|provider=" + S.Workspaces.provider + " connected=" + S.Workspaces.connected + " prefer=" + S.Workspaces.prefer);
    var m = S.Workspaces.monitors;
    console.log("PROBE|MONS|n=" + m.length);
    if (m.length) { console.log("PROBE|MON0|" + JSON.stringify(m[0]).substring(0, 700)); }
    console.log("PROBE|TB|available=" + S.TaskbarService.available + " count=" + tm.count + " roles=" + JSON.stringify(tm.roleNames ? tm.roleNames() : "n/a"));
    console.log("PROBE|ROW0|" + (rows.count > 0 ? keys(rows.objectAt(0)) : "none"));
    console.log("PROBE|SCREENS|" + Quickshell.screens.map(s => s.name + ":" + s.width + "x" + s.height).join(" "));
    console.log("PROBE|DONE");
  } }
}
