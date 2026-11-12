.pragma library

function openPayload(osd, payloadJson) {
  try {
    var payload = JSON.parse(payloadJson || "{}")
    osd.show(payload.icon || "", payload.message || "", payload.value === undefined ? "" : String(payload.value), payload.max === undefined ? "100" : String(payload.max), payload.progressText || "", payload.duration === undefined ? "1200" : String(payload.duration))
  } catch (error) {}
}
