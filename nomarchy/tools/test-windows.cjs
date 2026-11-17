const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")
const vm = require("node:vm")

function load(file) {
  const context = vm.createContext({})
  const source = fs.readFileSync(path.join(__dirname, "..", file), "utf8").replace(".pragma library", "")
  vm.runInContext(source, context)
  return context
}

const search = load("plugins/menu/WindowsSearch.js")
for (const [query, expected] of [
  ["2+2", "4"], ["2*(3+4)", "14"], ["-2.5*4", "-10"], [".5+0.25", "0.75"],
  ["1/0", ""], ["1+", ""], ["1+abc", ""], ["2**3", ""], ["1+2)", ""]
]) {
  assert.equal(search.calculate(query), expected, query)
}

const windows = [{ hwnd: 42, title: "Editor", appId: "code", activate() { this.activated = true } }]
assert.equal(search.results("edit", windows)[0].action, "42")
assert.equal(search.results("code", windows)[0].label, "Editor")
assert.equal(search.results("missing", windows).length, 0)
search.activateWindow(windows, "42")
assert.equal(windows[0].activated, true)
search.activateWindow([], "42")

const bar = load("plugins/bar/BarModel.js")
const warmTimer = { running: false }
const delayTimer = { starts: 0, restart() { this.starts++ } }
const callbacks = []
const target = { hovered: true }
const tooltip = {
  tooltipShown: false, tooltipRequest: 0,
  targetTooltipHovered(item) { return !!item && item.hovered },
  clearTooltip() {
    if (this.tooltipShown) warmTimer.running = true
    this.tooltipShown = false
    this.pendingTooltipTarget = null
    this.pendingTooltipText = ""
    this.tooltipTarget = null
    this.tooltipText = ""
  }
}
const showTooltip = (item, text) => bar.showTooltip(tooltip, item, text, fn => callbacks.push(fn), warmTimer, delayTimer)
showTooltip(target, "First")
callbacks.shift()()
assert.equal(delayTimer.starts, 1)
assert.equal(tooltip.tooltipText, "First")
tooltip.tooltipShown = true
showTooltip(target, "Second")
callbacks.shift()()
assert.equal(tooltip.tooltipShown, true)
assert.equal(tooltip.tooltipText, "Second")
warmTimer.running = false
tooltip.tooltipShown = false
showTooltip(target, "Stale")
showTooltip(target, "Latest")
callbacks.shift()()
assert.equal(tooltip.tooltipText, "")
callbacks.shift()()
assert.equal(tooltip.tooltipText, "Latest")
target.hovered = false
showTooltip(target, "Not hovered")
assert.equal(tooltip.tooltipTarget, null)

const workspaces = load("plugins/bar/widgets/WorkspacesModel.js")
const slots = workspaces.slots({
  workspaces: [{}, {}, {}, { active: true }]
}, 5)
assert.equal(workspaces.canFocus(slots[4]), true, "clicking a placeholder must allow desktop creation")
assert.equal(workspaces.canFocus(slots[0]), true, "existing inactive desktops remain clickable")
assert.equal(workspaces.canFocus(slots[3]), false, "clicking the active desktop remains a no-op")
const focusedWorkspaces = []
const workspaceRoot = {
  slots, wheelAccumulator: 0,
  focusWorkspace(number) { focusedWorkspaces.push(number) }
}
workspaces.scroll(workspaceRoot, -120, { steps: -1, remainder: 0 })
assert.deepEqual(focusedWorkspaces, [], "scrolling must not create a desktop")
workspaces.scroll(workspaceRoot, 120, { steps: 1, remainder: 0 })
assert.deepEqual(focusedWorkspaces, [3], "scrolling still focuses an existing desktop")

const tray = load("plugins/bar/widgets/TrayModel.js")
const items = [
  { id: "pinned", status: 1 }, { id: "flyout", status: 1 },
  { id: "hidden", status: 1 }, { id: "passive", status: 0 }
]
const bucket = category => Array.from(
  tray.bucket(items, category, ["pinned"], ["hidden"], () => false, 0), item => item.id
)
assert.deepEqual(bucket("pinned"), ["pinned"])
assert.deepEqual(bucket("drawer"), ["flyout"])
assert.deepEqual(bucket("all"), ["pinned", "flyout", "hidden"])
assert.equal(tray.moveSelection(0, 0, 1, 4, 10), 4)
assert.equal(tray.moveSelection(8, 0, 1, 4, 10), 9)
assert.equal(tray.moveSelection(0, -1, 0, 4, 10), 0)
assert.equal(tray.moveSelection(0, 1, 0, 4, 0), -1)
assert.equal(tray.popupWidth(1, 27, 8, 2, 2), 47)
assert.equal(tray.popupWidth(4, 27, 8, 2, 2), 128)
assert.equal(tray.popupWidth(6, 27, 8, 2, 2), 182)
assert.equal(tray.popupWidth(12, 27, 8, 2, 2), 182)
assert.equal(tray.popupWidth(0, 27, 8, 2, 2), 182)

const config = JSON.parse(fs.readFileSync(path.join(__dirname, "..", "config", "nomarchy", "shell.json"), "utf8"))
const right = config.bar.layout.right.map(item => item.id)
assert.equal(right.indexOf("nomarchy.controls"), right.indexOf("nomarchy.tray") + 1)

const theme = load("services/WallpaperTheme.js")
const colors = {
  surface: "#111111", onSurface: "#eeeeee", primary: "#aabbcc", outline: "#777777",
  surfaceVariant: "#333333", error: "#ff0000", secondary: "#00ff00", tertiary: "#0000ff"
}
assert.equal(theme.palette({ valid: false }, true), "")
assert.equal(theme.palette({ valid: true, dark: false, colors }, true), "")
assert.equal(JSON.parse(theme.palette({ valid: true, dark: true, colors }, true)).accent, "#aabbcc")
colors.primary = "invalid"
assert.equal(theme.palette({ valid: true, dark: true, colors }, true), "")
console.log("Nomarchy Windows search, tooltip, workspaces, tray and palette tests passed")
