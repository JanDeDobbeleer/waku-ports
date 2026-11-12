pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import waku.services as S
import qs.Commons
import qs.Ui
import "WorkspacesModel.js" as WorkspacesModel

// Windows port of the workspaces widget: the Windows virtual desktops, through the
// engine's `Workspaces` service (the Hyprland version read hyprctl and a per-monitor block of ten).
// The active workspace shows a filled square, the others their number; one with no windows is dimmed.
BarWidget {
  id: root
  moduleName: "nomarchy.workspaces"

  // At least this many buttons, so the bar looks the same before the desktops are known.
  readonly property int minimumSlots: 5

  readonly property string screenName: WorkspacesModel.screenName(root.QsWindow.window)

  // The engine names a monitor "DISPLAY1"; a Quickshell screen is "\\.\DISPLAY1".
  // A monitor is a plain map; the engine replaces `monitors` whenever a desktop changes.
  readonly property var monitor: WorkspacesModel.monitorFor(S.Workspaces.monitors, root.screenName)

  // [{ number, active, occupied, exists }]
  readonly property var slots: WorkspacesModel.slots(root.monitor, root.minimumSlots)

  function focusWorkspace(number: var): var {
    S.Workspaces.focus(0, String(number - 1))
  }

  // A wheel notch moves one entry along the row, and a touchpad adds up its smaller deltas.
  property real wheelAccumulator: 0

  function scrollWorkspaces(delta: var): void {
    WorkspacesModel.scroll(root, delta, Util.wheelSteps(root.wheelAccumulator, delta))
  }

  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

  implicitWidth: grid.implicitWidth + trailingGap
  implicitHeight: grid.implicitHeight

  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : WorkspacesModel.count(root.slots)
    columnSpacing: root.vertical ? 0 : Style.space(1)
    rowSpacing: root.vertical ? Style.space(2) : 0

    Repeater {
      model: root.slots

      WidgetButton {
        required property var modelData

        bar: root.bar
        text: WorkspacesModel.label(modelData)
        opacity: WorkspacesModel.opacity(modelData)
        horizontalMargin: 6
        verticalPadding: 6
        fixedWidth: root.vertical ? root.barSize : Style.space(20)
        fixedHeight: root.barSize
        onPressed: function(): var {
          if (WorkspacesModel.canFocus(modelData)) root.focusWorkspace(WorkspacesModel.number(modelData))
        }
        onWheelMoved: function(delta: int): var { root.scrollWorkspaces(delta) }
      }
    }
  }
}
