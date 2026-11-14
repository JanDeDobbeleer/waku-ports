pragma ComponentBehavior: Bound
import QtQuick
import qs.Commons
import qs.Commons as Commons
import "ButtonGroupUtils.js" as ButtonGroupUtils

// Mutually-exclusive row of Buttons — the form-style "pick one of N"
// pattern (bar position top/right/bottom/left, theme preset chips, etc.).
// Emits `changed(value)` when the user activates a different option.
//
// `options` is either a plain string[] (label == value) or an array of
// { value, label, icon?, tooltip? } objects. Mixing is fine.
//
// Keyboard navigation. The group itself is a single Tab stop, not one
// stop per chip — so in a form that walks `activeFocusOnTab` items with
// Tab / j / k, the cursor enters the group as a unit. Once focused,
// h / l / Left / Right walks between chips and Enter / Space activates
// the current one. The selected chip is the default landing point so
// users see their existing choice on arrival.
//
// Panel-cursor consumers (the bar widget panels) drive `cursorIndex`
// directly and listen on `hovered` to sync the mouse — Tab focus and
// `cursorIndex` are independent; either one paints the chip's hot
// state, and the bar widget panels never give Tab focus to a
// ButtonGroup so they only see the cursorIndex path.
Row {
  id: root

  property var options: []
  property string value: ""
  property color foreground: Commons.Color.foreground
  property color background: Commons.Color.background
  property color accent: Commons.Color.accent
  property string fontFamily: Style.font.family
  property real fontSize: Style.font.body
  property bool focusable: true

  // -1 disables the external cursor highlight (the panel-cursor case).
  // Driven by a containing panel; the group's own Tab-focus h/l
  // tracking is internal and lives in _focusedIndex.
  property int cursorIndex: -1

  // Internal: which chip h / l / Left / Right is currently sitting on
  // when the group itself has Tab focus. Reset to the selected option
  // each time focus arrives so the user sees their existing choice.
  property int _focusedIndex: -1

  signal changed(string value)
  signal hovered(int index, bool isHovered)

  spacing: Style.spacing.md

  activeFocusOnTab: focusable

  function optionValue(o: var): string {
    return o && typeof o === "object" ? String(ButtonGroupUtils.field(o, "value")) : String(o)
  }
  function optionLabel(o: var): string {
    var label = ButtonGroupUtils.field(o, "label")
    return o && typeof o === "object" && label !== undefined ? String(label) : String(o)
  }
  function optionIcon(o: var): string {
    var icon = ButtonGroupUtils.field(o, "icon")
    return o && typeof o === "object" && icon ? String(icon) : ""
  }
  function optionTooltip(o: var): string {
    var tooltip = ButtonGroupUtils.field(o, "tooltip")
    return o && typeof o === "object" && tooltip ? String(tooltip) : ""
  }

  function optionCount(): int { return ButtonGroupUtils.arrayLength(options) }
  function optionAt(index: int): var { return ButtonGroupUtils.arrayAt(options, index) }

  function selectedOptionIndex(): int {
    for (let i = 0; i < optionCount(); i++)
      if (optionValue(optionAt(i)) === value) return i
    return -1
  }

  function activateFocused(): void {
    if (_focusedIndex < 0 || _focusedIndex >= optionCount()) return
    var v = optionValue(optionAt(_focusedIndex))
    root.changed(v)
  }

  onActiveFocusChanged: {
    if (activeFocus) {
      let idx = selectedOptionIndex()
      _focusedIndex = idx < 0 ? 0 : idx
    } else {
      _focusedIndex = -1
    }
  }

  Keys.priority: Keys.BeforeItem
  Keys.onPressed: function(event) {
    if (Util.readingKey(event, true) === Qt.Key_Left) {
      _focusedIndex = Math.max(0, (_focusedIndex < 0 ? 0 : _focusedIndex) - 1)
      event.accepted = true
    } else if (Util.readingKey(event, true) === Qt.Key_Right) {
      let max = optionCount() - 1
      let next = (_focusedIndex < 0 ? 0 : _focusedIndex) + 1
      _focusedIndex = Math.min(max, next)
      event.accepted = true
    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
        || event.key === Qt.Key_Space) {
      activateFocused()
      event.accepted = true
    }
  }

  Repeater {
    model: root.options

    delegate: Button {
      required property var modelData
      required property int index
      text: root.optionLabel(modelData)
      iconText: root.optionIcon(modelData)
      tooltipText: root.optionTooltip(modelData)
      selected: root.optionValue(modelData) === root.value
      // Chip lights up when either the external panel cursor lands here
      // or the group has Tab focus and h/l has walked to this index.
      hasCursor: root.cursorIndex === index
        || (root.activeFocus && root._focusedIndex === index)
      // Every chip carries the standard bordered-button chrome so the
      // group reads as a row of distinct options. selected / hover-cursor /
      // focus are all painted by Button from Style's shared state tokens.
      bordered: true
      foreground: root.foreground
      background: root.background
      accent: root.accent
      fontFamily: root.fontFamily
      fontSize: root.fontSize
      onClicked: root.changed(root.optionValue(modelData))
      onHovered: function(h) { root.hovered(index, h) }
    }
  }
}
