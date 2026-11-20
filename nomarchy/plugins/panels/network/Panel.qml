pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import waku.services as S
import qs.Ui
import qs.Commons
import qs.Commons as Commons
import "Model.js" as Model
import qs.compat

Panel {
  id: root

  readonly property color contentForeground: bar ? BarValues.foreground(bar) : Commons.Color.foreground
  readonly property string contentFontFamily: bar ? BarValues.fontFamily(bar) : Style.font.family
  readonly property color contentUrgent: bar ? BarValues.urgent(bar) : Commons.Color.urgent
  moduleName: "nomarchy.network"
  ipcTarget: "nomarchy.network"
  // manageIpc: false so this panel can own the single IpcHandler the target
  // permits — needed for the toggleNetwork method below.
  manageIpc: false

  // Centralized close so callers can't forget to drop the passphrase prompt.
  function arrayLength(value: var): int {
    return Model.arrayLength(value)
  }

  function fieldValue(object: var, name: string): var {
    return Model.field(object, name)
  }

  function callMethod(object: var, name: string): void {
    Model.callMethod(object, name)
  }

  function close(): void {
    Model.callMethod(root.controller, "hide")
    cancelPasswordPrompt()
  }

  function cancelPasswordPrompt(): void {
    passwordSsid = ""
    passwordText = ""
  }

  // Live connection details from the engine's Network service and the netprobe tool.
  property var info: ({})  // { iface, type, ip, prefix, gateway, speed, duplex, ssid, signal, freq, bitrate, rx_bytes, tx_bytes, router_ping_ms, internet_ping_ms }

  // Throughput tracking. Rates are computed as deltas between successive
  // status samples (~1.5s apart via detailsPoll).
  // We hold "prev" alongside a timestamp so the first sample after open or
  // after an interface switch doesn't manufacture a spike.
  property real prevRxBytes: 0
  property real prevTxBytes: 0
  property real prevSampleTime: 0
  property string prevIface: ""
  property real downloadRate: 0  // bytes/sec
  property real uploadRate: 0    // bytes/sec
  property string pingIface: ""
  property var routerPingSamples: []
  property var internetPingSamples: []
  property real routerPingLatency: -1
  property real internetPingLatency: -1
  property int internetPingPacketLoss: 0
  readonly property int pingHistoryWindow: 24
  readonly property int pingAverageWindow: 5
  readonly property bool hasInternetPing: Model.internetPingReadable(internetPingSamples, connectivity)
  // Every stat row stays mounted whether or not there is data behind it, so a
  // sample arriving late never reflows the grid. This says whether the numbers
  // are real yet or the row should read "--".
  readonly property bool hasTransferStats: Model.field(info, "rx_bytes") !== undefined
  property int connectionPhraseIndex: 0
  readonly property list<string> connectionPhrases: [
    Commons.I18n.t("network.phrase1"),
    Commons.I18n.t("network.phrase2"),
    Commons.I18n.t("network.phrase3"),
    Commons.I18n.t("network.phrase4"),
    Commons.I18n.t("network.phrase5"),
    Commons.I18n.t("network.phrase6"),
    Commons.I18n.t("network.phrase7")
  ]
  readonly property string connectionPhrase: connectionPhrases[connectionPhraseIndex % connectionPhrases.length]
  readonly property bool networkManagerAvailable: Networking.backend === NetworkBackendType.NetworkManager
  readonly property var networkDevices: Model.values(Networking.devices)
  readonly property WifiDeviceItem wifiDevice: findDevice(DeviceType.Wifi) as WifiDeviceItem
  readonly property var wifiNetworkObjects: Model.values(wifiDevice ? Model.field(wifiDevice, "networks") : null)
  readonly property WifiNetworkItem connectedWifiNetwork: findConnectedWifiNetwork() as WifiNetworkItem
  property var wifiNetworks: []
  property bool scanning: false
  property bool wifiStationAvailable: false

  // Per-row in-flight state. `actionSsid` flips on for the row whose action
  // is currently running so it can render "Connecting…" / "Disconnecting…" /
  // "Forgetting…". `passwordSsid` is the row currently expanded into
  // password-entry mode; we keep it open across refresh cycles so a slow scan
  // doesn't collapse the input the user is typing into. Rows must gate
  // comparisons on the matching `*Kind`/`*Reason` being non-empty so a
  // hidden-SSID row (ssid == "") doesn't collide with the "" defaults.
  property string actionSsid: ""
  property string actionKind: ""  // "connect" | "disconnect" | "forget"
  property string failureSsid: ""
  property string failureReason: ""
  property string passwordSsid: ""
  property string passwordText: ""

  // ConnectionFailReason values as a plain object, so Model.js helpers stay
  // pure JS and Node-testable.
  readonly property var connectionFailReasons: ({
    NoSecrets: ConnectionFailReason.NoSecrets,
    WifiAuthTimeout: ConnectionFailReason.WifiAuthTimeout,
    WifiNetworkLost: ConnectionFailReason.WifiNetworkLost,
    WifiClientDisconnected: ConnectionFailReason.WifiClientDisconnected,
    WifiClientFailed: ConnectionFailReason.WifiClientFailed
  })

  // True while any wifi action is mid-flight. Rows
  // disable themselves on this so clicks on the other rows don't silently
  // no-op against runNetworkAction's serialized guard.
  readonly property bool busy: actionKind !== ""

  // Index into `wifiNetworks` for keyboard navigation. -1 = no selection.
  property int selectedIndex: -1
  property bool wifiActionFocused: false
  property bool cursorActive: false

  // Keyboard focus zone for the panel. j/k crosses section boundaries:
  // header switch, captive-portal button, then the Wi-Fi networks.
  property string focusSection: "wifi"  // "header" | "portal" | "wifi"
  property int headerIndex: 0
  readonly property bool canDisconnect: !!connectedWifiNetwork
  // The hero switch is the Wi-Fi radio, so it only exists when there is a
  // radio to switch. On a wired box it would otherwise sit there reading
  // "off" beside a perfectly live Ethernet connection.
  readonly property bool canToggleWifi: networkManagerAvailable && wifiStationAvailable
  readonly property int toggleHeaderIndex: canToggleWifi ? 0 : -1
  readonly property int headerActionCount: canToggleWifi ? 1 : 0
  readonly property bool toggleHeaderHasCursor: cursorActive && focusSection === "header" && headerIndex === toggleHeaderIndex
  readonly property string toggleHint: Networking.wifiEnabled ? Commons.I18n.t("network.turnWifiOff") : Commons.I18n.t("network.turnWifiOn")

  onHeaderActionCountChanged: clampHeaderIndex()

  function clampHeaderIndex(): void {
    var max = Math.max(0, headerActionCount - 1)
    if (headerIndex > max) headerIndex = max
    if (headerIndex < 0) headerIndex = 0
  }

  function selectHeaderByDelta(delta: int): void {
    headerIndex = Math.max(0, Math.min(headerActionCount - 1, headerIndex + delta))
  }

  function toggleNetwork(): void {
    if (!networkManagerAvailable) return
    Networking.wifiEnabled = !Networking.wifiEnabled
    Qt.callLater(function() { root.refresh(true) })
  }

  Commons.ShellIpc {
    target: "nomarchy.network"

    function open() { root.open() }
    function close() { root.close() }
    function show() { root.open() }
    function hide() { root.close() }
    function toggle() { root.toggle() }
    function toggleNetwork() { root.toggleNetwork() }
    function openCaptivePortal() { root.openCaptivePortal() }
    function checkConnectivity() { root.checkConnectivity() }
  }

  function activateHeader(): void {
    if (headerIndex === toggleHeaderIndex) toggleNetwork()
  }

  function setHeaderCursor(): void {
    cursorActive = true
    focusSection = "header"
    headerIndex = toggleHeaderIndex
  }

  // j/k across the sections that are on screen: header switch, captive-portal
  // button, then the Wi-Fi list (which scrolls row by row before it leaves).
  function moveFocus(dy: int): void {
    var order = []
    if (headerActionCount > 0) order.push("header")
    if (hasCaptivePortal) order.push("portal")
    if (Model.arrayLength(wifiNetworks) > 0) order.push("wifi")
    if (order.length === 0) return

    var at = order.indexOf(focusSection)
    if (at < 0) {
      focusSection = order[0]
    } else if (focusSection === "wifi" && (dy > 0 || selectedIndex > 0)) {
      selectByDelta(dy)
      return
    } else {
      focusSection = order[Math.max(0, Math.min(order.length - 1, at + (dy > 0 ? 1 : -1)))]
    }
    if (focusSection === "header") headerIndex = 0
    else if (focusSection === "wifi" && selectedIndex < 0) selectedIndex = 0
    wifiActionFocused = false
  }

  // Single cursor model: exactly one highlighted spot across the whole
  // panel, located via `focusSection` + (`headerIndex` | `selectedIndex`). Mouse hover and keyboard nav both mutate this state
  // at the root; items never read containsMouse for visuals. See
  // CursorSurface for the shared chrome shared by rows and pills.
  readonly property color hoverFill: bar ? Style.hoverFillFor(BarValues.foreground(bar), Commons.Color.accent, Commons.Color.urgent) : "transparent"
  readonly property color selectedFill: bar ? Style.selectedFillFor(BarValues.foreground(bar), Commons.Color.accent, Commons.Color.urgent) : "transparent"

  // scannerEnabled lives on the shared WifiDevice, which has no reference
  // counting, and a bar widget is instantiated once per monitor. Tracking the
  // device this instance turned scanning on for keeps the release correct when
  // the panel closes, the device is replaced, or the widget is destroyed —
  // without a closed instance ever claiming the scanner.
  property var scannerDevice: null

  function setScannerEnabled(enabled: bool): void {
    var nextDevice = opened ? wifiDevice : null

    if (scannerDevice && scannerDevice !== nextDevice)
      Model.setField(scannerDevice, "scannerEnabled", false)

    scannerDevice = nextDevice

    if (scannerDevice)
      Model.setField(scannerDevice, "scannerEnabled", enabled)
  }

  Component.onDestruction: {
    if (scannerDevice) Model.setField(scannerDevice, "scannerEnabled", false)
  }

  // KeyboardPanel primes layer-shell focus whenever the panel opens. That's
  // what makes the SUPER+CTRL+W keybind land here with navigation ready.
  onOpenedChanged: {
    if (opened) {
      refresh(true)
      selectedIndex = Model.arrayLength(wifiNetworks) > 0 ? 0 : -1
      wifiActionFocused = false
      focusSection = hasCaptivePortal ? "portal" : (Model.arrayLength(wifiNetworks) > 0 ? "wifi" : "header")
      headerIndex = 0
      cursorActive = hasCaptivePortal
    } else {
      // Drop a restart armed by this open: without it a close/reopen inside
      // the 100ms window reuses the running timer and re-enables the scanner
      // almost immediately, undoing the deferral #6605 restored.
      scanRestart.stop()
      // Reset throughput tracking so the next open doesn't compute a fake
      // rate from a sample taken minutes ago.
      prevSampleTime = 0
      downloadRate = 0
      uploadRate = 0
      pingIface = ""
      routerPingSamples = []
      internetPingSamples = []
      routerPingLatency = -1
      internetPingLatency = -1
      internetPingPacketLoss = 0
      setScannerEnabled(false)
    }
  }

  // When the passphrase prompt closes (Esc / Cancel / success) restore
  // focus to the keyCatcher so j/k/Enter resume working without a click.
  // The KeyboardPanel's focusTarget covers initial popup-open; this handles
  // the inline-editor case where focus was handed off to a child.
  onPasswordSsidChanged: {
    if (passwordSsid === "" && opened) {
      passwordText = ""
      Qt.callLater(function() { if (panel.loadedContent) root.callMethod(panel.loadedContent, "forceActiveFocus") })
    }
  }

  // Keep selectedIndex valid as scans refresh the network list.
  // If the list empties (station gone, e.g. wifi off), bounce the cursor
  // back to the header so the panel doesn't end up with no cursor at all.
  onWifiNetworksChanged: {
    if (Model.arrayLength(wifiNetworks) === 0) {
      selectedIndex = -1
      wifiActionFocused = false
      if (focusSection === "wifi") focusSection = hasCaptivePortal ? "portal" : "header"
    } else if (passwordSsid !== "") {
      let passwordIndex = wifiIndexForSsid(passwordSsid)
      if (passwordIndex >= 0) {
        selectedIndex = passwordIndex
        focusSection = "wifi"
      }
    } else if (selectedIndex >= Model.arrayLength(wifiNetworks)) {
      selectedIndex = Model.arrayLength(wifiNetworks) - 1
    } else if (selectedIndex < 0 && opened) {
      selectedIndex = 0
    }

    if (selectedIndex < 0 || selectedIndex >= Model.arrayLength(wifiNetworks) || !canForgetNetwork(wifiNetworks[selectedIndex])) {
      wifiActionFocused = false
    }
  }

  onWifiDeviceChanged: {
    setScannerEnabled(true)
    syncWifiNetworks()
  }

  onWifiNetworkObjectsChanged: syncWifiNetworks()

  function selectByDelta(delta: int): void {
    if (Model.arrayLength(wifiNetworks) === 0) { selectedIndex = -1; return }
    if (selectedIndex < 0) selectedIndex = delta > 0 ? 0 : Model.arrayLength(wifiNetworks) - 1
    else selectedIndex = Math.max(0, Math.min(Model.arrayLength(wifiNetworks) - 1, selectedIndex + delta))
    wifiActionFocused = false
  }

  function canForgetNetwork(net: var): bool {
    return Model.canForgetNetwork(net)
  }

  function selectWifiActionByDelta(delta: int): void {
    if (selectedIndex < 0 || selectedIndex >= Model.arrayLength(wifiNetworks)) return
    if (!canForgetNetwork(wifiNetworks[selectedIndex])) {
      wifiActionFocused = false
      return
    }
    if (delta > 0) wifiActionFocused = true
    else if (delta < 0) wifiActionFocused = false
  }

  // Enter/Space on the highlighted row. Mirrors row-click semantics:
  // connected → disconnect, credentials-required/unknown → prompt,
  // passwordless/known → connect.
  function activateSelected(): void {
    if (busy || selectedIndex < 0 || selectedIndex >= Model.arrayLength(wifiNetworks)) return
    var net = wifiNetworks[selectedIndex]
    if (!net) return
    if (wifiActionFocused && canForgetNetwork(net)) { forget(net); return }
    // Only act on a row that still resolves. disconnect() falls back to
    // connectedWifiNetwork when handed null, so a row left stale by scan churn
    // would otherwise tear down whatever is connected now instead.
    if (Model.field(net, "connected")) { disconnectRow(Model.field(net, "ssid")); return }
    if (requiresCredentials(Model.field(net, "security")) && !Model.field(net, "known")) { openPasswordPrompt(Model.field(net, "ssid")); return }
    connectDirectly(Model.field(net, "ssid"))
  }

  // Bar pill state, derived from the native NetworkManager service so the
  // icon reflects connection changes without polling. Wired is preferred
  // when both are up, matching the default-route device.
  readonly property WiredDeviceItem wiredDevice: findDevice(DeviceType.Wired) as WiredDeviceItem
  readonly property string kind: {
    if (wiredDevice && Model.field(wiredDevice, "connected")) return "ethernet"
    if (connectedWifiNetwork) return "wifi"
    // NetworkManager can leave the active profile out of the device's
    // AvailableConnections, and Quickshell only builds known networks from
    // that list. An OWE transition-mode network does this between scans: the
    // in-use access point carries the hidden "_owetm_" SSID, so the profile
    // for the open SSID looks out of range even while it is connected. Trust
    // the device's own state then instead of flickering to disconnected.
    if (wifiDevice && Model.field(wifiDevice, "connected")) return "wifi"
    return "disconnected"
  }
  readonly property int signalStrength: kind === "wifi"
    ? Model.connectedSignalStrength(connectedWifiNetwork ? Model.field(connectedWifiNetwork, "signalStrength") : 0, -1)
    : -1

  function copyToClipboard(value: string): void {
    if (!value) return
    Quickshell.clipboardText = value
  }

  // NetworkManager performs the HTTP probe (including unexpected page bodies,
  // not just redirects). Consume its native notifications rather than running
  // a second curl loop or mistaking an ordinary timeout for a captive portal.
  readonly property bool connectivityChecksEnabled: networkManagerAvailable
    && Networking.canCheckConnectivity && Networking.connectivityCheckEnabled
  readonly property string connectivity: Model.connectivityState(kind, Networking.connectivity, {
    Portal: NetworkConnectivity.Portal, Limited: NetworkConnectivity.Limited,
    Full: NetworkConnectivity.Full, None: NetworkConnectivity.None
  }, connectivityChecksEnabled)
  readonly property bool hasCaptivePortal: connectivity === "portal"
  readonly property bool restricted: hasCaptivePortal || connectivity === "limited"
  readonly property string icon: Model.connectionIcon(kind, signalStrength, connectivity)
  // Keyed on the device rather than the SSID: on an OWE transition-mode
  // network the listed network comes and goes with every scan while the link
  // stays up, and a real network switch already passes through "disconnected".
  readonly property string connectionKey: kind === "wifi" && wifiDevice
    ? kind + ":" + Model.field(wifiDevice, "name")
    : (kind === "ethernet" && wiredDevice ? kind + ":" + Model.field(wiredDevice, "name") : "")

  onConnectionKeyChanged: Qt.callLater(checkConnectivity)
  onConnectivityChecksEnabledChanged: Qt.callLater(checkConnectivity)
  onHasCaptivePortalChanged: {
    if (hasCaptivePortal && opened && passwordSsid === "") {
      focusSection = "portal"
      cursorActive = true
    } else if (!hasCaptivePortal && focusSection === "portal") {
      focusSection = headerActionCount > 0 ? "header" : "wifi"
      headerIndex = 0
    }
  }
  onRestrictedChanged: {
    connectionPhraseSwap.stop()
    if (panel.loadedContent) Model.setField(Model.field(panel.loadedContent as LazyContent, "heroMeta"), "opacity", 1.0)
  }

  function checkConnectivity(): void {
    if (connectivityChecksEnabled && kind !== "disconnected") Networking.checkConnectivity()
  }

  function openCaptivePortal(): void {
    if (!hasCaptivePortal) return
    // Explicit user action only, and a fixed HTTP URL: let the browser handle
    // the redirect without trusting portal input.
    Qt.openUrlExternally(Model.captivePortalUrl)
    close()
  }

  // Keep checking while login is needed, even with the panel closed in favour
  // of the browser. Normal connected operation relies on NM's own schedule.
  Timer {
    id: connectivityPoll
    interval: 10000
    repeat: true
    running: root.restricted && root.connectivityChecksEnabled
    onTriggered: root.checkConnectivity()
  }

  function refresh(scanWifi: bool): void {
    checkConnectivity()
    if (scanWifi === undefined) scanWifi = false
    root.updateDetails(root.windowsStatus())
    // A closed panel has no nearby-network list to fill, and bare refresh(false)
    // reaches here from action completion, timeouts and construction.
    if (opened && wifiDevice) {
      if (scanWifi) {
        scanning = true
        setScannerEnabled(false)
        scanRestart.start()
      } else {
        setScannerEnabled(true)
      }
    }
    syncWifiNetworks()
  }

  function formatHeaderSpeed(mbps: real): string {
    return Model.formatHeaderSpeed(mbps, Commons.I18n.numberFormatter())
  }

  function formatHeaderFreq(mhz: real): string {
    return Model.formatHeaderFreq(mhz, Commons.I18n.numberFormatter())
  }

  function headerDetail(): string {
    return Model.headerDetail(info, Commons.I18n.numberFormatter())
  }

  // The status text built from the engine's Network service: key=value lines.
  function windowsStatus(): string {
    var kind = String(S.Network.kind || "none")
    if (kind !== "wifi" && kind !== "ethernet") return ""
    var lines = []
    var iface = kind === "wifi" ? "Wi-Fi" : "Ethernet"
    var adapters = S.Network.adapters || []
    if (kind === "ethernet") {
      for (let i = 0; i < Model.arrayLength(adapters); i++) {
        if (Model.field(adapters[i], "isUp") && !/wi-?fi|wlan|wireless|loopback|virtual|vethernet|bluetooth/i.test(String(Model.field(adapters[i], "name")))) { iface = String(Model.field(adapters[i], "name")); break }
      }
    }
    lines.push("iface=" + iface, "type=" + kind, "ip=" + (S.Network.ipAddress || ""))
    lines.push("rx_bytes=" + Math.round(S.Network.rxBytesTotal || 0), "tx_bytes=" + Math.round(S.Network.txBytesTotal || 0))
    if (kind === "wifi") lines.push("ssid=" + (S.Network.ssid || ""), "signal=" + (S.Network.signalPercent || 0))
    for (let key in probe) lines.push(key + "=" + probe[key])
    return lines.join("\n")
  }

  function updateDetails(raw: string): void {
    var next = Model.parseKeyValue(raw)

    info = next
    updateThroughput(next)
    // The engine keeps its own per-second rates; use them rather than a second difference.
    downloadRate = S.Network.rxBytesPerSecond || 0
    uploadRate = S.Network.txBytesPerSecond || 0
    updatePingLatency(next)
  }

  function updateThroughput(next: var): void {
    var state = Model.throughputState({
      prevIface: prevIface,
      prevRxBytes: prevRxBytes,
      prevTxBytes: prevTxBytes,
      prevSampleTime: prevSampleTime,
      downloadRate: downloadRate,
      uploadRate: uploadRate
    }, next, Date.now() / 1000)

    prevIface = state.prevIface
    prevRxBytes = state.prevRxBytes
    prevTxBytes = state.prevTxBytes
    prevSampleTime = state.prevSampleTime
    downloadRate = state.downloadRate
    uploadRate = state.uploadRate
  }

  function updatePingLatency(next: var): void {
    var state = Model.pingLatencyState({
      pingIface: pingIface,
      routerPingSamples: routerPingSamples,
      internetPingSamples: internetPingSamples
    }, next, pingHistoryWindow, pingAverageWindow)

    pingIface = state.pingIface
    routerPingSamples = state.routerPingSamples
    internetPingSamples = state.internetPingSamples
    routerPingLatency = state.routerPingLatency
    internetPingLatency = state.internetPingLatency
    internetPingPacketLoss = state.internetPingPacketLoss
  }

  function formatBytes(bytes: real): string {
    return Model.formatBytes(bytes, Commons.I18n.numberFormatter())
  }

  function formatRate(bytesPerSec: real): string {
    return Model.formatRate(bytesPerSec, Commons.I18n.numberFormatter())
  }

  function formatPingLatency(ms: real): string {
    return Model.formatPingLatency(ms, hasInternetPing, Commons.I18n.translator(), Commons.I18n.numberFormatter())
  }

  function formatPacketLoss(percent: real): string {
    return Model.formatPacketLoss(percent, hasInternetPing, Commons.I18n.numberFormatter())
  }

  // Prefer a connected device: a machine can expose several NICs of the
  // same type (e.g. an idle onboard port alongside the active adapter),
  // and the first-enumerated one may be carrierless.
  function findDevice(type: var): var {
    var devices = networkDevices || []
    var fallback = null
    for (let i = 0; i < Model.arrayLength(devices); i++) {
      let device = devices[i]
      if (!device || device.type !== type) continue
      if (device.connected) return device
      if (!fallback) fallback = device
    }
    return fallback
  }

  function findConnectedWifiNetwork(): var {
    var networks = wifiNetworkObjects || []
    for (let i = 0; i < Model.arrayLength(networks); i++) {
      if (networks[i] && networks[i].connected) return networks[i]
    }
    return null
  }

  function syncWifiNetworks(): void {
    var nets = []
    var networks = wifiNetworkObjects || []

    for (let i = 0; i < Model.arrayLength(networks); i++) {
      let network = networks[i]
      if (!network) continue
      checkActionCompletion(network)
      let row = Model.wifiRow(network)
      if (row) nets.push(row)
    }
    wifiNetworks = Model.sortWifiRows(nets)
    wifiStationAvailable = !!wifiDevice
    scanning = false
  }

  function wifiSectionTitle(index: int): string {
    return Model.wifiSectionTitle(wifiNetworks, index, Commons.I18n.translator())
  }

  function wifiIconFor(strength: int): string {
    return Model.wifiIconFor(strength)
  }

  function requiresCredentials(security: var): bool {
    return Model.requiresCredentials(security, WifiSecurityType.Open, WifiSecurityType.Owe)
  }

  // WPA-Enterprise needs an identity and a certificate policy this panel cannot
  // collect, so Windows handles the sign-in. Everything else gets the inline prompt.
  function openPasswordPrompt(ssid: string): void {
    var security = Model.field(networkForSsid(ssid), "security")
    if (security === WifiSecurityType.Wpa2Eap || security === WifiSecurityType.WpaEap) {
      Quickshell.execDetached(["explorer.exe", "ms-settings:network-wifi"])
      close()
      return
    }
    if (passwordSsid !== ssid) passwordText = ""
    passwordSsid = ssid
  }

  function networkForSsid(ssid: string): var {
    var networks = wifiNetworkObjects || []
    for (let i = 0; i < Model.arrayLength(networks); i++) {
      if (networks[i] && networks[i].name === ssid) return networks[i]
    }
    return null
  }

  function wifiIndexForSsid(ssid: string): int {
    for (let i = 0; i < Model.arrayLength(wifiNetworks); i++) {
      if (wifiNetworks[i] && wifiNetworks[i].ssid === ssid) return i
    }
    return -1
  }

  function runNetworkAction(kind: string, network: var, callback: var): void {
    if (actionKind !== "" || !network) return
    var ssid = Model.field(network, "name") || ""
    actionSsid = ssid
    actionKind = kind
    failureSsid = ""
    failureReason = ""
    Model.invoke(callback, network)
    // Safety net: if onExited never fires (process death, signal handler
    // throws, etc.), clear the busy state so the row doesn't get stuck on
    // "Connecting…" / "Disconnecting…" forever.
    actionTimeout.restart()
  }

  function clearNetworkAction(): void {
    actionTimeout.stop()
    if (actionKind === "connect") passwordSsid = ""
    failureSsid = ""
    failureReason = ""
    actionSsid = ""
    actionKind = ""
    refresh(false)
  }

  function failNetworkAction(network: var, reason: var): void {
    if (!network || actionKind === "" || actionSsid !== (Model.field(network, "name") || "")) return
    actionTimeout.stop()
    failureSsid = actionSsid
    failureReason = networkFailureReason(reason, requiresCredentials(Model.field(network, "security")))
    actionSsid = ""
    actionKind = ""
    refresh(false)
  }

  function networkFailureReason(reason: var, needsCredentials: bool): string {
    return Model.networkFailureReason(reason, needsCredentials, connectionFailReasons, Commons.I18n.translator())
  }

  function shouldRepromptPassphrase(reason: var, needsCredentials: bool): bool {
    return Model.shouldRepromptPassphrase(reason, needsCredentials, connectionFailReasons)
  }

  function checkActionCompletion(network: var): void {
    if (!network || actionKind === "" || actionSsid !== (Model.field(network, "name") || "")) return
    if (actionKind === "connect" && Model.field(network, "connected")) clearNetworkAction()
    else if (actionKind === "disconnect" && !Model.field(network, "connected") && !Model.field(network, "stateChanging")) clearNetworkAction()
    else if (actionKind === "forget" && !Model.field(network, "known") && !Model.field(network, "stateChanging")) clearNetworkAction()
  }

  function connectDirectly(ssid: string): void {
    runNetworkAction("connect", networkForSsid(ssid), function(network: var): void { network.connect() })
  }

  function connectWithPassphrase(ssid: string, passphrase: string): void {
    runNetworkAction("connect", networkForSsid(ssid), function(network: var): void { network.connectWithPsk(passphrase) })
  }

  function disconnect(network: var): void {
    runNetworkAction("disconnect", network || connectedWifiNetwork, function(net: var): void { net.disconnect() })
  }

  // Disconnect from a row's SSID. Rows are primitive snapshots that can outlive
  // their WifiNetwork, and disconnect()'s null fallback targets whatever is
  // connected now, so a stale row must do nothing rather than hit an unrelated
  // network. Callers that mean "drop the current connection" call disconnect().
  function disconnectRow(ssid: string): void {
    var network = networkForSsid(ssid)
    if (network) disconnect(network)
  }

  function forget(net: var): void {
    runNetworkAction("forget", net ? networkForSsid(Model.field(net, "ssid")) : null, function(network: var): void { network.forget() })
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Component.onCompleted: refresh(false)

  // Windows port: the engine samples interface counters only while a binding watches them, and
  // windowsStatus() reads them from a function. These two keep the sampler running with the panel.
  readonly property real watchedRxTotal: S.Network.rxBytesTotal
  readonly property real watchedTxTotal: S.Network.txBytesTotal
  readonly property real watchedRxRate: S.Network.rxBytesPerSecond
  readonly property real watchedTxRate: S.Network.txBytesPerSecond

  // Windows port: the engine's Network service reports "none" for its first second, and the details
  // above were read once at construction. Re-read them whenever the service changes.
  Connections {
    target: S.Network
    function onKindChanged() { root.updateDetails(root.windowsStatus()) }
    function onSsidChanged() { root.updateDetails(root.windowsStatus()) }
    function onIpAddressChanged() { root.updateDetails(root.windowsStatus()) }
    function onWifiChanged() { root.updateDetails(root.windowsStatus()) }
  }

  // Pulls everything we want about the active route's interface in one shot.
  // Windows port: tools/netprobe.ps1 supplies gateway and the router and internet pings.
  property var probe: ({})
  // One long-lived process that prints a sample every 2 s while the panel is open; nothing is
  // spawned per sample, and closing the panel stops it.
  Process {
    id: detailsProc
    running: root.opened
    command: ["powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", String(Quickshell.shellDir) + "/tools/netprobe.ps1", "-IntervalMs", "2000"]
    stdout: SplitParser {
      onRead: function(line) {
        root.probe = Model.parseKeyValue(String(line).trim().split(/\s+/).join("\n"))
        root.updateDetails(root.windowsStatus())
      }
    }
  }

  Timer {
    id: scanRestart
    interval: 100
    repeat: false
    onTriggered: {
      if (root.opened && root.wifiDevice) {
        root.setScannerEnabled(true)
        scanDone.start()
      }
    }
  }

  Timer {
    id: scanDone
    interval: 1500
    repeat: false
    onTriggered: root.syncWifiNetworks()
  }

  // Poll details while the panel is open so the IP/route header catches up
  // as soon as NetworkManager finishes activating a connection.
  Timer {
    id: detailsPoll
    interval: 1500
    repeat: true
    running: root.opened
    onTriggered: root.updateDetails(root.windowsStatus())
  }

  Timer {
    id: connectionPhraseTimer
    interval: 2800
    running: root.opened && !root.restricted && (Model.field(root.info, "type") === "ethernet" || (Model.field(root.info, "type") === "wifi" && root.canDisconnect))
    repeat: true
    onTriggered: connectionPhraseSwap.restart()
  }

  SequentialAnimation {
    id: connectionPhraseSwap
    PropertyAnimation {
      target: panel.loadedContent ? Model.field(panel.loadedContent as LazyContent, "heroMeta") : null; property: "opacity"
      to: 0.0; duration: Style.duration(150); easing.type: Easing.OutCubic
    }
    ScriptAction {
      script: root.connectionPhraseIndex = (root.connectionPhraseIndex + 1) % root.connectionPhrases.length
    }
    PropertyAnimation {
      target: panel.loadedContent ? Model.field(panel.loadedContent as LazyContent, "heroMeta") : null; property: "opacity"
      to: 1.0; duration: Style.duration(200); easing.type: Easing.OutCubic
    }
  }

  Connections {
    target: root
    function onInfoChanged() {
      if (!(Model.field(root.info, "type") === "ethernet" || (Model.field(root.info, "type") === "wifi" && root.canDisconnect))) {
        connectionPhraseSwap.stop()
        if (panel.loadedContent) Model.setField(Model.field(panel.loadedContent as LazyContent, "heroMeta"), "opacity", 1.0)
      }
    }
  }

  Timer {
    id: actionTimeout
    // Must outlast NetworkManager's 25s supplicant timeout: a wrong saved
    // PSK fails with WifiAuthTimeout at ~25s, and that failure has to land
    // while the action is still tracked to show "Wrong password" and reopen
    // the passphrase prompt.
    interval: 30000
    repeat: false
    onTriggered: {
      if (!root.actionKind) return
      var reason
      if (root.actionKind === "connect") reason = Commons.I18n.t("network.timedOutConnecting")
      else if (root.actionKind === "disconnect") reason = Commons.I18n.t("network.timedOutDisconnecting")
      else reason = Commons.I18n.t("network.timedOutForgetting")
      root.failureSsid = root.actionSsid
      root.failureReason = reason
      root.actionSsid = ""
      root.actionKind = ""
      root.refresh(false)
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.icon
    active: root.restricted
    tooltipText: root.hasCaptivePortal ? Commons.I18n.t("network.signInToNetwork")
      : (root.restricted ? Commons.I18n.t("network.limitedAccess") : "")

    onPressed: function(b) {
      if (root.opened) root.close()
      // open() is enough: onOpenedChanged runs refresh(true), which defers the
      // PHY scan past the first frame. The bare refresh(false) that used to follow
      // took the no-scan branch and set scannerEnabled synchronously, undoing
      // that deferral and stalling the open on NetworkManager's AP flood.
      else root.open()
    }
  }

  // Keyboard-driven popup anchored to the bar widget icon. The shared
  // KeyboardPanel handles the layer-shell PanelWindow scaffolding
  // (focus priming on open, screen binding, anchored-to-icon positioning,
  // outside-click via an overlay MouseArea + Region mask that lets the bar
  // remain clickable, fade animation, popout coordination). What stays
  // here is the wifi-specific UI inside.
  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: panel.loadedContent
    contentWidth: panel.fittedContentWidth(Style.space(380), undefined)
    contentHeight: panel.fittedContentHeight(panel.loadedContentHeight, undefined)

    // Catches all unhandled keys for keyboard navigation. AfterItem priority
    // lets the passphrase TextField (a child via focus chain) get its keys
    // first; only events the focused subtree ignores bubble back here.
    panelContent: LazyContent {}

    component LazyContent: PanelKeyCatcher {
      id: keyCatcher
      final property alias heroMeta: heroMeta
      implicitHeight: column.implicitHeight
      anchors.fill: parent
      // Freeze the cursor model while the inline password prompt is open;
      // the TextField inside owns input until Esc/Enter/Cancel.
      blocked: root.passwordSsid !== ""

      onMoveRequested: function(dx, dy) {
        if (!root.cursorActive) {
          root.cursorActive = true
          if (dy >= 0) return
        }
        if (dy !== 0) root.moveFocus(dy)
        if (dx !== 0) {
          if (root.focusSection === "header") root.selectHeaderByDelta(dx)
          else if (root.focusSection === "wifi") root.selectWifiActionByDelta(dx)
        }
      }
      onActivateRequested: {
        if (root.cursorActive) {
          if (root.focusSection === "header") root.activateHeader()
          else if (root.focusSection === "portal") root.openCaptivePortal()
          else root.activateSelected()
        }
      }
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) {
        if (t === "r" || t === "R") root.refresh(false)
        else if (t === "w" || t === "W") root.toggleNetwork()
      }

    Column {
      id: column
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      spacing: Style.space(12)

      // ---------- Hero: network icon · SSID + state · actions ----------
      Item {
        width: parent.width
        implicitHeight: Math.max(heroIcon.implicitHeight, heroLabels.implicitHeight, heroActions.implicitHeight)

        // Status only — the switch owns toggling, mouse and keyboard alike.
        Text {
          id: heroIcon
          textFormat: Text.PlainText
          text: root.icon
          color: root.restricted ? root.contentUrgent : root.contentForeground
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.display
          opacity: root.networkManagerAvailable ? 1.0 : 0.5
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
        }

        // The Wi-Fi radio switch is the only hero action.
        RowLayout {
          id: heroActions
          spacing: Style.space(8)
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter

          ToggleSwitch {
            id: powerSwitch
            visible: root.canToggleWifi
            checked: Networking.wifiEnabled
            hasCursor: root.toggleHeaderHasCursor
            foreground: root.contentForeground
            Layout.alignment: Qt.AlignVCenter
            onHovered: function(on) { if (on) root.setHeaderCursor() }
            onToggled: root.toggleNetwork()

            PanelToolTip {
              visible: powerSwitch.containsMouse
              text: root.toggleHint
              fontFamily: root.contentFontFamily
            }
          }
        }

        Column {
          id: heroLabels
          anchors.left: heroIcon.right
          anchors.leftMargin: Style.space(14)
          anchors.right: parent.right
          anchors.rightMargin: heroActions.width > 0 ? heroActions.width + Style.space(12) : 0
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(2)

          // Link detail rides inline after the name — "Ethernet (2.5gbit)" —
          // rather than in a pill, which crowded the on/off switch.
          Text {
            id: heroSsid
            textFormat: Text.PlainText
            width: parent.width

            readonly property string title: {
              // The HTTP restriction does not undo association. Show the live
              // SSID even before route/details polling has returned anything.
              if (root.kind === "wifi" && root.connectedWifiNetwork) return root.fieldValue(root.connectedWifiNetwork, "name") || "Wi-Fi"
              if (Model.field(root.info, "type") === "wifi") return Model.field(root.info, "ssid") || "Wi-Fi"
              if (Model.field(root.info, "type") === "ethernet") return Commons.I18n.t("network.ethernet")
              return Model.field(root.info, "iface") || (root.kind === "disconnected" ? Commons.I18n.t("network.disconnected") : Commons.I18n.t("network.noConnection"))
            }
            readonly property string detail: root.headerDetail()

            text: heroSsid.detail !== "" ? heroSsid.title + " (" + heroSsid.detail + ")" : heroSsid.title
            color: root.contentForeground
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.title
            font.bold: true
            elide: Text.ElideRight
          }

          Text {
            id: heroMeta
            textFormat: Text.PlainText
            width: parent.width
            text: {
              // The sign-in button right below already says what a portal needs.
              if (root.hasCaptivePortal) return ""
              if (root.restricted) return Commons.I18n.t("network.limitedAccessHeader")
              if (Model.field(root.info, "type") === "wifi") {
                if (root.canDisconnect) return root.connectionPhrase.toUpperCase()
                if (root.kind === "disconnected") return Commons.I18n.t("network.notConnected")
                return ""
              }
              if (Model.field(root.info, "type") === "ethernet") return root.connectionPhrase.toUpperCase()
              if (root.kind === "disconnected") return Commons.I18n.t("network.notConnected")
              return ""
            }
            visible: text !== ""
            color: root.restricted ? root.contentUrgent : Qt.darker(root.contentForeground, 1.4)
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 1.2
            elide: Text.ElideRight
          }
        }

      }

      Button {
        id: portalAction
        visible: root.hasCaptivePortal
        width: parent.width
        text: Commons.I18n.t("network.openCaptivePortal")
        iconText: "󰏌"
        foreground: root.contentUrgent
        accent: root.contentUrgent
        fontFamily: root.contentFontFamily
        verticalPadding: Style.space(10)
        bordered: true
        active: true
        hasCursor: root.cursorActive && root.focusSection === "portal"
        onHovered: function(on) {
          if (!on) return
          root.cursorActive = true
          root.focusSection = "portal"
        }
        onClicked: root.openCaptivePortal()
      }

      // Connection details: transfer metrics first, then IP/Gateway.
      Column {
        visible: !!Model.field(root.info, "iface")
        width: parent.width
        spacing: Style.spacing.labelGap

        GridLayout {
          width: parent.width
          columns: 4
          columnSpacing: Style.space(20)
          rowSpacing: Style.spacing.labelGap

          // Always mounted: these two used to appear a beat after the panel
          // opened, once the first probe returned, shoving everything below
          // them down. They now hold their place and read "--" until there is
          // a sample, and while the internet is out of reach.
          InfoLabel { text: Commons.I18n.t("network.ping") }
          DetailValue {
            text: root.formatPingLatency(root.internetPingLatency)
            color: root.hasInternetPing && root.internetPingPacketLoss > 0 ? root.contentUrgent : root.contentForeground
          }
          InfoLabel { text: Commons.I18n.t("network.packetLoss") }
          DetailValue {
            text: root.formatPacketLoss(root.internetPingPacketLoss)
            color: root.hasInternetPing && root.internetPingPacketLoss > 0 ? root.contentUrgent : root.contentForeground
          }

          InfoLabel { text: Commons.I18n.t("network.receiving") }
          DetailValue { text: root.hasTransferStats ? root.formatRate(root.downloadRate) : "--" }
          InfoLabel { text: Commons.I18n.t("network.sending") }
          DetailValue { text: root.hasTransferStats ? root.formatRate(root.uploadRate) : "--" }

          InfoLabel { text: Commons.I18n.t("network.downloaded") }
          DetailValue { text: root.hasTransferStats ? root.formatBytes(parseFloat(Model.field(root.info, "rx_bytes") || "0")) : "--" }
          InfoLabel { text: Commons.I18n.t("network.uploaded") }
          DetailValue { text: root.hasTransferStats ? root.formatBytes(parseFloat(Model.field(root.info, "tx_bytes") || "0")) : "--" }

          InfoLabel { text: Commons.I18n.t("network.ipAddress") }
          DetailValue {
            text: Model.field(root.info, "ip") || "--"
            copyable: !!Model.field(root.info, "ip")
            tooltipText: Commons.I18n.t("network.copyIp")
          }
          InfoLabel { text: Commons.I18n.t("network.gateway") }
          DetailValue {
            text: Model.field(root.info, "gateway") || "--"
            copyable: !!Model.field(root.info, "gateway")
            tooltipText: Commons.I18n.t("network.copyGateway")
          }
        }
      }

      // Wi-Fi networks (only if a Wi-Fi station is available).
      PanelSeparator {
        visible: root.wifiStationAvailable
        foreground: root.contentForeground
      }

      PanelSectionHeader {
        visible: root.wifiStationAvailable && root.scanning
        text: Commons.I18n.t("network.scanningWifi")
        foreground: root.contentForeground
        fontFamily: root.contentFontFamily
      }

      // Scrollable network list — cap the height so a busy neighbourhood
      // doesn't push the popup off-screen. ListView (vs Repeater+Column)
      // gives us positionViewAtIndex for free, which is what keeps the
      // keyboard-selected row scrolled into view as j/k walk past the
      // visible window.
      ListView {
        id: networkList
        visible: root.wifiStationAvailable
        width: parent.width
        height: Math.min(contentHeight, Style.space(240))
        spacing: Style.space(4)
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        model: root.wifiStationAvailable ? root.wifiNetworks : []
        currentIndex: root.selectedIndex
        onCurrentIndexChanged: if (currentIndex >= 0) positionViewAtIndex(currentIndex, ListView.Contain)

        // Wrapper takes the required props from ListView's delegate context
        // (which doesn't bind into nested `component` declarations like
        // NetworkRow) and passes them down explicitly.
        delegate: Item {
          id: wifiDelegate
          required property var modelData
          required property int index
          readonly property string sectionTitle: root.wifiSectionTitle(index)
          width: ListView.view.width
          height: delegateColumn.implicitHeight

          Column {
            id: delegateColumn
            width: parent.width
            spacing: Style.space(4)

            PanelSectionHeader {
              visible: wifiDelegate.sectionTitle !== ""
              text: wifiDelegate.sectionTitle
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              height: visible ? implicitHeight : 0
            }

            NetworkRow {
              width: parent.width
              net: wifiDelegate.modelData
              index: wifiDelegate.index
            }
          }
        }
      }
    }
    }
  }

  // A single Wi-Fi network entry. Collapses to a one-line pill normally;
  // expands inline to a passphrase prompt when the user picks a network that
  // requires credentials we do not have. Clicking a connected row
  // disconnects.
  component NetworkRow: CursorSurface {
    id: row
    required property var net
    required property int index
    final readonly property string ssid: net ? Model.field(net, "ssid") : ""

    readonly property bool isConnected: net && Model.field(net, "connected")
    readonly property bool isKnown: !!(net && Model.field(net, "known"))
    readonly property bool requiresCredentials: net ? root.requiresCredentials(Model.field(net, "security")) : false
    readonly property bool canForget: root.canForgetNetwork(net)
    readonly property bool isSelected: root.focusSection === "wifi" && root.selectedIndex === index
    readonly property bool forgetFocused: isSelected && root.wifiActionFocused && canForget
    readonly property bool forgetVisible: canForget && (!requiresCredentials || forgetFocused || rightMouse.containsMouse)

    hasCursor: root.cursorActive && isSelected && !root.wifiActionFocused
    current: isConnected
    foreground: root.contentForeground
    fill: root.hoverFill
    currentFill: root.selectedFill
    // Gate on the matching *Kind/*Reason being non-empty so a hidden-SSID
    // row (ssid == "") doesn't match the "" defaults of actionSsid etc.
    readonly property bool isBusy: root.actionKind !== "" && root.actionSsid === (net ? row.ssid : "")
    readonly property bool isFailed: root.failureReason !== "" && root.failureSsid === (net ? row.ssid : "")
    readonly property bool isPasswordOpen: root.passwordSsid !== "" && root.passwordSsid === (net ? row.ssid : "")

    function submitCredentials(): void {
      if (!net || root.busy || root.passwordText.length === 0) return
      root.connectWithPassphrase(row.ssid, root.passwordText)
    }

    Connections {
      target: row.net ? root.networkForSsid(row.ssid) : null
      function onConnectionFailed(reason: var): void {
        // Background auto-connect retries fire this too; only reprompt for
        // the connect started from this panel. Checked before
        // failNetworkAction, which clears the action state.
        var ours = root.actionKind === "connect" && root.actionSsid === (row.ssid || "")
        root.failNetworkAction(root.networkForSsid(row.ssid), reason)
        if (ours && root.shouldRepromptPassphrase(reason, row.requiresCredentials)) root.openPasswordPrompt(row.ssid)
      }
      function onConnectedChanged() {
        if (row.net) root.checkActionCompletion(root.networkForSsid(row.ssid))
      }
      function onKnownChanged() {
        if (row.net) root.checkActionCompletion(root.networkForSsid(row.ssid))
      }
      function onStateChangingChanged() {
        if (row.net) root.checkActionCompletion(root.networkForSsid(row.ssid))
      }
    }

    readonly property string statusText: {
      if (!net) return ""
      if (isPasswordOpen) return ""
      if (isBusy && root.actionKind === "connect") return Commons.I18n.t("network.connecting")
      if (isBusy && root.actionKind === "disconnect") return Commons.I18n.t("network.disconnecting")
      if (isBusy && root.actionKind === "forget") return Commons.I18n.t("network.forgetting")
      if (isFailed) return root.failureReason || Commons.I18n.t("network.failed")
      if (isConnected && root.kind === "wifi" && root.hasCaptivePortal) return Commons.I18n.t("network.signInRequired")
      if (isConnected) return Commons.I18n.t("network.connected")
      return ""
    }

    readonly property color statusColor: {
      if (isFailed) return root.contentUrgent
      if (isBusy) return root.contentForeground
      if (isConnected && root.kind === "wifi" && root.hasCaptivePortal) return root.contentUrgent
      if (isConnected) return root.contentForeground
      return Qt.darker(root.contentForeground, 1.5)
    }

    implicitHeight: rowBody.implicitHeight + (isPasswordOpen ? passwordPanel.implicitHeight + Style.spacing.md : 0)

    MouseArea {
      id: rowMouse
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      height: rowBody.implicitHeight
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton
      cursorShape: Qt.PointingHandCursor
      enabled: !root.busy

      // Move the cursor here when the mouse enters; mouse leaving doesn't
      // clear it (so the cursor stays where the mouse last was and
      // subsequent j/k pick up from this row).
      onContainsMouseChanged: if (containsMouse) { root.cursorActive = true; root.focusSection = "wifi"; root.selectedIndex = row.index; root.wifiActionFocused = false }

      onClicked: {
        if (!row.net) return
        // Resync cursor in case keyboard nav moved it away while the mouse
        // stayed parked on this row — the click target is unambiguously here.
        root.cursorActive = true
        root.focusSection = "wifi"
        root.selectedIndex = row.index
        root.wifiActionFocused = false
        if (row.isConnected) {
          root.disconnectRow(row.ssid)
          return
        }
        if (row.requiresCredentials && !row.isKnown) {
          root.openPasswordPrompt(row.ssid)
          return
        }
        root.connectDirectly(row.ssid)
      }
    }

    Item {
      id: rowBody
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.leftMargin: Style.space(10)
      anchors.rightMargin: Style.space(10)
      implicitHeight: Math.max(networkIcon.implicitHeight, networkInfo.implicitHeight, rightAction.implicitHeight) + Style.spacing.rowPaddingX

      Text {
        id: networkIcon
        textFormat: Text.PlainText
        text: row.net ? Model.connectionIcon("wifi", root.fieldValue(row.net, "signal"),
          row.isConnected && root.kind === "wifi" ? root.connectivity : "") : ""
        color: row.statusColor
        font.family: root.contentFontFamily
        font.pixelSize: Style.font.title
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
      }

      // The right edge shows a lock for networks that require credentials and
      // reveals Forget on hover. Known passwordless networks show Forget
      // directly rather than reserving an invisible or misleading target.
      Item {
        id: rightAction
        visible: row.requiresCredentials || row.canForget
        width: Style.space(22)
        implicitHeight: lockIndicator.implicitHeight
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        Text {
          id: lockIndicator
          textFormat: Text.PlainText
          visible: row.requiresCredentials || row.forgetVisible
          width: parent.width
          anchors.verticalCenter: parent.verticalCenter
          horizontalAlignment: Text.AlignHCenter
          text: row.forgetVisible ? "󰅙" : "󰌾"
          color: row.forgetVisible ? root.contentUrgent : Qt.darker(root.contentForeground, 1.4)
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.subtitle
        }

        BorderSurface {
          anchors.fill: parent
          visible: row.forgetFocused
          color: Style.hoverFillFor(root.contentUrgent, root.contentUrgent, Commons.Color.urgent)
          borderSpec: Border.controlSpec("hover-cursor", root.contentUrgent, root.contentUrgent)
          radius: Style.cornerRadius
          z: -1
        }

        MouseArea {
          id: rightMouse
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.LeftButton
          enabled: row.canForget && !root.busy
          cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
          onContainsMouseChanged: if (containsMouse) { root.cursorActive = true; root.focusSection = "wifi"; root.selectedIndex = row.index; root.wifiActionFocused = true }
          onClicked: if (row.net) root.forget(row.net)
        }

        PanelToolTip {
          visible: rightMouse.containsMouse || row.forgetFocused
          text: Commons.I18n.t("network.forgetNetwork")
          fontFamily: root.contentFontFamily
        }
      }

      Column {
        id: networkInfo
        spacing: Style.space(1)
        anchors.left: networkIcon.right
        anchors.leftMargin: Style.space(10)
        anchors.right: rightAction.visible ? rightAction.left : parent.right
        anchors.rightMargin: rightAction.visible ? Style.space(8) : 0
        anchors.verticalCenter: parent.verticalCenter

        Text {
          textFormat: Text.PlainText
          text: row.net ? (row.ssid || Commons.I18n.t("network.hidden")) : ""
          color: root.contentForeground
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.body
          elide: Text.ElideRight
          width: parent.width
        }
        Text {
          textFormat: Text.PlainText
          // Signal strength is conveyed by the wifi-bars icon and the
          // right-edge glyph/buttons carry protection or forget affordances,
          // so the second line only carries action status (Connecting…,
          // Connected, Failed, etc.). Collapses to zero height when empty
          // so rows without status keep a tight one-line look.
          text: row.statusText
          visible: row.statusText !== ""
          height: visible ? implicitHeight : 0
          color: row.statusColor
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
          width: parent.width
        }
      }
    }

    Timer {
      id: failureTimer
      interval: 2000
      running: row.isFailed && row.isPasswordOpen
      onTriggered: {
        root.failureSsid = ""
        root.failureReason = ""
        pwField.forceActiveFocus()
      }
    }

    // Inline passphrase prompt — shown when we hit a protected network we
    // don't have saved credentials for, or when a connect fails because the
    // saved passphrase is wrong. Submitting (Enter or the check button) fires
    // connect; Esc cancels back to the row.
    Item {
      id: passwordPanel
      visible: row.isPasswordOpen
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: rowMouse.bottom
      anchors.leftMargin: Style.space(10)
      anchors.rightMargin: Style.space(10)
      anchors.topMargin: Style.space(4)
      implicitHeight: pwField.implicitHeight + Style.spacing.rowGap
      height: implicitHeight

      TextField {
        id: pwField
        visible: !row.isBusy && !row.isFailed
        anchors.left: parent.left
        anchors.right: connectPwBtn.left
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Style.spacing.rowGap / 2
        anchors.rightMargin: Style.space(6)
        password: true
        placeholderText: Commons.I18n.t("network.passphrase")
        font.family: Style.font.family
        font.pixelSize: Style.font.body
        foreground: root.contentForeground
        horizontalPadding: Style.spacing.controlGap
        verticalPadding: Style.spacing.controlPaddingY
        enabled: !row.isBusy
        text: row.isPasswordOpen ? root.passwordText : ""

        onAccepted: row.submitCredentials()
        onTextChanged: if (row.isPasswordOpen && text !== root.passwordText) root.passwordText = text
        Keys.onEscapePressed: root.cancelPasswordPrompt()

        onVisibleChanged: if (visible) Qt.callLater(forceActiveFocus)
        Component.onCompleted: if (visible) Qt.callLater(forceActiveFocus)
      }

      BorderSurface {
        id: statusMsgWrapper
        visible: row.isBusy || row.isFailed
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: Style.spacing.controlHeight
        color: Style.normalFillFor(root.contentForeground, Commons.Color.accent, Commons.Color.urgent)
        borderSpec: Border.controlSpec("normal", root.contentForeground, Commons.Color.accent)
        radius: Style.cornerRadius

        Text {
          textFormat: Text.PlainText
          anchors.fill: parent
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          text: row.isFailed ? Commons.I18n.t("network.wrongPassword") : Commons.I18n.t("network.connecting")
          color: row.isFailed ? root.contentUrgent : root.contentForeground
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.bodySmall
        }
      }

      // 22×22 right-anchored to line up with lockIndicator above. Esc closes
      // the prompt (handled by pwField.Keys.onEscapePressed)
      // so there's no separate cancel button.
      PanelActionButton {
        id: connectPwBtn
        visible: !row.isBusy && !row.isFailed
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        enabled: row.net && pwField.text.length > 0
        iconText: "󰄬"
        tooltipText: Commons.I18n.t("network.connect")
        foreground: root.contentForeground
        fontFamily: root.contentFontFamily
        onClicked: row.submitCredentials()
      }
    }
  }


  component DetailValue: InfoValue {
    id: detailValue
    property bool copyable: false
    property string tooltipText: Commons.I18n.t("network.copyToClipboard")

    Layout.fillWidth: true
    horizontalAlignment: Text.AlignRight

    MouseArea {
      id: valueMouse
      anchors.fill: parent
      enabled: detailValue.copyable && detailValue.text !== ""
      hoverEnabled: enabled
      cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
      onClicked: root.copyToClipboard(detailValue.text)
    }

    PanelToolTip {
      visible: valueMouse.enabled && valueMouse.containsMouse
      text: detailValue.tooltipText
      fontFamily: root.contentFontFamily
    }
  }

  component InfoLabel: Text {
    textFormat: Text.PlainText
    color: root.contentForeground
    opacity: 0.6
    font.family: root.contentFontFamily
    font.pixelSize: Style.font.bodySmall
  }

  component InfoValue: Text {
    textFormat: Text.PlainText
    color: root.contentForeground
    font.family: root.contentFontFamily
    font.pixelSize: Style.font.bodySmall
  }
}
