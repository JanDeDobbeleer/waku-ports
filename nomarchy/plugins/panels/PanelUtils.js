.pragma library

function dismiss(shell, manifest, fallbackId) {
  if (!shell || typeof shell.hide !== "function") return false
  shell.hide((manifest && manifest.id) || fallbackId)
  return true
}
function applyConnection(panel, payloadJson) {
  var payload = {}
  try { payload = JSON.parse(payloadJson || "{}") || {} } catch (error) {}
  if (payload.connection === undefined) return false
  panel.connectionName = String(payload.connection)
  return true
}

function reminderFontFamily(payloadJson) {
  try {
    var payload = JSON.parse(payloadJson || "{}")
    return payload && payload.fontFamily ? String(payload.fontFamily) : ""
  } catch (error) {
    return ""
  }
}
function openWifiQr(panel, payloadJson) {
  var payload = {}
  try { payload = JSON.parse(payloadJson || "{}") || {} } catch (error) {}
  panel.ssid = payload.ssid !== undefined ? String(payload.ssid) : ""
  panel.generate(String(payload.iface || ""))
}
