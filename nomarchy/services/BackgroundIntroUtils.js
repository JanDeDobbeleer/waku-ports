.pragma library

function field(object, key) { return object ? object[key] : undefined }
function pluginRegistry(host) { return field(host, "pluginRegistry") || null }
function backgroundService(host) {
  return host && field(host, "services") ? host.firstPartyServiceFor("nomarchy.background") : null
}
function desktopReady(host) {
  var registry = pluginRegistry(host)
  return !host || (!field(host, "pluginReloading") && (!registry || !field(registry, "scanning")) && (!("bar" in host) || !!field(host, "bar")))
}
function canFinishStartup(host, backgroundReady) {
  var registry = pluginRegistry(host)
  var backgroundId = registry ? registry.resolveEnabledId("nomarchy.background") : ""
  var disabled = registry && field(registry, "installedPlugins")[backgroundId] && !registry.isEnabled(backgroundId)
  return !!backgroundReady || !!disabled
}
function readyFrames(instances) {
  for (var i = 0; i < instances.length; i++) if (field(instances[i], "readyFrames") < 2) return false
  return true
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
