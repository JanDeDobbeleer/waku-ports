.pragma library

function field(object, key) { return object ? object[key] : undefined }
function backgroundService(host) {
  return host && field(host, "services") ? host.firstPartyServiceFor("nomarchy.background") : null
}
function nativeSize(service) {
  var sizes = field(service, "nativeSizes")
  return sizes ? sizes[field(service, "displayedBackground")] : null
}
function themeStatus(token, transitionToken, themeToken, revealing) {
  return token === transitionToken && (themeToken || revealing) ? "pending" : "ready"
}
function coverStatus(token, themeToken, themeBackground, instances) {
  if (token !== themeToken) return "superseded"
  if (!themeBackground) return "ready"
  for (var i = 0; i < instances.length; i++) {
    if (field(instances[i], "coverFailed")) return "error"
    if (!field(instances[i], "coverReady")) return "loading"
  }
  return instances.length > 0 ? "ready" : "loading"
}

function readyVideo(text) {
  try {
    var status = JSON.parse(text)
    return status.kind === "video" && status.ready && !status.has_transition && status.time_pos > 0
  } catch (error) { return false }
}
