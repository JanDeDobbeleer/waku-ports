import QtQuick
import Quickshell
import waku.services as S
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// Windows port: the running applications, one icon per program, right of the workspaces. The rows
// are the engine's `TaskbarModel` (every window the taskbar lists, on every komorebi workspace),
// grouped by executable in the order they first appeared. The program with the foreground window
// sits on a highlighted tile, one whose windows are all minimized is dimmed with a dash under the
// icon, and a program with several windows has a count badge. A click raises the window after the
// focused one (or the first), restoring a minimized window; a middle click raises the last one.
BarWidget {
  id: root
  moduleName: "omarchy.apps"

  readonly property real cell: Style.space(22)
  readonly property real gap: Style.space(2)
  // Past this many programs the list stops growing: the rest show as "+N".
  readonly property int maxVisible: Number(setting("maxVisible", 12))
  readonly property color ink: root.bar ? root.bar.barForeground : Commons.Color.foreground
  readonly property string family: root.bar ? root.bar.fontFamily : Style.font.family
  // The attached Window is only available on an Item, so it is read here and handed to the model.
  readonly property var hostWindow: Window.window

  // [{ key, exe, iconUrl, windows: [{ index, title, active, minimized }] }]
  property var groups: []
  // The programs in the order they first showed up, kept while rows come and go.
  property var known: []

  function rebuild() {
    var byExe = {}
    var order = []
    for (var i = 0; i < rows.count; i++) {
      var o = rows.objectAt(i)
      if (!o || o.key.indexOf("w:") !== 0) continue
      var exe = o.exe
      if (!byExe[exe]) {
        byExe[exe] = { key: exe, exe: exe, iconUrl: o.iconUrl, windows: [] }
        order.push(exe)
      }
      var g = byExe[exe]
      if (!g.iconUrl) g.iconUrl = o.iconUrl
      g.windows.push({ index: i, title: o.title, active: o.active, minimized: o.minimized })
    }
    var kept = []
    var seen = {}
    for (var k = 0; k < root.known.length; k++) {
      if (byExe[root.known[k]]) { kept.push(root.known[k]); seen[root.known[k]] = true }
    }
    for (var n = 0; n < order.length; n++) if (!seen[order[n]]) kept.push(order[n])
    root.known = kept
    var out = []
    for (var m = 0; m < kept.length; m++) out.push(byExe[kept[m]])
    root.groups = out
  }

  // Raise a program: the window after the focused one, else the first (the last for `last`). The
  // only window of a program that already has focus is left alone, as a click on a taskbar button
  // would minimize it.
  function clickGroup(g, last) {
    if (!g || g.windows.length === 0) return
    var target = g.windows[last ? g.windows.length - 1 : 0]
    var focusedAt = -1
    for (var i = 0; i < g.windows.length; i++) if (g.windows[i].active) focusedAt = i
    if (focusedAt >= 0 && g.windows.length === 1) return
    if (focusedAt >= 0 && !last) target = g.windows[(focusedAt + 1) % g.windows.length]
    taskbar.activate(target.index)
  }

  readonly property var shown: groups.length > maxVisible ? groups.slice(0, maxVisible) : groups
  readonly property int hidden: Math.max(0, groups.length - shown.length)

  visible: !vertical && groups.length > 0
  implicitWidth: visible ? row.implicitWidth + Style.space(8) : 0
  implicitHeight: barSize

  S.TaskbarModel {
    id: taskbar
    // The model has no service of its own: without this it never has a row.
    service: S.TaskbarService
    grouping: false
    // The engine starts its window tracker for a model that has a bar window.
    window: root.hostWindow
  }

  Instantiator {
    id: rows
    model: taskbar
    delegate: QtObject {
      required property string title
      required property bool active
      required property bool minimized
      required property string key
      required property string iconUrl
      required property string uniqueId
      readonly property string exe: uniqueId.split(/[\\/!]/).pop().replace(/\.exe$/i, "")

      onActiveChanged: Qt.callLater(root.rebuild)
      onMinimizedChanged: Qt.callLater(root.rebuild)
      onTitleChanged: Qt.callLater(root.rebuild)
      onIconUrlChanged: Qt.callLater(root.rebuild)
    }
    onObjectAdded: Qt.callLater(root.rebuild)
    onObjectRemoved: Qt.callLater(root.rebuild)
  }

  Row {
    id: row
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    anchors.leftMargin: Style.space(4)
    spacing: root.gap

    Repeater {
      model: root.shown

      delegate: Item {
        id: app
        required property var modelData

        readonly property bool focused: modelData.windows.some(function(w) { return w.active })
        readonly property bool allMinimized: modelData.windows.length > 0 && modelData.windows.every(function(w) { return w.minimized })
        readonly property int count: modelData.windows.length
        readonly property bool hasImage: image.source.toString() !== "" && image.status !== Image.Error

        width: root.cell
        height: root.cell
        opacity: allMinimized && !focused ? 0.5 : 1

        Rectangle {
          anchors.fill: parent
          radius: Style.cornerRadius
          color: app.focused ? Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.18)
            : (area.containsMouse ? Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.08) : "transparent")
        }

        Image {
          id: image
          anchors.centerIn: parent
          width: Math.round(root.cell * 0.68)
          height: width
          visible: app.hasImage
          source: app.modelData.iconUrl
          sourceSize: Qt.size(width * 2, height * 2)
          fillMode: Image.PreserveAspectFit
          asynchronous: true
          smooth: true
          mipmap: true
        }

        // No icon from the engine: the first letter of the program.
        Text {
          anchors.centerIn: parent
          visible: !app.hasImage
          textFormat: Text.PlainText
          text: app.modelData.exe.length > 0 ? app.modelData.exe.charAt(0).toUpperCase() : "?"
          color: root.ink
          font.family: root.family
          font.pixelSize: Style.font.body
          font.bold: true
        }

        // The minimized mark: a short dash under the icon.
        Rectangle {
          visible: app.allMinimized
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 1
          width: Math.round(root.cell * 0.4)
          height: 2
          radius: 1
          color: root.ink
        }

        // The window count, at the icon's top-right corner.
        Rectangle {
          visible: app.count > 1
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.rightMargin: -2
          anchors.topMargin: -2
          width: Math.max(height, badge.implicitWidth + 6)
          height: badge.implicitHeight + 1
          radius: height / 2
          color: Commons.Color.accent

          Text {
            id: badge
            anchors.centerIn: parent
            textFormat: Text.PlainText
            text: app.count
            color: Commons.Color.background
            font.family: root.family
            font.pixelSize: Style.font.caption
            font.bold: true
          }
        }

        MouseArea {
          id: area
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.LeftButton | Qt.MiddleButton
          cursorShape: Qt.PointingHandCursor
          onClicked: function(mouse) { root.clickGroup(app.modelData, mouse.button === Qt.MiddleButton) }
        }
      }
    }

    // "+N": the programs that do not fit.
    Text {
      visible: root.hidden > 0
      anchors.verticalCenter: parent.verticalCenter
      textFormat: Text.PlainText
      text: "+" + root.hidden
      color: root.ink
      font.family: root.family
      font.pixelSize: Style.font.bodySmall
      opacity: 0.7
    }
  }
}
