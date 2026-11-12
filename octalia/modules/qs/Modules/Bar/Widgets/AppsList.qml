import QtQuick 6.10
import Quickshell
import Quickshell.Widgets
import qs.Commons
import qs.Services.Compositor
import qs.Services.UI

// AppsList - the running applications as a row of icons, in place of the active-window label
// (styled after Celeste's bar list). One icon per application (windows grouped by app id, in the
// order they were first seen). The application with the focused window sits on a rounded primary
// pill. An application with several windows has a count badge. An application whose windows are all
// on other workspaces is dimmed. A click focuses the application's window: for a group, the one
// after the focused window, so repeated clicks cycle through them.
Item {
  id: root

  property ShellScreen screen

  // Widget properties passed from Bar.qml for per-instance settings
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  readonly property string screenName: screen ? screen.name : ""
  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool isVertical: barPosition === "left" || barPosition === "right"
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)

  property var widgetMetadata: BarWidgetRegistry.widgetMetadata[widgetId] ?? {}
  property var widgetSettings: {
    var widgets;
    if (section && sectionWidgetIndex >= 0 && screenName) {
      widgets = Settings.getBarWidgetsForScreen(screenName)[section];
      if (widgets && sectionWidgetIndex < widgets.length) {
        return widgets[sectionWidgetIndex];
      }
    }
    return {};
  }

  readonly property bool onlySameOutput: (widgetSettings.onlySameOutput !== undefined) ? widgetSettings.onlySameOutput : (widgetMetadata.onlySameOutput ?? false)

  // The capsule is as high as the other bar widgets. Each application sits in a round cell inset from
  // the capsule by the same amount on every side, so the padding matches a single-icon widget.
  readonly property real cell: capsuleHeight
  readonly property real pad: Math.round(cell * 0.14)
  readonly property real itemSize: cell - pad * 2
  readonly property real iconSize: Style.toOdd(itemSize * 0.66)
  // Space between applications, and the capsule's padding along the list (a little wider than across)
  readonly property real gap: Style.marginS
  readonly property real edgePad: Math.round(cell * 0.2)

  // [{key, appId, windows: [window...], focused, onActiveWs}]
  property var groups: []

  function rebuild() {
    var i;
    const order = [];
    const byKey = {};
    const activeIds = CompositorService.getActiveWorkspaces().map(function (ws) {
      return ws.id;
    });
    const total = CompositorService.windows.count || 0;
    for (i = 0; i < total; i++) {
      const w = CompositorService.windows.get(i);
      if (!w || !w.appId)
        continue;
      if (onlySameOutput && w.output !== screenName)
        continue;
      const key = String(w.appId).toLowerCase();
      let g = byKey[key];
      if (!g) {
        g = {
          "key": key,
          "appId": w.appId,
          "windows": [],
          "focused": false,
          "onActiveWs": false
        };
        byKey[key] = g;
        order.push(g);
      }
      g.windows.push(w);
      if (w.isFocused)
        g.focused = true;
      if (activeIds.includes(w.workspaceId))
        g.onActiveWs = true;
    }
    groups = order;
  }

  // The window to focus when the application's icon is clicked
  function focusGroup(g) {
    if (!g || g.windows.length === 0)
      return;
    let target = g.windows[0];
    const fi = g.windows.findIndex(function (w) {
      return w.isFocused;
    });
    if (fi >= 0) {
      target = g.windows[(fi + 1) % g.windows.length];
    }
    CompositorService.focusWindow(target);
  }

  visible: groups.length > 0
  implicitWidth: isVertical ? cell : capsule.width
  implicitHeight: isVertical ? capsule.height : cell

  Component.onCompleted: rebuild()

  Connections {
    target: CompositorService
    function onActiveWindowChanged() {
      root.rebuild();
    }
    function onWindowListChanged() {
      root.rebuild();
    }
    function onWorkspaceChanged() {
      root.rebuild();
    }
  }

  // Capsule behind the icons, like the other bar widgets
  Rectangle {
    id: capsule
    anchors.centerIn: parent
    width: root.isVertical ? root.cell : (list.implicitWidth + root.edgePad * 2)
    height: root.isVertical ? (list.implicitHeight + root.edgePad * 2) : root.cell
    radius: Style.radiusL
    color: Style.capsuleColor
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    Grid {
      id: list
      anchors.centerIn: parent
      rows: root.isVertical ? root.groups.length : 1
      columns: root.isVertical ? 1 : root.groups.length
      spacing: root.gap

      Repeater {
        model: root.groups

        delegate: Item {
          id: app

          required property var modelData
          required property int index

          readonly property int windowCount: modelData.windows.length
          readonly property bool focused: modelData.focused

          width: root.itemSize
          height: root.itemSize
          opacity: (modelData.onActiveWs || focused) ? 1 : 0.55

          // A second card behind the icon marks a group
          Rectangle {
            anchors.fill: parent
            anchors.leftMargin: root.isVertical ? 0 : Style.marginXXS
            anchors.rightMargin: root.isVertical ? 0 : -Style.marginXXS
            visible: app.windowCount > 1 && !app.focused
            radius: height / 2
            color: Color.mSurface
            opacity: 0.6
          }

          // The focused application's pill
          Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: app.focused ? Color.mPrimary : (mouse.containsMouse ? Color.mHover : "transparent")
          }

          IconImage {
            anchors.centerIn: parent
            width: root.iconSize
            height: root.iconSize
            source: ThemeIcons.iconForAppId(app.modelData.appId)
            smooth: true
            asynchronous: true
          }

          // Count of windows: a small dot on the icon's bottom-right corner, sized from the icon so it
          // never covers much of it
          Rectangle {
            visible: app.windowCount > 1
            readonly property real dot: Math.max(10, Math.round(root.iconSize * 0.5))
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: -Math.round(dot * 0.2)
            anchors.bottomMargin: -Math.round(dot * 0.2)
            width: Math.max(dot, badge.implicitWidth + 4)
            height: dot
            radius: height / 2
            color: Color.mTertiary
            border.width: 1
            border.color: Color.mSurface

            Text {
              id: badge
              anchors.centerIn: parent
              text: app.windowCount > 9 ? "9+" : app.windowCount
              color: Color.mOnTertiary
              font.pixelSize: Math.round(parent.dot * 0.75)
              font.bold: true
            }
          }

          MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.focusGroup(app.modelData)
          }
        }
      }
    }
  }
}
