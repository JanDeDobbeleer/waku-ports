pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic as QQC
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import "MultiSelectUtils.js" as MultiSelectUtils

// Searchable multi-select dropdown. Trigger shape matches Dropdown /
// SearchableDropdown; the popup shows a search field, an optional refresh
// button, and a checkbox list. Click rows to toggle. Use when callers
// need to pick zero or more items from a (possibly long, possibly
// dynamic) list.
//
// Options are either:
//   - static `options`: string[] or [{ value, label, description? }]
//   - dynamic `optionsCommand`: argv array. The command's stdout is
//     parsed as JSON when it trims to start with `[`, otherwise as
//     one option per non-empty newline. Re-runs whenever the popup opens
//     and via the refresh button.
//
// `values` is the persisted selection — always an array of strings.
// Emits `changed(values)` whenever the selection mutates.
Item {
  id: root

  property string label: ""
  property var values: []
  property var options: []
  property var optionsCommand: []
  property string optionsCommandCwd: ""
  property string placeholderText: Commons.I18n.t("common.search")
  property string emptyText: Commons.I18n.t("common.noOptions")
  property string noSelectionText: Commons.I18n.t("common.noneSelected")
  property string triggerLabel: ""
  property bool showLabel: true

  property color foreground: Commons.Color.popups.text
  property color background: Commons.Color.popups.background
  property color popupBorder: Commons.Color.popups.border
  property color accent: Commons.Color.accent
  readonly property var popupBorderSpec: Border.localOrSurfaceSpec("popups", "border", popupBorder, Commons.Color.popups.border, Style.normalBorderWidth)
  property string fontFamily: Style.font.family
  property int rowHeight: Style.spacing.controlHeight
  property int popupRowHeight: Style.spacing.popupRowHeight
  property int popupMinHeight: Style.spacing.searchablePopupMinHeight

  property bool hasCursor: false

  readonly property bool popupOpen: popup.opened
  function open() { popup.open() }
  function close() { popup.close() }
  function toggle() { popup.opened ? popup.close() : popup.open() }

  signal changed(var values)
  signal hovered(bool isHovered)

  // Loaded options after merging static + dynamic. Always normalized
  // into the [{ value, label, description }] shape for delegate use.
  property var resolvedOptions: []
  property bool loadingOptions: false
  property string optionsError: ""

  function normalizeOption(o: var): var { return MultiSelectUtils.normalizeOption(o) }
  function arrayLength(value: var): int { return MultiSelectUtils.arrayLength(value) }
  function arrayAt(value: var, index: int): var { return MultiSelectUtils.arrayAt(value, index) }
  function fieldValue(object: var, name: string): var { return MultiSelectUtils.field(object, name) }

  // QML schema arrays sometimes arrive as JSValue lists that fail
  // `Array.isArray`. arrayFrom accepts anything array-like (`.length`
  // numeric) and returns a real JS array so the rest of the component can
  // rely on standard array operations.
  function arrayFrom(v: var): var { return MultiSelectUtils.arrayFrom(v) }

  function normalizeAll(arr: var): var { return MultiSelectUtils.normalizeAll(arr) }

  function valueSet(): var { return MultiSelectUtils.valueSet(values) }

  function isSelected(value: string): bool {
    var set = valueSet()
    return !!set[String(value)]
  }

  function toggleValue(value: string): void {
    var v = String(value)
    var arr = arrayFrom(values)
    var idx = arr.indexOf(v)
    if (idx === -1) arr.push(v)
    else arr.splice(idx, 1)
    root.values = arr
    root.changed(arr)
  }

  function selectionLabel(): string {
    return MultiSelectUtils.selectionLabel(values, resolvedOptions, Commons.I18n)
  }

  property var filtered: resolvedOptions
  function recomputeFiltered(): void {
    filtered = MultiSelectUtils.filteredOptions(resolvedOptions, searchField.text)
  }

  function rebuildFromStatic(): void {
    resolvedOptions = normalizeAll(options)
    recomputeFiltered()
  }

  // Parse stdout from a dynamic optionsCommand into `{ options, error }`.
  // Output starting with `[` is parsed strictly as JSON — a malformed array
  // surfaces as an error rather than silently falling back to newline
  // parsing, which would render the broken text as a literal option label.
  // Output not starting with `[` is treated as one value per non-empty line.
  function parseCommandOutput(text: string): var {
    return MultiSelectUtils.parseCommandOutput(text, Commons.I18n.t("multiSelect.invalidJson"))
  }

  // Monotonic request id so stale stdout/exit signals from a previous
  // refresh can't clobber the resolvedOptions of a newer refresh, and
  // a runaway command can be detected after a timeout.
  property int refreshSeq: 0
  readonly property int refreshTimeoutMs: 6000

  function refresh(): void {
    var cmd = arrayFrom(optionsCommand)
    if (MultiSelectUtils.arrayLength(cmd) === 0) {
      rebuildFromStatic()
      return
    }
    refreshSeq++
    loadingOptions = true
    optionsError = ""
    optionsProcess.command = cmd
    optionsProcess.workingDirectory = optionsCommandCwd
    optionsProcess.running = false
    optionsProcess.running = true
    refreshTimeoutTimer.restart()
  }

  Timer {
    id: refreshTimeoutTimer
    interval: root.refreshTimeoutMs
    repeat: false
    onTriggered: {
      if (!root.loadingOptions) return
      optionsProcess.running = false
      root.loadingOptions = false
      root.optionsError = Commons.I18n.t("multiSelect.timedOut")
    }
  }

  onOptionsChanged: if (arrayLength(arrayFrom(optionsCommand)) === 0) rebuildFromStatic()
  onOptionsCommandChanged: refresh()
  Component.onCompleted: refresh()

  Process {
    id: optionsProcess
    running: false
    command: []

    property int seq: 0

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (optionsProcess.seq !== root.refreshSeq) return
        var result = root.parseCommandOutput(text)
        var error = root.arrayAt(result, 1)
        var dynamicOptions = root.arrayAt(result, 0)
        if (error) {
          root.optionsError = error
          root.resolvedOptions = root.normalizeAll(root.options)
        } else {
          let combined = root.arrayFrom(root.options)
          for (let j = 0; j < root.arrayLength(dynamicOptions); j++) combined.push(root.arrayAt(dynamicOptions, j))
          root.resolvedOptions = root.normalizeAll(combined)
        }
        root.recomputeFiltered()
        root.loadingOptions = false
        refreshTimeoutTimer.stop()
      }
    }

    onRunningChanged: if (running) seq = root.refreshSeq

    onExited: function(exitCode, exitStatus) {
      if (seq !== root.refreshSeq) return
      refreshTimeoutTimer.stop()
      if (exitCode !== 0) {
        root.loadingOptions = false
        root.optionsError = Commons.I18n.t("multiSelect.exited").arg(Commons.I18n.formatNumber(exitCode))
      }
    }
  }

  implicitWidth: Style.spacing.searchableDropdownWidth
  implicitHeight: showLabel && label !== "" ? rowHeight + Style.spacing.huge : rowHeight

  Column {
    anchors.fill: parent
    spacing: Style.spacing.labelGap

    Text {
      textFormat: Text.PlainText
      visible: root.showLabel && root.label !== ""
      text: root.label
      color: Qt.darker(root.foreground, 1.4)
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
    }

    BorderSurface {
      id: trigger
      readonly property Item attachedWindowItem: MultiSelectUtils.windowContentItem(Window.window)
      width: parent.width
      height: root.rowHeight
      radius: Style.cornerRadius

      readonly property bool _focused: trigger.activeFocus
      readonly property bool _hot: triggerHover.hovered || root.hasCursor
      readonly property var _borderSpec: Border.controlSpec(trigger._focused ? "focus" : (trigger._hot ? "hover-cursor" : "normal"), root.foreground, root.accent)

      color: Style.controlFill(trigger._focused, trigger._hot, root.foreground, root.accent)
      borderSpec: _borderSpec

      activeFocusOnTab: true

      HoverHandler {
        id: triggerHover
        onHoveredChanged: root.hovered(hovered)
      }

      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
            || event.key === Qt.Key_Space || event.key === Qt.Key_Down || event.text === "j") {
          popup.opened ? popup.close() : popup.open()
          event.accepted = true
        } else if (event.key === Qt.Key_Escape && popup.opened) {
          popup.close(); event.accepted = true
        }
      }

      Text {
        textFormat: Text.PlainText
        anchors.left: parent.left
        anchors.right: chevron.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: trigger.borderLeft + Style.spacing.controlPaddingX
        anchors.rightMargin: trigger.borderRight + Style.spacing.md
        text: root.selectionLabel() || root.triggerLabel || root.noSelectionText
        color: root.selectionLabel() ? root.foreground : Qt.darker(root.foreground, 1.5)
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        elide: Text.ElideRight
      }

      Text {
        id: chevron
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: trigger.borderRight + Style.spacing.controlGap
        text: "󰅀"
        color: Qt.darker(root.foreground, 1.2)
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        // CloseOnPressOutsideParent treats a press on the trigger as inside,
        // so the popup is still open here and a second click collapses it
        // instead of reopening.
        onClicked: {
          trigger.forceActiveFocus()
          popup.opened ? popup.close() : popup.open()
        }
      }

      QQC.Popup {
        id: popup
        closePolicy: QQC.Popup.CloseOnPressOutsideParent | QQC.Popup.CloseOnEscape
        // Keep the trigger as the logical parent so CloseOnPressOutsideParent
        // treats a press on the trigger as inside, leaving the toggle to the
        // trigger's onClicked. The popup item is still rendered in the window
        // overlay, so it is not clipped by the trigger's ancestors. Position
        // and available height are recomputed on open and any time the
        // trigger's geometry changes, since a binding on mapToItem alone
        // won't reliably re-evaluate when ancestors scroll or resize.
        parent: trigger
        property real _anchorX: 0
        property real _anchorY: 0
        property real _availableBelow: 0
        readonly property Item _windowItem: trigger.attachedWindowItem
        readonly property real _windowHeight: _windowItem ? _windowItem.height : 0
        readonly property real _idealContent: resultList.contentHeight + Style.space(50)
        readonly property real _maxRowsHeight: root.popupRowHeight * 6 + 5 * Style.spacing.labelGap + Style.space(50)

        function reposition() {
          if (!parent) return
          var p = trigger.mapToItem(parent, 0, trigger.height + Style.spacing.xxs)
          _anchorX = p.x
          _anchorY = p.y
          // _anchorY is relative to the trigger; the clamp below needs the
          // anchor in window coordinates.
          var win = _windowItem ? trigger.mapToItem(_windowItem, 0, trigger.height + Style.spacing.xxs) : p
          _availableBelow = Math.max(0, _windowHeight - win.y - Style.space(12))
        }

        x: _anchorX
        y: _anchorY
        width: trigger.width
        // Clamp to whatever fits below the trigger; don't force popupMinHeight
        // when there isn't room, otherwise the popup overflows the window.
        implicitHeight: Math.min(_availableBelow, _idealContent, _maxRowsHeight)
        padding: Style.spacing.hairline
        leftPadding: Border.left(root.popupBorderSpec) + Style.spacing.hairline
        rightPadding: Border.right(root.popupBorderSpec) + Style.spacing.hairline
        topPadding: Border.top(root.popupBorderSpec) + Style.spacing.hairline
        bottomPadding: Border.bottom(root.popupBorderSpec) + Style.spacing.hairline
        focus: true

        Connections {
          target: trigger
          function onXChanged() { popup.reposition() }
          function onYChanged() { popup.reposition() }
          function onWidthChanged() { popup.reposition() }
          function onHeightChanged() { popup.reposition() }
        }

        background: BorderSurface {
          color: root.background
          borderSpec: root.popupBorderSpec
          radius: Style.cornerRadius
        }

        onOpened: {
          reposition()
          searchField.text = ""
          root.refresh()
          root.recomputeFiltered()
          Qt.callLater(function() { searchField.forceActiveFocus() })
        }
        onClosed: searchField.text = ""

        contentItem: Column {
          spacing: 0

          Item {
            id: searchHeader
            width: parent.width
            height: root.popupRowHeight + Style.spacing.controlPaddingX

            Row {
              id: searchHeaderRow
              anchors.fill: parent
              anchors.margins: Style.spacing.md
              spacing: Style.spacing.rowGap

              TextField {
                id: searchField
                width: parent.width - refreshButton.width - searchHeaderRow.spacing
                height: parent.height
                placeholderText: root.placeholderText
                foreground: root.foreground
                accent: root.accent
                font.family: root.fontFamily
                font.pixelSize: Style.font.body

                onTextChanged: {
                  root.recomputeFiltered()
                  if (resultList.count > 0) resultList.currentIndex = 0
                }

                Keys.onPressed: function(event) {
                  if (event.key === Qt.Key_Escape) {
                    popup.close(); event.accepted = true
                  } else if (event.key === Qt.Key_Down) {
                    if (resultList.count > 0) {
                      resultList.currentIndex = 0
                      resultList.forceActiveFocus()
                    }
                    event.accepted = true
                  } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    if (resultList.count > 0) {
                      resultList.currentIndex = 0
                      resultList.toggleCurrent()
                    }
                    event.accepted = true
                  }
                }
              }

              BorderSurface {
                id: refreshButton
                visible: root.arrayLength(root.arrayFrom(root.optionsCommand)) > 0
                enabled: !root.loadingOptions
                width: parent.height
                height: parent.height
                radius: Style.cornerRadius
                color: refreshHover.hovered
                  ? Style.hoverFillFor(root.foreground, root.accent, Commons.Color.urgent)
                  : Style.normalFillFor(root.foreground, root.accent, Commons.Color.urgent)
                borderSpec: refreshHover.hovered
                  ? Border.controlSpec("hover-cursor", root.foreground, root.accent)
                  : Border.controlSpec("normal", root.foreground, root.accent)

                Text {
                  textFormat: Text.PlainText
                  anchors.centerIn: parent
                  text: root.loadingOptions ? "󰦖" : "󰑐"
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body

                  RotationAnimator on rotation {
                    running: root.loadingOptions && !Style.reduceMotion
                    from: 0; to: 360
                    duration: Style.duration(800)
                    loops: Animation.Infinite
                  }
                }

                HoverHandler { id: refreshHover }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.refresh()
                }
              }
            }
          }

          Rectangle {
            width: parent.width
            height: 1
            color: Util.alpha(root.foreground, 0.10)
          }

          Item {
            width: parent.width
            height: popup.height - searchHeader.height - Style.spacing.xxs - 1

            Text {
              textFormat: Text.PlainText
              anchors.centerIn: parent
              visible: resultList.count === 0
              text: root.loadingOptions ? Commons.I18n.t("common.loading") : (root.optionsError !== "" ? root.optionsError : root.emptyText)
              color: Qt.darker(root.foreground, 1.6)
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
            }

            ListView {
              id: resultList
              anchors.fill: parent
              spacing: Style.spacing.labelGap
              clip: true
              boundsBehavior: Flickable.StopAtBounds
              model: root.filtered
              currentIndex: -1
              keyNavigationEnabled: false

              function toggleCurrent(): void {
                if (currentIndex < 0 || currentIndex >= root.arrayLength(root.filtered)) return
                root.toggleValue(root.filtered[currentIndex].value)
              }

              Keys.priority: Keys.BeforeItem
              Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Escape) {
                  popup.close(); event.accepted = true
                } else if (event.key === Qt.Key_Down || event.text === "j") {
                  if (resultList.currentIndex >= resultList.count - 1) {
                    event.accepted = true; return
                  }
                  resultList.currentIndex = resultList.currentIndex + 1
                  event.accepted = true
                } else if (event.key === Qt.Key_Up || event.text === "k") {
                  if (resultList.currentIndex <= 0) {
                    searchField.forceActiveFocus()
                    event.accepted = true; return
                  }
                  resultList.currentIndex = resultList.currentIndex - 1
                  event.accepted = true
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                           || event.key === Qt.Key_Space) {
                  resultList.toggleCurrent(); event.accepted = true
                }
              }

              delegate: Rectangle {
                id: resultRow
                required property var modelData
                required property int index

                readonly property bool selected: root.isSelected(root.fieldValue(modelData, "value"))

                width: resultList.width
                height: Math.max(root.popupRowHeight, rowContent.implicitHeight + Style.spacing.rowPaddingX)
                color: index === resultList.currentIndex
                  ? Style.hoverFillFor(root.foreground, root.accent, Commons.Color.urgent)
                  : "transparent"

                Row {
                  id: rowContent
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.leftMargin: Style.spacing.controlPaddingX
                  anchors.rightMargin: Style.spacing.controlPaddingX
                  spacing: Style.spacing.rowGap

                  BorderSurface {
                    id: checkbox
                    width: Style.space(16)
                    height: Style.space(16)
                    radius: Math.max(2, Style.cornerRadius / 2)
                    anchors.verticalCenter: parent.verticalCenter
                    color: resultRow.selected ? Style.selectedFillFor(root.foreground, root.accent, Commons.Color.urgent) : "transparent"
                    borderSpec: resultRow.selected
                      ? Border.controlSpec("selected", root.foreground, root.accent)
                      : Border.controlSpec("normal", root.foreground, root.accent)

                    Text {
                      anchors.centerIn: parent
                      visible: resultRow.selected
                      text: "✓"
                      color: Style.selectedStateColor(root.foreground, root.accent, Commons.Color.urgent)
                      font.family: root.fontFamily
                      font.pixelSize: Math.round(checkbox.height * 0.85)
                      font.bold: true
                    }
                  }

                  Column {
                    width: parent.width - checkbox.width - rowContent.spacing
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Style.spacing.xxs

                    Text {
                      textFormat: Text.PlainText
                      text: root.fieldValue(resultRow.modelData, "label")
                      color: resultRow.index === resultList.currentIndex ? Style.hoverStateColor(root.foreground, root.accent, Commons.Color.urgent) : root.foreground
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.body
                      elide: Text.ElideRight
                      width: parent.width
                    }
                    Text {
                      textFormat: Text.PlainText
                      visible: text !== ""
                      text: root.fieldValue(resultRow.modelData, "description")
                      color: Qt.darker(root.foreground, 1.5)
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      elide: Text.ElideRight
                      width: parent.width
                    }
                  }
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onPositionChanged: resultList.currentIndex = resultRow.index
                  onClicked: root.toggleValue(root.fieldValue(resultRow.modelData, "value"))
                }
              }
            }
          }
        }
      }
    }
  }
}
