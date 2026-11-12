pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "nomarchy.tailscale"
  ipcTarget: "nomarchy.tailscale"
  manageIpc: false

  // Items inside the panel's lazily built content, null until it first
  // opens. Code inside the content reaches its own ids directly.
  readonly property Flickable panelFlick: panel.loadedContent ? Model.field(panel.loadedContent as LazyContent, "panelFlick") as Flickable : null
  readonly property PanelHero hero: panel.loadedContent ? Model.field(panel.loadedContent as LazyContent, "hero") as PanelHero : null
  readonly property Column exitNodeColumn: panel.loadedContent ? Model.field(panel.loadedContent as LazyContent, "exitNodeColumn") as Column : null
  readonly property TextField mullvadSearch: panel.loadedContent ? Model.field(panel.loadedContent as LazyContent, "mullvadSearch") as TextField : null
  readonly property Column mullvadRegionColumn: panel.loadedContent ? Model.field(panel.loadedContent as LazyContent, "mullvadRegionColumn") as Column : null
  readonly property TextField peerSearch: panel.loadedContent ? Model.field(panel.loadedContent as LazyContent, "peerSearch") as TextField : null
  readonly property RememberingListView peerList: panel.loadedContent ? Model.field(panel.loadedContent as LazyContent, "peerList") as RememberingListView : null
  readonly property Popup sharedCopyPopup: panel.loadedContent ? Model.field(panel.loadedContent as LazyContent, "sharedCopyPopup") as Popup : null

  property string focusSection: "header"
  property int headerIndex: 0
  property int accountIndex: 0
  property int peerIndex: 0
  property int exitNodeIndex: 0
  property int mullvadRegionIndex: 0
  property bool cursorActive: false
  property bool copyMenuOpen: false
  property bool mullvadPickerOpen: false
  property string mullvadQuery: ""
  property int phraseIndex: 0
  readonly property var activePhrases: [
    Commons.I18n.t("tailscale.phrase1"),
    Commons.I18n.t("tailscale.phrase2"),
    Commons.I18n.t("tailscale.phrase3"),
    Commons.I18n.t("tailscale.phrase4"),
    Commons.I18n.t("tailscale.phrase5"),
    Commons.I18n.t("tailscale.phrase6"),
    Commons.I18n.t("tailscale.phrase7"),
    Commons.I18n.t("tailscale.phrase8"),
    Commons.I18n.t("tailscale.phrase9"),
    Commons.I18n.t("tailscale.phrase10")
  ]
  readonly property string heroPhraseText: activePhrases[phraseIndex % root.arrayLength(activePhrases)]

  readonly property color foreground: bar ? BarValues.foreground(bar) : Commons.Color.foreground
  readonly property color urgent: bar ? BarValues.urgent(bar) : Commons.Color.urgent
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? BarValues.fontFamily(bar) : Style.font.family
  readonly property bool showConnections: root.arrayLength(tailscale.accounts) > 1 || tailscale.accountsAccessDenied
  readonly property bool showPeers: tailscale.active && root.arrayLength(filteredPeers) > 0
  readonly property var recentMullvadRegions: Model.recentRegions(settings)
  readonly property var recentMullvadExitNodes: recentMullvadNodes()
  readonly property var exitNodes: displayExitNodes()
  readonly property bool showExitNodes: tailscale.active && (root.arrayLength(exitNodes) > 0 || root.arrayLength(tailscale.mullvadRegions) > 0)
  readonly property var filteredMullvadRegions: filteredMullvadRegionNodes()
  // Only claim the header cursor when the switch is actually on screen —
  // "header" stays navigable, but an absent CLI leaves nothing to highlight.
  readonly property bool headerHasCursor: cursorActive && focusSection === "header" && tailscale.installed
  readonly property color iconColor: tailscale.active ? foreground : dim
  readonly property string toggleHint: tailscale.active ? Commons.I18n.t("tailscale.turnOff") : (tailscale.needsLogin ? Commons.I18n.t("tailscale.authorizeDevice") : Commons.I18n.t("tailscale.turnOn"))
  readonly property color barIconColor: tailscale.active ? barForeground : Qt.darker(barForeground, 1.55)
  readonly property color hoverFill: bar ? Style.hoverFillFor(BarValues.foreground(bar), Commons.Color.accent) : "transparent"
  readonly property color selectedFill: bar ? Style.selectedFillFor(BarValues.foreground(bar), Commons.Color.accent) : "transparent"

  // Large tailnets: the machine list renders through a virtualized
  // ListView over this filtered view instead of one eager row per peer.
  property string peerQuery: ""
  readonly property var filteredPeers: {
    var query = peerQuery.trim().toLowerCase()
    if (query === "") return tailscale.peers
    var result = []
    for (let i = 0; i < root.arrayLength(tailscale.peers); i++) {
      let p = tailscale.peers[i]
      let ip = Model.field(p, "TailscaleIPs") && root.arrayLength(Model.field(p, "TailscaleIPs")) > 0 ? String(Model.field(p, "TailscaleIPs")[0]) : ""
      let hay = (String(Model.field(p, "DisplayName") || "") + " " + String(Model.field(p, "DNSName") || "") + " " + ip).toLowerCase()
      if (hay.indexOf(query) !== -1) result.push(p)
    }
    return result
  }

  // One shared copy menu for whichever row summoned it, instead of a Popup
  // instantiated inside every machine row.
  property var copyPeer: null
  property int copyIndex: 0
  readonly property var copyOptions: copyOptionsFor(copyPeer)

  function copyOptionsFor(peer: var): var { return Model.copyOptionsFor(peer) }
  function arrayLength(value: var): int { return Model.arrayLength(value) }
  function fieldValue(object: var, name: string): var { return Model.field(object, name) }
  function setFieldValue(object: var, name: string, value: var): void { Model.setField(object, name, value) }
  function callMethod(object: var, name: string): void { Model.callMethod(object, name) }

  function clampCopyIndex(): void {
    copyIndex = Math.max(0, Math.min(copyIndex, root.arrayLength(copyOptions) - 1))
  }

  function moveCopyCursor(delta: int): void {
    if (root.arrayLength(copyOptions) === 0) return
    copyIndex = Math.max(0, Math.min(root.arrayLength(copyOptions) - 1, copyIndex + delta))
  }

  function copyOption(kind: string): void {
    var peer = copyPeer
    if (peer) {
      if (kind === "name") tailscale.copyPeerName(peer)
      else if (kind === "dns") tailscale.copyPeerDnsName(peer)
      else if (kind === "ipv6") {
        let ipv6 = Model.field(peer, "TailscaleIPv6") && root.arrayLength(Model.field(peer, "TailscaleIPv6")) > 0 ? String(Model.field(peer, "TailscaleIPv6")[0] || "") : ""
        tailscale.copyToClipboard(ipv6, String(Model.field(peer, "DisplayName") || Model.field(peer, "HostName") || "") + " IPv6")
      } else if (kind === "ip") tailscale.copyPeerIp(peer)
    }
    if (sharedCopyPopup) Model.callMethod(sharedCopyPopup, "close")
  }

  function copyCurrentOption(): void {
    clampCopyIndex()
    if (root.arrayLength(copyOptions) === 0) return
    copyOption(copyOptions[copyIndex].kind)
  }

  function openCopyMenuFor(peer: var, row: Item): void {
    if (!peer || !peerList || !sharedCopyPopup || root.arrayLength(copyOptionsFor(peer)) === 0) return
    // The popup is shared across rows, so a cursor position left over from
    // another machine's menu must not carry into this one.
    if (!copyPeer || String(Model.field(copyPeer, "id") || "") !== String(Model.field(peer, "id") || "")) copyIndex = 0
    copyPeer = peer
    clampCopyIndex()
    var anchor = row || peerList
    var pointX = Model.mapToItemX(anchor, peerList, 0, anchor.height)
    var pointY = Model.mapToItemY(anchor, peerList, 0, anchor.height)
    // Opens toward the row, from whichever end its copy button sits at.
    var x = peerList.LayoutMirroring.enabled ? pointX : pointX + anchor.width - sharedCopyPopup.width
    sharedCopyPopup.x = Math.max(0, Math.min(peerList.width - sharedCopyPopup.width, x))
    sharedCopyPopup.y = pointY + Style.space(4)
    Model.callMethod(sharedCopyPopup, "open")
  }

  function selectedPeer(): var {
    if (root.arrayLength(filteredPeers) === 0) return null
    return filteredPeers[Math.max(0, Math.min(peerIndex, root.arrayLength(filteredPeers) - 1))]
  }

  function selectedExitNode(): var {
    if (root.arrayLength(exitNodes) === 0) return null
    return exitNodes[Math.max(0, Math.min(exitNodeIndex, root.arrayLength(exitNodes) - 1))]
  }

  function selectedMullvadRegion(): var {
    if (root.arrayLength(filteredMullvadRegions) === 0) return null
    return filteredMullvadRegions[Math.max(0, Math.min(mullvadRegionIndex, root.arrayLength(filteredMullvadRegions) - 1))]
  }

  function displayExitNodes(): var {
    var nodes = []
    for (let i = 0; i < root.arrayLength(tailscale.tailnetExitNodes); i++) nodes.push(tailscale.tailnetExitNodes[i])
    for (let j = 0; j < root.arrayLength(recentMullvadExitNodes); j++) nodes.push(recentMullvadExitNodes[j])
    if (root.arrayLength(tailscale.mullvadRegions) > 0) nodes.push({ id: "mullvad:add", AddMullvad: true, DisplayName: Commons.I18n.t("tailscale.chooseMullvadRegion") })
    return nodes
  }

  function recentMullvadNodes(): var {
    var nodes = []
    var seen = {}
    for (let a = 0; a < root.arrayLength(tailscale.mullvadRegions) && nodes.length < 5; a++) {
      let active = tailscale.mullvadRegions[a]
      let activeKey = mullvadRegionKey(active)
      if (Model.field(active, "ExitNode") === true && activeKey !== "" && !seen[activeKey]) {
        nodes.push(active)
        seen[activeKey] = true
      }
    }
    for (let i = 0; i < root.arrayLength(recentMullvadRegions) && nodes.length < 5; i++) {
      let region = String(recentMullvadRegions[i] || "")
      if (region === "" || seen[region]) continue
      let node = mullvadRegionNode(region)
      if (node) {
        nodes.push(node)
        seen[region] = true
      }
    }
    return nodes
  }

  function mullvadRegionKey(node: var): string {
    if (!node) return ""
    var country = String(Model.field(node, "Country") || "")
    var city = String(Model.field(node, "City") || "")
    if (country === "" || city === "") return ""
    return country + "\n" + city
  }

  function mullvadRegionNode(region: string): var {
    for (let i = 0; i < root.arrayLength(tailscale.mullvadRegions); i++) {
      let node = tailscale.mullvadRegions[i]
      if (mullvadRegionKey(node) === String(region || "")) return node
      if (String(Model.field(node, "Country") || "") === String(region || "")) return node
    }
    return null
  }

  function filteredMullvadRegionNodes(): var {
    var query = String(mullvadQuery || "").trim().toLowerCase()
    var result = []
    for (let i = 0; i < root.arrayLength(tailscale.mullvadRegions); i++) {
      let node = tailscale.mullvadRegions[i]
      let label = (String(Model.field(node, "City") || "") + " " + String(Model.field(node, "Country") || "")).toLowerCase()
      if (query === "" || label.indexOf(query) !== -1) result.push(node)
    }
    return result
  }

  function mullvadRegionTitle(peer: var): string {
    if (!peer) return Commons.I18n.t("tailscale.unknown")
    var city = String(Model.field(peer, "City") || "").trim()
    var country = String(Model.field(peer, "Country") || "").trim()
    if (city === "" || city === "Any") return country || String(Model.field(peer, "DisplayName") || Commons.I18n.t("tailscale.unknown"))
    return city
  }

  function mullvadRegionSubtitle(peer: var): string {
    if (!peer) return ""
    return String(Model.field(peer, "Country") || "").trim()
  }

  function persistRecentMullvad(region: string): void {
    var name = String(region || "")
    if (name === "") return
    var next = [name]
    for (let i = 0; i < root.arrayLength(recentMullvadRegions) && next.length < 5; i++) {
      let existing = String(recentMullvadRegions[i] || "")
      if (existing !== "" && existing !== name && next.indexOf(existing) === -1) next.push(existing)
    }
    if (!BarValues.hasUpdateEntryInline(root.bar)) return
    var entry = { id: root.moduleName }
    for (let key in settings) if (key !== "id") entry[key] = settings[key]
    entry.recentMullvadRegions = next
    BarValues.updateEntryInline(root.bar, root.moduleName, entry)
  }

  function chooseExitNode(peer: var): void {
    if (!peer) return
    if (Model.field(peer, "AddMullvad") === true) {
      mullvadPickerOpen = !mullvadPickerOpen
      mullvadRegionIndex = 0
      if (mullvadPickerOpen) Qt.callLater(function() { if (mullvadSearch) Model.callMethod(mullvadSearch, "forceActiveFocus") })
      return
    }
    if (Model.field(peer, "Mullvad") === true) persistRecentMullvad(mullvadRegionKey(peer))
    tailscale.setExitNode(peer)
    mullvadPickerOpen = false
  }

  function selectedAccount(): var {
    if (root.arrayLength(tailscale.accounts) === 0) return null
    return tailscale.accounts[Math.max(0, Math.min(accountIndex, root.arrayLength(tailscale.accounts) - 1))]
  }

  function ensureCursor(): void {
    if (headerIndex < 0) headerIndex = 0
    if (headerIndex > 0) headerIndex = 0
    if (accountIndex >= root.arrayLength(tailscale.accounts)) accountIndex = Math.max(0, root.arrayLength(tailscale.accounts) - 1)
    if (peerIndex >= root.arrayLength(filteredPeers)) peerIndex = Math.max(0, root.arrayLength(filteredPeers) - 1)
    if (exitNodeIndex >= root.arrayLength(exitNodes)) exitNodeIndex = Math.max(0, root.arrayLength(exitNodes) - 1)
    if (mullvadRegionIndex >= root.arrayLength(filteredMullvadRegions)) mullvadRegionIndex = Math.max(0, root.arrayLength(filteredMullvadRegions) - 1)
    if (focusSection === "auth" && !tailscale.accountsAccessDenied) focusSection = root.arrayLength(tailscale.accounts) > 1 ? "accounts" : (showExitNodes ? "exitNodes" : (showPeers ? "peers" : "header"))
    if (focusSection === "accounts" && root.arrayLength(tailscale.accounts) <= 1) focusSection = tailscale.accountsAccessDenied ? "auth" : (showExitNodes ? "exitNodes" : (showPeers ? "peers" : "header"))
    if (focusSection === "peers" && !showPeers) focusSection = showExitNodes ? "exitNodes" : (tailscale.accountsAccessDenied ? "auth" : (root.arrayLength(tailscale.accounts) > 1 ? "accounts" : "header"))
    if (focusSection === "exitNodes" && !showExitNodes) focusSection = showPeers ? "peers" : (tailscale.accountsAccessDenied ? "auth" : (root.arrayLength(tailscale.accounts) > 1 ? "accounts" : "header"))
  }

  function moveCursor(dx: int, dy: int): void {
    cursorActive = true
    ensureCursor()
    if (dy !== 0) {
      if (focusSection === "header") {
        if (dy > 0) {
          if (tailscale.accountsAccessDenied) focusSection = "auth"
          else if (root.arrayLength(tailscale.accounts) > 1) focusSection = "accounts"
          else if (showExitNodes) focusSection = "exitNodes"
          else if (showPeers) focusSection = "peers"
        }
      } else if (focusSection === "auth") {
        if (dy < 0) focusSection = "header"
        else if (root.arrayLength(tailscale.accounts) > 1) focusSection = "accounts"
        else if (showExitNodes) focusSection = "exitNodes"
        else if (showPeers) focusSection = "peers"
      } else if (focusSection === "accounts") {
        if (dy < 0) {
          if (accountIndex <= 0) focusSection = tailscale.accountsAccessDenied ? "auth" : "header"
          else accountIndex--
        } else {
          if (accountIndex < root.arrayLength(tailscale.accounts) - 1) accountIndex++
          else if (showExitNodes) focusSection = "exitNodes"
          else if (showPeers) focusSection = "peers"
        }
      } else if (focusSection === "peers") {
        if (dy < 0) {
          if (peerIndex <= 0) focusSection = showExitNodes ? "exitNodes" : (root.arrayLength(tailscale.accounts) > 1 ? "accounts" : (tailscale.accountsAccessDenied ? "auth" : "header"))
          else peerIndex--
        } else if (peerIndex < root.arrayLength(filteredPeers) - 1) {
          peerIndex++
        }
      } else if (focusSection === "exitNodes") {
        if (dy < 0) {
          if (exitNodeIndex <= 0) focusSection = root.arrayLength(tailscale.accounts) > 1 ? "accounts" : (tailscale.accountsAccessDenied ? "auth" : "header")
          else exitNodeIndex--
        } else if (exitNodeIndex < root.arrayLength(exitNodes) - 1) {
          exitNodeIndex++
        } else if (showPeers) {
          focusSection = "peers"
        }
      }
    }
    ensureCursor()
    scrollCursorIntoView()
  }

  function activateCursor(): void {
    ensureCursor()
    if (focusSection === "header") {
      tailscale.toggleTailscale()
    } else if (focusSection === "auth") {
      tailscale.authorizeTailscaleOperator()
    } else if (focusSection === "accounts") {
      let account = selectedAccount()
      if (account) tailscale.switchAccount(Model.field(account, "id"))
    } else if (focusSection === "peers") {
      openSelectedPeerCopyMenu()
    } else if (focusSection === "exitNodes") {
      chooseExitNode(selectedExitNode())
    }
  }

  function moveMullvadRegionCursor(delta: int): void {
    if (root.arrayLength(filteredMullvadRegions) === 0) return
    cursorActive = true
    mullvadRegionIndex = Math.max(0, Math.min(root.arrayLength(filteredMullvadRegions) - 1, mullvadRegionIndex + delta))
    scrollMullvadRegionCursorIntoView()
  }

  function activateMullvadRegionCursor(): void {
    var region = selectedMullvadRegion()
    if (region) chooseExitNode(region)
  }

  function scrollItemIntoView(item: Item): void {
    if (!panelFlick || !item) return
    Qt.callLater(function() {
      if (!item) return
      var margin = Style.space(6)
      var point = item.mapToItem(Model.field(panelFlick, "contentItem"), 0, 0)
      var top = point.y
      var bottom = top + item.height
      var viewTop = Model.field(panelFlick, "contentY")
      var viewBottom = viewTop + panelFlick.height
      var maxY = Math.max(0, Model.field(panelFlick, "contentHeight") - panelFlick.height)
      if (top < viewTop + margin) Model.setField(panelFlick, "contentY", Math.max(0, top - margin))
      else if (bottom > viewBottom - margin) Model.setField(panelFlick, "contentY", Math.min(maxY, bottom + margin - panelFlick.height))
    })
  }

  function scrollCursorIntoView(): void {
    if (focusSection === "peers" && peerList && root.arrayLength(filteredPeers) > 0) {
      Model.callMethod(peerList, "positionViewAtIndex", [Math.max(0, Math.min(peerIndex, root.arrayLength(filteredPeers) - 1)), ListView.Contain])
      Model.callMethod(peerList, "rememberPosition")
      scrollItemIntoView(peerList)
    } else if (focusSection === "exitNodes" && exitNodeColumn && exitNodeIndex >= 0 && exitNodeIndex < Model.field(exitNodeColumn, "children").length) scrollItemIntoView(Model.field(exitNodeColumn, "children")[exitNodeIndex])
  }

  function scrollMullvadRegionCursorIntoView(): void {
    if (mullvadRegionColumn && mullvadRegionIndex >= 0 && mullvadRegionIndex < root.arrayLength(Model.field(mullvadRegionColumn, "children"))) scrollItemIntoView(Model.field(mullvadRegionColumn, "children")[mullvadRegionIndex])
  }

  function setPeerCursor(index: int): void {
    cursorActive = true
    focusSection = "peers"
    peerIndex = index
    scrollCursorIntoView()
  }

  // The file picker takes over from here, so get the panel out of the way.
  function sendPeerFile(peer: var): void {
    if (!tailscale.canSendFiles(peer)) return
    tailscale.sendFile(peer)
    close()
  }

  function openSelectedPeerCopyMenu(): void {
    if (root.arrayLength(filteredPeers) === 0 || !peerList) return
    ensureCursor()
    Model.callMethod(peerList, "positionViewAtIndex", [peerIndex, ListView.Contain])
    Model.callMethod(peerList, "rememberPosition")
    openCopyMenuFor(selectedPeer(), Model.callMethod(peerList, "itemAtIndex", [peerIndex]))
  }

  function setExitNodeCursor(index: int): void {
    cursorActive = true
    focusSection = "exitNodes"
    exitNodeIndex = index
    scrollCursorIntoView()
  }

  function setAccountCursor(index: int): void {
    cursorActive = true
    focusSection = "accounts"
    accountIndex = index
  }

  function setAuthCursor(): void {
    cursorActive = true
    focusSection = "auth"
  }

  function setHeaderCursor(): void {
    cursorActive = true
    focusSection = "header"
    headerIndex = 0
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onOpenedChanged: if (opened) {
    cursorActive = false
    if (panelFlick) Model.setField(panelFlick, "contentY", 0)
    if (peerList) {
      peerList.rememberedY = 0
      Model.callMethod(peerList, "positionViewAtBeginning")
    }
    tailscale.refresh(false, true)
    Qt.callLater(function() { if (panel.loadedContent) Model.callMethod(panel.loadedContent, "forceActiveFocus") })
  } else if (peerSearch && Model.field(peerSearch, "text") !== "") {
    // A query must not survive the panel: reopening to a silently filtered
    // list looks like machines are missing.
    Model.setField(peerSearch, "text", "")
  }
  onPeerIndexChanged: scrollCursorIntoView()
  onExitNodeIndexChanged: scrollCursorIntoView()
  onMullvadRegionIndexChanged: if (mullvadPickerOpen) scrollMullvadRegionCursorIntoView()
  onShowConnectionsChanged: ensureCursor()
  onShowPeersChanged: ensureCursor()
  onFilteredPeersChanged: ensureCursor()
  onShowExitNodesChanged: ensureCursor()
  onFilteredMullvadRegionsChanged: ensureCursor()

  Service {
    id: tailscale
    settings: root.settings
    peersWanted: root.opened
  }

  Connections {
    id: serviceEvents
    target: tailscale
    property string lastAccountId: ""
    function onPeersChanged() { root.ensureCursor() }
    function onAccountsChanged() { root.ensureCursor() }
    function onAccountsAccessDeniedChanged() { root.ensureCursor() }
    function onSelectedAccountIdChanged() {
      // A remembered scroll position belongs to the tailnet it was scrolled
      // in; restoring it midway into another account's machine list would
      // land the user somewhere they have never been.
      var next = tailscale.selectedAccountId
      // A failed account poll publishes an empty id for the tailnet the user
      // is still on, so compare against the last one actually seen.
      if (next === "" || next === serviceEvents.lastAccountId) return
      serviceEvents.lastAccountId = next
      root.peerIndex = 0
      if (!root.peerList) return
      root.peerList.rememberedY = 0
      root.callMethod(root.peerList, "positionViewAtBeginning")
    }
  }

  Commons.ShellIpc {
    target: root.ipcTarget
    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function refresh(): string { tailscale.refresh(false, true); return "ok" }
    function up(): string { tailscale.loginOrUp(); return "ok" }
    function down(): string { tailscale.down(); return "ok" }
    function toggleTailscale(): string { tailscale.toggleTailscale(); return "ok" }
    function status(): string { return tailscale.statusText }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    iconComponent: Component {
      Item {
        TailscaleIcon {
          x: (parent.width - width) / 2
          y: (parent.height - height) / 2
          iconSize: button.iconSize
          color: root.barIconColor
          badgeColor: root.urgent
          crossed: !tailscale.active && !tailscale.needsLogin
          warning: tailscale.needsLogin
        }
      }
    }
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) tailscale.toggleTailscale()
      else if (buttonCode === Qt.MiddleButton) tailscale.refresh(false, true)
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: panel.loadedContent
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(panel.loadedContentHeight, Style.space(560))

    panelContent: LazyContent {}

    component LazyContent: PanelKeyCatcher {
      id: keyCatcher
      final property alias panelFlick: panelFlick
      final property alias hero: hero
      final property alias exitNodeColumn: exitNodeColumn
      final property alias mullvadSearch: mullvadSearch
      final property alias mullvadRegionColumn: mullvadRegionColumn
      final property alias peerSearch: peerSearchField
      final property alias peerList: peerList
      final property alias sharedCopyPopup: sharedCopyPopup
      implicitHeight: column.implicitHeight
      anchors.fill: parent
      blocked: root.copyMenuOpen
      onMoveRequested: function(dx, dy) {
        if (!root.cursorActive) { root.cursorActive = true; return }
        root.moveCursor(dx, dy)
      }
      onActivateRequested: if (root.cursorActive) root.activateCursor()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) {
        if (t === "t" || t === "T") tailscale.toggleTailscale()
        else if (t === "c" || t === "C") tailscale.copyPeerIp(root.selectedPeer())
        else if (t === "n" || t === "N") tailscale.copyPeerName(root.selectedPeer())
        else if (t === "d" || t === "D") tailscale.copyPeerDnsName(root.selectedPeer())
        else if (t === "s" || t === "S") root.sendPeerFile(root.selectedPeer())
        else if (t === "/" && peerSearchField.visible) peerSearchField.forceActiveFocus()
      }

      Flickable {
        id: panelFlick
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
          id: column
          width: panelFlick.width
          spacing: Style.space(12)

          Item {
            id: header
            width: parent.width
            implicitHeight: hero.implicitHeight
            // Exposed for the hero's trailingControl, whose `root` resolves to
            // PanelHero (not this Panel) — reach panel state via `header`.
            readonly property bool ringVisible: root.headerHasCursor
            function focusHero(): void { root.setHeaderCursor() }

            PanelHero {
              id: hero
              width: parent.width
              title: tailscale.installed ? (tailscale.selfName || "Tailscale") : "Tailscale"
              meta: tailscale.active ? root.heroPhraseText : Commons.I18n.t("tailscale.disconnectedMeta")
              foreground: root.foreground
              fontFamily: root.fontFamily
              iconOpacity: tailscale.active ? 1.0 : 0.5
              // Status only — the switch owns toggling, mouse and keyboard alike.
              iconComponent: Component {
                TailscaleIcon {
                  iconSize: Style.font.display
                  color: root.iconColor
                  badgeColor: root.urgent
                  crossed: !tailscale.active && !tailscale.needsLogin
                  warning: tailscale.needsLogin
                }
              }

              // Compact on/off switch on the trailing edge of the hero, and the
              // header's only cursor target. The service already flips `active`
              // optimistically, so the knob throws the instant you click it.
              trailingControl: Component {
                ToggleSwitch {
                  id: powerSwitch
                  visible: tailscale.installed
                  checked: tailscale.active
                  busy: tailscale.busy
                  hasCursor: header.ringVisible
                  foreground: hero.foreground
                  onHovered: function(on) { if (on) header.focusHero() }
                  onToggled: tailscale.toggleTailscale()

                  PanelToolTip {
                    visible: powerSwitch.containsMouse
                    text: root.toggleHint
                    fontFamily: hero.fontFamily
                  }
                }
              }
            }
          }

          Text {
            textFormat: Text.PlainText
            visible: tailscale.actionStatus !== "" || tailscale.lastError !== ""
            width: parent.width
            text: tailscale.actionStatus !== "" ? tailscale.actionStatus : tailscale.lastError
            color: tailscale.lastError !== "" && tailscale.actionStatus === "" ? root.urgent : root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.WordWrap
          }

          CursorSurface {
            visible: !tailscale.installed
            width: parent.width
            implicitHeight: missingText.implicitHeight + Style.spacing.rowPaddingX
            foreground: root.foreground

            Text {
              id: missingText
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              anchors.margins: Style.space(12)
              text: Commons.I18n.t("tailscale.notInstalled")
              textFormat: Text.PlainText
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              wrapMode: Text.WordWrap
            }
          }

          PanelSeparator {
            visible: root.showConnections
            foreground: root.foreground
          }

          Column {
            visible: root.showConnections
            width: parent.width
            spacing: Style.space(10)

            PanelSectionHeader {
              text: Commons.I18n.t("tailscale.connections")
              foreground: root.foreground
              fontFamily: root.fontFamily
            }

            AuthRow {
              visible: tailscale.accountsAccessDenied
              width: parent.width
            }

            Repeater {
              model: tailscale.accounts
              AccountRow {
                required property var modelData
                required property int index
                width: parent.width
                account: modelData
                rowIndex: index
              }
            }
          }

          PanelSeparator {
            visible: root.showExitNodes
            foreground: root.foreground
          }

          Column {
            visible: root.showExitNodes
            width: parent.width
            spacing: Style.space(10)

            PanelSectionHeader {
              text: Commons.I18n.t("tailscale.exitNodes")
              foreground: root.foreground
              fontFamily: root.fontFamily
            }

            Column {
              id: exitNodeColumn
              width: parent.width
              spacing: Style.space(6)

              Repeater {
                model: root.exitNodes
                ExitNodeRow {
                  required property var modelData
                  required property int index
                  width: exitNodeColumn.width
                  peer: modelData
                  rowIndex: index
                }
              }

              Column {
                visible: root.mullvadPickerOpen
                width: parent.width
                spacing: Style.space(6)

                TextField {
                  id: mullvadSearch
                  width: parent.width
                  foreground: root.foreground
                  placeholderText: Commons.I18n.t("tailscale.searchRegions")
                  text: root.mullvadQuery
                  onTextChanged: {
                    root.mullvadQuery = text
                    root.mullvadRegionIndex = 0
                  }
                  onAccepted: {
                    root.activateMullvadRegionCursor()
                  }
                  Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Down || event.text === "j") {
                      root.moveMullvadRegionCursor(1)
                      event.accepted = true
                      return
                    }
                    if (event.key === Qt.Key_Up || event.text === "k") {
                      root.moveMullvadRegionCursor(-1)
                      event.accepted = true
                      return
                    }
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                      root.activateMullvadRegionCursor()
                      event.accepted = true
                      return
                    }
                    if (event.key === Qt.Key_Escape) {
                      root.mullvadPickerOpen = false
                      keyCatcher.forceActiveFocus()
                      event.accepted = true
                    }
                  }
                }

                Text {
                  visible: root.arrayLength(root.filteredMullvadRegions) === 0
                  width: parent.width
                  text: Commons.I18n.t("tailscale.noRegions")
                  textFormat: Text.PlainText
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  horizontalAlignment: Text.AlignHCenter
                }

                Column {
                  id: mullvadRegionColumn
                  width: parent.width
                  spacing: Style.space(6)

                  Repeater {
                    model: root.filteredMullvadRegions
                    MullvadRegionRow {
                      required property var modelData
                      required property int index
                      width: parent.width
                      peer: modelData
                      rowIndex: index
                    }
                  }
                }
              }
            }
          }

          PanelSeparator {
            visible: tailscale.installed && tailscale.active
            foreground: root.foreground
          }

          Column {
            visible: tailscale.installed && tailscale.active
            width: parent.width
            spacing: Style.space(10)

            PanelSectionHeader {
              text: {
                if (root.arrayLength(tailscale.peers) === 0) return Commons.I18n.t("tailscale.machines")
                var total = Commons.I18n.formatNumber(root.arrayLength(tailscale.peers))
                if (root.peerQuery.trim() === "") return Commons.I18n.t("tailscale.machinesCount").arg(total)
                return Commons.I18n.t("tailscale.machinesFiltered").arg(Commons.I18n.formatNumber(root.arrayLength(root.filteredPeers))).arg(total)
              }
              foreground: root.foreground
              fontFamily: root.fontFamily
            }

            TextField {
              id: peerSearchField
              visible: root.arrayLength(tailscale.peers) > 8
              width: parent.width
              foreground: root.foreground
              placeholderText: Commons.I18n.t("tailscale.searchMachines")
              // The field can disappear (account switch to a small tailnet)
              // while a query is typed; a filter with no visible box and no
              // `/` shortcut to clear it would look like missing machines.
              onVisibleChanged: if (!visible && text !== "") text = ""
              onTextChanged: {
                root.peerQuery = text
                root.peerIndex = 0
                peerList.rememberedY = 0
                Model.callMethod(peerList, "positionViewAtBeginning")
              }
              onAccepted: {
                root.setPeerCursor(0)
                keyCatcher.forceActiveFocus()
              }
              Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Down) {
                  root.setPeerCursor(0)
                  keyCatcher.forceActiveFocus()
                  event.accepted = true
                  return
                }
                if (event.key === Qt.Key_Up) {
                  // Unhandled Up propagates past the field and moves the
                  // panel's section cursor out from under the query.
                  keyCatcher.forceActiveFocus()
                  event.accepted = true
                  return
                }
                if (event.key === Qt.Key_Escape) {
                  if (peerSearchField.text !== "") peerSearchField.text = ""
                  else keyCatcher.forceActiveFocus()
                  event.accepted = true
                }
              }
            }

            Text {
              // Only claim an empty tailnet once a full peer fetch has
              // answered; before that the panel is simply still loading.
              visible: tailscale.installed && tailscale.active && tailscale.peersLoaded && root.arrayLength(tailscale.peers) === 0
              width: parent.width
              text: Commons.I18n.t("tailscale.noMachines")
              textFormat: Text.PlainText
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              horizontalAlignment: Text.AlignHCenter
            }

            Text {
              visible: tailscale.installed && tailscale.active && !tailscale.peersLoaded && root.arrayLength(tailscale.peers) === 0
              width: parent.width
              text: Commons.I18n.t("tailscale.loadingMachines")
              textFormat: Text.PlainText
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              horizontalAlignment: Text.AlignHCenter
            }

            Text {
              visible: root.arrayLength(tailscale.peers) > 0 && root.arrayLength(root.filteredPeers) === 0
              width: parent.width
              text: Commons.I18n.t("tailscale.noMatchingMachines")
              textFormat: Text.PlainText
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              horizontalAlignment: Text.AlignHCenter
            }

            // Virtualized: only the visible slice of the tailnet exists as
            // delegates, and rows are pooled instead of destroyed on refresh.
            RememberingListView {
              id: peerList
              visible: root.showPeers
              width: parent.width
              height: Math.min(contentHeight, Style.space(300))
              clip: true
              spacing: Style.space(6)
              model: root.filteredPeers
              reuseItems: true
              boundsBehavior: Flickable.StopAtBounds
              flickableDirection: Flickable.VerticalFlick
              interactive: contentHeight > height
              ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                onPressedChanged: if (!pressed) Model.callMethod(peerList, "rememberPosition")
              }

              delegate: PeerRow {
                required property var modelData
                required property int index
                width: peerList.width
                peer: modelData
                rowIndex: index
              }
            }

            Popup {
              id: sharedCopyPopup
              parent: peerList
              width: Style.space(280)
              padding: 0
              modal: false
              focus: true
              closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
              function handleKey(event: KeyEvent): void {
                if (event.key === Qt.Key_Escape) {
                  close()
                  event.accepted = true
                  return
                }
                if (event.key === Qt.Key_Down || event.text === "j") {
                  root.moveCopyCursor(1)
                  event.accepted = true
                  return
                }
                if (event.key === Qt.Key_Up || event.text === "k") {
                  root.moveCopyCursor(-1)
                  event.accepted = true
                  return
                }
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                  root.copyCurrentOption()
                  event.accepted = true
                }
              }
              onOpenedChanged: {
                root.copyMenuOpen = opened
                if (opened) {
                  root.clampCopyIndex()
                  Qt.callLater(function() { sharedCopyContent.forceActiveFocus() })
                } else if (root.opened) {
                  Qt.callLater(function() { keyCatcher.forceActiveFocus() })
                }
              }
              background: BorderSurface {
                color: Commons.Color.background
                borderSpec: Border.flat(root.dim, 1)
                radius: Style.cornerRadius
              }

              contentItem: Column {
                id: sharedCopyContent
                width: parent.width
                focus: true
                Keys.priority: Keys.BeforeItem
                Keys.onPressed: function(event) { sharedCopyPopup.handleKey(event) }

                Repeater {
                  model: root.copyOptions
                  CopyChoice {
                    required property var modelData
                    required property int index
                    width: parent.width
                    label: String(Model.field(modelData, "label") || "")
                    selected: root.copyIndex === index
                    onHovered: root.copyIndex = index
                    onChosen: root.copyOption(String(Model.field(modelData, "kind") || ""))
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  Timer {
    id: phraseTimer
    interval: 2800
    running: root.opened && tailscale.active
    repeat: true
    onTriggered: phraseSwap.restart()
  }

  SequentialAnimation {
    id: phraseSwap
    PropertyAnimation {
      target: root.hero; property: "metaOpacity"
      to: 0.0; duration: Style.duration(150); easing.type: Easing.OutCubic
    }
    ScriptAction {
      script: root.phraseIndex = (root.phraseIndex + 1) % root.arrayLength(root.activePhrases)
    }
    PropertyAnimation {
      target: root.hero; property: "metaOpacity"
      to: 1.0; duration: Style.duration(200); easing.type: Easing.OutCubic
    }
  }

  component AuthRow: CursorSurface {
    id: authRow

    hasCursor: root.cursorActive && root.focusSection === "auth"
    foreground: root.foreground

    implicitHeight: row.implicitHeight + Style.spacing.rowPaddingX

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: tailscale.busy ? Qt.ArrowCursor : Qt.PointingHandCursor
      enabled: !tailscale.busy
      onEntered: root.setAuthCursor()
      onClicked: tailscale.authorizeTailscaleOperator()
    }

    RowLayout {
      id: row
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(10)
      anchors.rightMargin: Style.space(10)
      spacing: Style.space(8)

      Text {
        text: "󰒃"
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.heading
        Layout.alignment: Qt.AlignVCenter
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.space(1)

        Text {
          Layout.fillWidth: true
          text: Commons.I18n.t("tailscale.authorizeOperator")
          textFormat: Text.PlainText
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          elide: Text.ElideRight
        }

        Text {
          Layout.fillWidth: true
          text: Commons.I18n.t("tailscale.authorizeHelp")
          textFormat: Text.PlainText
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
        }
      }

    }
  }

  component AccountRow: CursorSurface {
    id: accountRow
    property var account: null
    property int rowIndex: 0
    readonly property bool selectedAccount: account && Model.field(account, "selected") === true
    readonly property bool switchingAccount: account && tailscale.switchingAccountId === String(Model.field(account, "id") || "")
    readonly property string accountText: account ? tailscale.accountLabel(account) : Commons.I18n.t("tailscale.account")

    hasCursor: root.cursorActive && root.focusSection === "accounts" && root.accountIndex === rowIndex
    current: selectedAccount
    foreground: root.foreground
    fill: root.hoverFill
    currentFill: root.selectedFill

    implicitHeight: accountInner.implicitHeight + Style.spacing.xl

    Row {
      id: accountInner
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(6)
      anchors.rightMargin: Style.space(6)
      spacing: Style.space(8)

      Text {
        id: accountGlyph
        text: ""
        color: accountRow.selectedAccount || accountRow.switchingAccount ? root.foreground : root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        width: Style.space(22)
        horizontalAlignment: Text.AlignHCenter
        anchors.verticalCenter: parent.verticalCenter
        opacity: accountRow.switchingAccount ? 0.45 : 1.0

        SequentialAnimation on opacity {
          running: accountRow.switchingAccount && !Style.reduceMotion
          NumberAnimation { to: 1.0; duration: Style.duration(420); easing.type: Easing.InOutQuad }
          NumberAnimation { to: 0.45; duration: Style.duration(420); easing.type: Easing.InOutQuad }
          loops: Animation.Infinite
        }
      }

      Text {
        textFormat: Text.PlainText
        text: accountRow.accountText
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        font.bold: accountRow.selectedAccount
        elide: Text.ElideRight
        width: parent.width - Style.space(22) - Style.space(8)
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onEntered: root.setAccountCursor(accountRow.rowIndex)
      onClicked: if (accountRow.account) tailscale.switchAccount(Model.field(accountRow.account, "id"))
    }
  }

  component PeerRow: CursorSurface {
    id: peerRow
    property var peer: null
    property int rowIndex: 0
    readonly property string peerName: peer ? String(Model.field(peer, "DisplayName") || Model.field(peer, "HostName") || Commons.I18n.t("tailscale.unknown")) : Commons.I18n.t("tailscale.unknown")
    readonly property string peerIp: peer && Model.field(peer, "TailscaleIPs") && root.arrayLength(Model.field(peer, "TailscaleIPs")) > 0 ? String(Model.field(peer, "TailscaleIPs")[0]) : ""
    readonly property string peerIpv6: {
      if (!peer || !Model.field(peer, "TailscaleIPv6") || root.arrayLength(Model.field(peer, "TailscaleIPv6")) === 0) return ""
      return String(Model.field(peer, "TailscaleIPv6")[0] || "")
    }
    readonly property string peerDns: peer ? String(Model.field(peer, "DNSName") || "") : ""
    hasCursor: root.cursorActive && root.focusSection === "peers" && root.peerIndex === rowIndex
    foreground: root.foreground

    implicitHeight: Math.max(peerContent.implicitHeight, copyButton.implicitHeight) + Style.spacing.rowPaddingX

    function openCopyMenu() {
      root.openCopyMenuFor(peer, peerRow)
    }

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton
      hoverEnabled: true
      cursorShape: Qt.ArrowCursor
      onContainsMouseChanged: if (containsMouse) root.setPeerCursor(peerRow.rowIndex)
    }

    RowLayout {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(10)
      anchors.rightMargin: Style.space(8)
      spacing: Style.space(8)

      Text {
        textFormat: Text.PlainText
        text: tailscale.osIcon(peerRow.peer ? Model.field(peerRow.peer, "OS") : "")
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.icon
        Layout.alignment: Qt.AlignVCenter
      }

      ColumnLayout {
        id: peerContent
        Layout.fillWidth: true
        spacing: Style.space(1)

        Text {
          textFormat: Text.PlainText
          Layout.fillWidth: true
          text: peerRow.peerName
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          elide: Text.ElideRight
        }

        Text {
          textFormat: Text.PlainText
          Layout.fillWidth: true
          text: {
            var parts = []
            if (peerRow.peerIp !== "") parts.push(peerRow.peerIp)
            if (peerRow.peerDns !== "") parts.push(peerRow.peerDns)
            return parts.join(" · ")
          }
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
        }
      }

      PanelActionButton {
        id: sendButton
        visible: tailscale.canSendFiles(peerRow.peer)
        iconText: "󰒊"
        tooltipText: Commons.I18n.t("tailscale.sendFiles")
        foreground: root.foreground
        fontFamily: root.fontFamily
        Layout.alignment: Qt.AlignVCenter
        onClicked: root.sendPeerFile(peerRow.peer)
      }

      PanelActionButton {
        id: copyButton
        iconText: "󰆏"
        foreground: root.foreground
        fontFamily: root.fontFamily
        enabled: peerRow.peerIp !== "" || peerRow.peerName !== "" || peerRow.peerDns !== "" || peerRow.peerIpv6 !== ""
        Layout.alignment: Qt.AlignVCenter
        onClicked: peerRow.openCopyMenu()
      }
    }
  }

  component CopyChoice: CursorSurface {
    id: copyChoice
    signal chosen()
    signal hovered()
    property string label: ""
    property bool selected: false

    visible: enabled
    foreground: root.foreground
    hasCursor: selected
    implicitHeight: Style.space(48)
    radius: 0

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onEntered: copyChoice.hovered()
      onClicked: copyChoice.chosen()
    }

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: Style.space(12)
      anchors.rightMargin: Style.space(12)
      spacing: Style.space(10)

      Text {
        textFormat: Text.PlainText
        Layout.fillWidth: true
        text: copyChoice.label
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        elide: Text.ElideRight
      }

      Text {
        text: "󰆏"
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.icon
        Layout.alignment: Qt.AlignVCenter
      }
    }
  }

  component ExitNodeRow: CursorSurface {
    id: exitNodeRow
    property var peer: null
    property int rowIndex: 0
    readonly property bool addMullvad: peer && Model.field(peer, "AddMullvad") === true
    readonly property bool activeExitNode: peer && Model.field(peer, "ExitNode") === true
    readonly property bool settingExitNode: peer && tailscale.settingExitNodeId === String(Model.field(peer, "id") || "")
    readonly property string peerName: peer ? String(Model.field(peer, "DisplayName") || Model.field(peer, "HostName") || Commons.I18n.t("tailscale.unknown")) : Commons.I18n.t("tailscale.unknown")
    readonly property string actionTooltip: addMullvad ? "" : (activeExitNode ? Commons.I18n.t("tailscale.disconnect") : Commons.I18n.t("tailscale.connect"))

    hasCursor: root.cursorActive && root.focusSection === "exitNodes" && root.exitNodeIndex === rowIndex
    current: activeExitNode || settingExitNode || (addMullvad && root.mullvadPickerOpen)
    foreground: root.foreground
    fill: root.hoverFill
    currentFill: root.selectedFill

    implicitHeight: exitNodeInner.implicitHeight + Style.spacing.xl

    Row {
      id: exitNodeInner
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(6)
      anchors.rightMargin: Style.space(6)
      spacing: Style.space(8)

      Text {
        id: exitNodeGlyph
        textFormat: Text.PlainText
        text: exitNodeRow.addMullvad ? "+" : (exitNodeRow.peer && Model.field(exitNodeRow.peer, "Mullvad") === true ? "󰖂" : "󱇢")
        color: exitNodeRow.activeExitNode || exitNodeRow.settingExitNode || exitNodeRow.addMullvad ? root.foreground : root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        width: Style.space(22)
        horizontalAlignment: Text.AlignHCenter
        anchors.verticalCenter: parent.verticalCenter

        NumberAnimation on rotation {
          running: exitNodeRow.settingExitNode && !Style.reduceMotion
          from: 0
          to: 360
          duration: Style.duration(900)
          loops: Animation.Infinite
        }

        onRotationChanged: if (!exitNodeRow.settingExitNode && rotation !== 0) rotation = 0
      }

      Text {
        textFormat: Text.PlainText
        text: exitNodeRow.peerName
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        font.bold: exitNodeRow.activeExitNode
        elide: Text.ElideRight
        width: parent.width - Style.space(22) - Style.space(8)
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    MouseArea {
      id: exitNodeMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onEntered: root.setExitNodeCursor(exitNodeRow.rowIndex)
      onClicked: root.chooseExitNode(exitNodeRow.peer)
    }

    PanelToolTip {
      visible: exitNodeRow.actionTooltip !== "" && exitNodeMouse.containsMouse
      text: exitNodeRow.actionTooltip
      fontFamily: root.fontFamily
    }
  }

  component MullvadRegionRow: CursorSurface {
    id: regionRow

    property var peer: null
    property int rowIndex: 0
    readonly property string regionName: root.mullvadRegionTitle(peer)
    readonly property string regionDetail: root.mullvadRegionSubtitle(peer)
    readonly property bool activeExitNode: peer && Model.field(peer, "ExitNode") === true
    readonly property bool settingExitNode: peer && tailscale.settingExitNodeId === String(Model.field(peer, "id") || "")
    readonly property bool selectedRegion: root.mullvadPickerOpen && root.mullvadRegionIndex === rowIndex
    readonly property string actionTooltip: activeExitNode ? Commons.I18n.t("tailscale.disconnect") : Commons.I18n.t("tailscale.connect")

    foreground: root.foreground
    fill: root.hoverFill
    currentFill: root.selectedFill
    current: activeExitNode || settingExitNode || selectedRegion
    implicitHeight: row.implicitHeight + Style.spacing.lg

    Row {
      id: row
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(6)
      anchors.rightMargin: Style.space(6)
      spacing: Style.space(8)

      Text {
        text: "󰖂"
        color: regionRow.current ? root.foreground : root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        width: Style.space(22)
        horizontalAlignment: Text.AlignHCenter
        anchors.verticalCenter: parent.verticalCenter
      }

      Column {
        width: parent.width - Style.space(30)
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(1)

        Text {
          textFormat: Text.PlainText
          width: parent.width
          text: regionRow.regionName
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          font.bold: regionRow.activeExitNode
          elide: Text.ElideRight
        }

        Text {
          textFormat: Text.PlainText
          width: parent.width
          text: regionRow.regionDetail
          visible: text !== ""
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
        }
      }
    }

    MouseArea {
      id: regionMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onEntered: root.mullvadRegionIndex = regionRow.rowIndex
      onClicked: root.chooseExitNode(regionRow.peer)
    }

    PanelToolTip {
      visible: regionMouse.containsMouse
      text: regionRow.actionTooltip
      fontFamily: root.fontFamily
    }
  }
}
