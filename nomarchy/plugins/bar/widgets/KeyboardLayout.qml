import QtQuick
import Quickshell.Hyprland
import Quickshell.Io
import qs.Ui
import qs.Commons
import "KeyboardLayoutModel.js" as KeyboardLayoutModel

BarWidget {
  id: root
  moduleName: "nomarchy.keyboard-layout"


  property string layoutFull: ""
  // The keyboard the last reading spoke for, which is the one a click switches,
  // and separately the one activelayout named as being typed on. A reading
  // confirms the first is really there, so the click has a keyboard to reach
  // from the first reading onwards rather than only after a switch, and stops
  // naming one that has been unplugged.
  property string keyboardName: ""
  property string typedKeyboardName: ""
  // Whether the last reading left the seat's shape in doubt.
  property bool keyboardUnresolved: false
  // Nothing to read or switch on the single-layout install most people run, so
  // the widget ships on the bar and stays out of the way until there are two.
  // An older Hyprland that doesn't report the list keeps showing the label.
  property bool multipleLayouts: true
  // Where the reading sits in the layout list, how long that list is, and every
  // keyboard sharing it. A switch moves that set together, so it needs all three.
  property int layoutIndex: 0
  property int layoutCount: 0
  property list<var> syncNames: []
  // Short language code per layout description ("English (US)": "en"), read from
  // xkb's own table rather than maintained by hand.
  property var layoutBriefs: ({})
  // The table is only needed once the widget shows a label, which a seat with
  // one layout and one input method never does, so it's read on first need.
  property bool layoutsRead: false
  property bool briefsRequested: false
  readonly property bool needsBriefs: layoutsRead && (multipleLayouts || multipleInputs)
  onNeedsBriefsChanged: loadBriefs()

  function loadBriefs(): var {
    if (!needsBriefs || briefsRequested) return
    briefsRequested = true
    briefsProc.running = true
  }
  readonly property string layoutLabel: KeyboardLayoutModel.shortLabel(layoutFull, layoutBriefs)
  readonly property var inputState: InputMethodState.state
  readonly property bool multipleInputs: KeyboardLayoutModel.hasMultipleInputs(inputState)
  readonly property string inputLabel: KeyboardLayoutModel.inputLabel(inputState, layoutLabel)

  // A query already in flight was started before this event, so it may read the
  // layout the switch replaced. Remember the request and re-run once it lands
  // rather than dropping it; nothing else would correct the label afterwards.
  property bool refreshPending: false

  function refresh(): var {
    if (queryProc.running) {
      refreshPending = true
      return
    }

    refreshPending = false
    queryProc.running = true
  }

  // Keyboards someone can actually type on, which is not everything Hyprland
  // calls a keyboard.

  // switchxkblayout is a hyprctl command rather than a dispatcher, so it has to
  // be run rather than sent over the dispatch socket.
  //
  // Move every keyboard holding the same layout list, rather than the single one
  // the last reading spoke for. Naming one device puts the whole switch behind
  // UNTYPED_KEYBOARDS recognising every non-keyboard by name, and that list
  // cannot keep up with what a seat carries: vendor hotkey blocks
  // (intel-hid-events, dell-wmi-hotkeys), HID consumer controls, and Bluetooth
  // AVRCP endpoints from a pair of headphones all arrive holding the seat's
  // layout list, and they sort ahead of the keyboard being typed on. The click
  // then advances a device nobody types on; that device is now the furthest
  // along, so it wins the next reading too, and the label describes it while the
  // real keyboard never moved.
  //
  // An absolute index rather than "next", because "next" advances each device
  // from wherever it already sits: a seat that has drifted apart stays drifted
  // and merely inverts. One index converges them in a single click, and a seat
  // in lockstep is what leaves the reading nothing to disagree about afterwards.
  //
  // Keyboards given their own kb_layout hold a different list and are left out:
  // an index into this list would not mean the same layout to them.
  function cycleLayout(): void {
    if (!root.bar || root.layoutCount < 2 || root.syncNames.length === 0) return
    BarValues.run(root.bar, KeyboardLayoutModel.switchCommand(root.syncNames, (root.layoutIndex + 1) % root.layoutCount))
    refreshTimer.restart()
  }

  Component.onCompleted: refresh()

  Connections {
    target: Hyprland
    function onRawEvent(event: var): void {
      KeyboardLayoutModel.handleHyprlandEvent(root, event)
    }
  }

  Process {
    id: queryProc
    command: ["cmd.exe", "/c", "rem"]
    onRunningChanged: {
      if (running) {
        stallTimer.restart()
        return
      }

      stallTimer.stop()
      if (root.refreshPending) root.refresh()
    }
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: KeyboardLayoutModel.applyReading(root, text)
    }
  }

  // The table only changes when xkb data is upgraded, so read it once, when
  // first needed, and leave it alone. The bar is built per monitor, so this
  // runs once per widget.
  // The exotic rulesets cover layouts like trans (IPA) that ship in the same xkb
  // package and set just as well, so load them or those labels lose their code.
  Process {
    id: briefsProc
    command: ["xkbcli", "list", "--load-exotic"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.layoutBriefs = KeyboardLayoutModel.layoutBriefs(text)
    }
  }

  Timer {
    id: refreshTimer
    interval: 600
    onTriggered: root.refresh()
  }

  // A query that never returns would freeze the label until the shell restarts,
  // since a Process that is already running can't be re-run. Give up on one that
  // overstays so the next refresh gets through, and ask again: the reading it
  // never delivered may have been the only one due on a settled seat, and
  // nothing else would come back for it.
  Timer {
    id: stallTimer
    interval: 5000
    onTriggered: {
      queryProc.running = false
      refreshTimer.restart()
    }
  }

  // Which keyboard on a crowded seat the label is describing changes when a
  // device arrives or leaves, which Hyprland raises no event for, so read the
  // seat again whenever /dev/input changes.
  Connections {
    target: InputDevices
    function onChanged(): var { root.refresh() }
  }

  // Ask again until a first reading lands, so a query that failed at login
  // still recovers, and while a reading has left the seat's shape in doubt. A
  // settled seat has neither, and is left alone rather than spawning hyprctl
  // forever for an answer only a device change can alter.
  Timer {
    interval: 10000
    running: !root.keyboardName || root.keyboardUnresolved || !InputDevices.healthy
    repeat: true
    onTriggered: root.refresh()
  }

  visible: inputLabel !== "" && KeyboardLayoutModel.showIndicator(layoutLabel, multipleLayouts, multipleInputs)
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.inputLabel
    fontSize: Style.font.caption
    horizontalMargin: 6
    tooltipText: KeyboardLayoutModel.inputTooltip(root.inputState, root.layoutFull, root.multipleLayouts)
    onPressed: function(button: int): var {
      if (root.multipleInputs && button === Qt.LeftButton) {
        InputMethodState.cycle(false)
      } else if (root.multipleLayouts) {
        root.cycleLayout()
      }
    }
  }
}
