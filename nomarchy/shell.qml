//@ pragma NomarchyLoadPatch
import QtQuick
import QtQml.Models
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import waku.services as S

import qs.Commons
import qs.Commons as Commons

import "plugins/bar"
import "services"
import "services/AuthServiceStore.js" as AuthServiceStore

ShellRoot {
  id: shell

  // Windows port: the Nomarchy logo and its icons live in this font.
  FontLoader {
    source: "file:///" + String(Quickshell.shellDir).replace(/\\/g, "/") + "/assets/fonts/nomarchy.ttf"
  }

  // Shared service instances. Plugins receive these via property injection
  // rather than re-importing them as singletons — relative-path imports do
  // not share singleton state, which silently leaves consumers with their
  // own empty copies.
  property PluginRegistry pluginRegistry: PluginRegistry { }
  property BarWidgetRegistry barWidgetRegistry: BarWidgetRegistry { }
  property AppLibrary appLibrary: AppLibrary { }
  property BrightnessKeys brightnessKeys: BrightnessKeys { host: shell }
  property WallpaperTheme wallpaperTheme: WallpaperTheme {}
  property BackgroundIntro bootIntro: BackgroundIntro { host: shell }
  property BackgroundSwitch backgroundSwitch: BackgroundSwitch { intro: shell.bootIntro }

  property string home: Paths.home

  // The nomarchy-shell host is the long-running entry point. Plugins live in
  // sibling directories under plugins/. The port folder is Quickshell.shellDir.
  property string nomarchyPath: Quickshell.shellDir
  readonly property string shellPath: nomarchyPath
  readonly property string firstPartyPluginsDir: shellPath + "/plugins"
  readonly property string defaultsPath: nomarchyPath + "/config/nomarchy/shell.json"
  readonly property string userConfigPath: home + "/.config/nomarchy/shell.json"

  // Bundled fallback so the shell can start even when the default shell.json is
  // missing or unreadable. The bar config here mirrors the on-disk defaults
  // closely enough to render a usable bar; not authoritative.
  readonly property var builtinShellConfig: ({
    version: 1,
    idle: {
      screensaver: 150,
      lock: 300
    },
    bar: {
      position: "top",
      background: "opaque",
      layout: {
        left: [{ id: "nomarchy.menu" }, { id: "nomarchy.workspaces" }, { id: "nomarchy.layout-switcher" }, { id: "nomarchy.apps" }],
        centerBegin: [],
        center: [{ id: "nomarchy.clock", format: "dddd HH:mm" }],
        centerEnd: [],
        right: [{ id: "nomarchy.tray" }, { id: "nomarchy.controls" }, { id: "nomarchy.audio" }]
      }
    },
    plugins: []
  })

  property var defaultsConfig: builtinShellConfig
  property var shellConfig: builtinShellConfig
  // shell.json has text the shell could not use; persisting would replace it with defaults.
  property bool userConfigUnreadable: false
  // Calling text() on a missing file retries the load and fires loadFailed again, so the config is cached here.
  property string userConfigText: ""
  property bool pluginReloading: false
  property bool pluginReloadPending: false

  onShellConfigChanged: {
    if (failedBarId !== "") failedBarId = ""
    pluginRegistry.registryRevision++
    pluginRegistry.pluginsChanged()
  }

  function applyShellConfig() {
    // Decide which source is canonical: a valid user shell.json overrides
    // defaults entirely; otherwise fall back to defaults. We do not deep-merge.
    var defaults = Util.isPlainObject(defaultsConfig) ? defaultsConfig : builtinShellConfig
    var user = null
    var userText = shell.userConfigText
    if (userText.trim()) {
      try {
        let parsed = JSON.parse(userText)
        if (Util.isPlainObject(parsed) && parsed.version === 1) user = parsed
        else if (Util.isPlainObject(parsed)) console.warn("shell.json missing version: 1, using defaults")
      } catch (e) {
        console.warn("shell.json parse failed, using defaults:", e)
      }
    }
    userConfigUnreadable = !!userText.trim() && !user
    shellConfig = user || defaults
  }

  function loadDefaults(raw) {
    var text = String(raw || "").trim()
    if (!text) {
      defaultsConfig = builtinShellConfig
      applyShellConfig()
      return
    }
    try {
      let parsed = JSON.parse(text)
      if (Util.isPlainObject(parsed) && parsed.version === 1) defaultsConfig = parsed
      else defaultsConfig = builtinShellConfig
    } catch (e) {
      console.warn("default shell.json parse failed, using builtin:", e)
      defaultsConfig = builtinShellConfig
    }
    applyShellConfig()
    if (!pluginRegistry.loaded) pluginRegistry.rescan()
  }

  function persistShellConfig(nextConfig) {
    var payload = JSON.parse(JSON.stringify(nextConfig))
    payload.version = 1
    shellConfig = payload
    if (userConfigUnreadable) {
      console.warn("shell.json is unreadable, not overwriting it; fix it to save bar changes")
      return
    }
    shell.userConfigText = JSON.stringify(payload, null, 2) + "\n"
    userConfigFile.setText(shell.userConfigText)
  }

  readonly property var barConfig: shellConfig && Util.isPlainObject(shellConfig.bar) ? shellConfig.bar : builtinShellConfig.bar
  onBarConfigChanged: {
    if (bar && "barConfig" in bar)
      bar.barConfig = shell.barConfig
  }
  FileView {
    id: defaultsFile
    path: shell.defaultsPath
    watchChanges: true
    printErrors: false
    onLoaded: shell.loadDefaults(text())
    onLoadFailed: function(error) {
      console.warn("default shell.json load failed: " + error + " path=" + shell.defaultsPath)
      shell.loadDefaults("")
    }
    onFileChanged: reload()
  }

  FileView {
    id: userConfigFile
    path: shell.userConfigPath
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onLoaded: {
      shell.userConfigText = text() || ""
      shell.applyShellConfig()
    }
    onLoadFailed: function(error) {
      shell.userConfigText = ""
      shell.applyShellConfig()
    }
    onFileChanged: reload()
  }

  Component.onCompleted: {
    console.log("nomarchy-shell paths",
      "nomarchyPath=" + shell.nomarchyPath,
      "shellDir=" + Quickshell.shellDir,
      "firstPartyPluginsDir=" + shell.firstPartyPluginsDir,
      "defaultsPath=" + shell.defaultsPath,
      "userConfigPath=" + shell.userConfigPath)
    pluginRegistry.firstPartyDir = shell.firstPartyPluginsDir
    pluginRegistry.shellConfigProvider = function() { return shell.shellConfig }
    pluginRegistry.shellConfigMutator = function(mutate) { shell.mutateShellConfig(mutate) }
    // The registry loads in loadDefaults(), once shell.json is known: its disabledPlugins decide
    // which services start, and syncing before that would start every one of them.
    // The built-in waku tiler is the default on every port (keys.conf drives it).
    S.Tiling.layout = "mainStack"
    S.Tiling.gap = 8
    S.Tiling.ratio = 0.5
    S.Tiling.enabled = true
  }

  function mutateShellConfig(mutator) {
    var copy = JSON.parse(JSON.stringify(shellConfig || builtinShellConfig))
    mutator(copy)
    persistShellConfig(copy)
  }

  // Exposed as a property so child plugins (notifications, future panels)
  // can read barSize/barHidden/position to anchor relative to the active bar.
  readonly property string defaultBarId: "nomarchy.bar"
  readonly property string selectedBarId: {
    var config = shell.barConfig
    if (Util.isPlainObject(config)) {
      let configured = Util.canonicalWidgetId(String(config.id || ""))
      if (configured) return configured
    }
    return shell.defaultBarId
  }
  property string failedBarId: ""
  readonly property bool selectedBarAvailable: {
    var revision = shell.pluginRegistry.registryRevision
    return shell.barOptionAvailable(shell.selectedBarId)
  }
  readonly property string activeBarId: selectedBarId !== failedBarId && selectedBarAvailable ? selectedBarId : defaultBarId
  readonly property var activeBarManifest: {
    var revision = shell.pluginRegistry.registryRevision
    return shell.barManifestFor(shell.activeBarId)
  }
  readonly property string activeBarSourceUrl: activeBarId === defaultBarId ? "" : shell.pluginRegistry.entryPointUrl(activeBarManifest, "bar")
  property var bar: null

  onSelectedBarIdChanged: if (failedBarId !== "") failedBarId = ""

  function barManifestFor(pluginId) {
    var plugins = shell.pluginRegistry ? shell.pluginRegistry.installedPlugins : null
    return plugins ? plugins[String(pluginId || "")] || null : null
  }

  function isBarOptionManifest(manifest) {
    return manifest
      && Array.isArray(manifest.kinds)
      && manifest.kinds.indexOf("bar") !== -1
      && manifest.entryPoints
      && manifest.entryPoints.bar
  }

  function barOptionAvailable(pluginId) {
    var id = String(pluginId || "")
    if (id === "" || id === shell.defaultBarId) return true
    var manifest = shell.barManifestFor(id)
    return shell.isBarOptionManifest(manifest) && shell.pluginRegistry.entryPointUrl(manifest, "bar") !== ""
  }

  function isActiveBarOption(pluginId) {
    return String(pluginId || "") === shell.activeBarId
  }

  function configureBar(target, manifest) {
    if (!target) return
    if ("nomarchyPath" in target) target.nomarchyPath = shell.nomarchyPath
    if ("shell" in target) target.shell = shell
    if ("manifest" in target) target.manifest = manifest
    if ("barWidgetRegistry" in target) target.barWidgetRegistry = shell.barWidgetRegistry
    if ("pluginRegistry" in target) target.pluginRegistry = shell.pluginRegistry
    if ("barConfig" in target) target.barConfig = shell.barConfig
    shell.bar = target
  }

  Component {
    id: defaultBarComponent

    Bar {
      nomarchyPath: shell.nomarchyPath
      barWidgetRegistry: shell.barWidgetRegistry
      barConfig: shell.barConfig
      shell: shell
      manifest: shell.barManifestFor(shell.defaultBarId)
    }
  }

  Loader {
    id: defaultBarLoader

    active: shell.activeBarId === shell.defaultBarId
    sourceComponent: defaultBarComponent
    onLoaded: shell.configureBar(item, shell.barManifestFor(shell.defaultBarId))
    onActiveChanged: if (!active && shell.activeBarId !== shell.defaultBarId) shell.bar = null
  }

  Loader {
    id: pluginBarLoader

    active: !shell.pluginReloading && shell.activeBarId !== shell.defaultBarId && shell.activeBarSourceUrl !== ""
    source: shell.activeBarId !== shell.defaultBarId ? shell.activeBarSourceUrl : ""
    asynchronous: true
    onLoaded: shell.configureBar(item, shell.activeBarManifest)
    onActiveChanged: if (!active) shell.bar = null
    onStatusChanged: {
      if (status === Loader.Error) {
        console.warn("bar option " + shell.activeBarId + " failed to load, falling back to " + shell.defaultBarId)
        shell.failedBarId = shell.activeBarId
      }
    }
  }

  // ------------------------------------------------------------- services
  //
  // Generic loader for any enabled plugin that declares kind "service".
  // First-party infrastructure services are implicitly enabled by the registry;
  // third-party services are enabled by adding the plugin id to shell.json.
  Item {
    id: serviceHost
    visible: false
  }

  property var _services: ({})

  // Reassigned as each service registers, so a binding that reads this before
  // looking a service up by id re-evaluates once that service exists.
  readonly property var services: _services

  function serviceFor(pluginId) {
    return _services[String(pluginId)] || null
  }

  function firstPartyServiceFor(pluginId) {
    return serviceFor(shell.pluginRegistry.resolveEnabledId(pluginId))
  }

  function isAuthenticationService(manifest, pluginId) {
    var key = String(pluginId || (manifest && manifest.id) || "")
    return AuthServiceStore.isTrusted(key)
      || (!!manifest && Array.isArray(manifest.__hostCapabilities)
        && manifest.__hostCapabilities.indexOf("authentication") !== -1)
  }

  function ensureService(pluginId) {
    var key = String(pluginId)
    if (_services[key]) return _services[key]
    var manifest = pluginRegistry && pluginRegistry.installedPlugins
      ? pluginRegistry.installedPlugins[key] : null
    if (!manifest) return null
    if (!Array.isArray(manifest.kinds) || manifest.kinds.indexOf("service") === -1) return null
    if (!manifest.entryPoints || !manifest.entryPoints.service) return null
    var url = pluginRegistry.entryPointUrl(manifest, "service")
    if (!url) return null
    var authenticationService = shell.isAuthenticationService(manifest, key)
    if (authenticationService && AuthServiceStore.has(key)) return null

    var comp = Qt.createComponent(url, Component.PreferSynchronous)
    function finalize() {
      if (comp.status !== Component.Ready) {
        console.warn("service plugin load failed for " + key + ": " + comp.errorString())
        return
      }
      // Authentication services and third-party services have no visual
      // parent. Parenting either to serviceHost would let a plugin's object
      // traversal walk between the host and credential-bearing QML.
      var inst = comp.createObject(manifest.__isFirstParty && !authenticationService ? serviceHost : null)
      if (!inst) {
        console.warn("service plugin createObject returned null for", key)
        return
      }
      if ("nomarchyPath" in inst) inst.nomarchyPath = shell.nomarchyPath
      if ("shell" in inst) inst.shell = shell
      if ("manifest" in inst) inst.manifest = manifest
      if ("barWidgetRegistry" in inst) inst.barWidgetRegistry = shell.barWidgetRegistry
      if ("pluginRegistry" in inst) inst.pluginRegistry = shell.pluginRegistry
      if (authenticationService) {
        // Never publish lock/polkit through ShellRoot._services. The private JS
        // import retains their lifetime without adding a traversable property
        // or QObject parent back to the host shell.
        AuthServiceStore.put(key, inst)
      } else {
        let snext = ({})
        for (let sk in _services) snext[sk] = _services[sk]
        snext[key] = inst
        _services = snext
      }
    }
    if (comp.status === Component.Loading) {
      comp.statusChanged.connect(finalize)
      return null
    }
    finalize()
    return authenticationService ? null : (_services[key] || null)
  }

  function _syncServices() {
    if (!pluginRegistry || !pluginRegistry.installedPlugins) return
    var plugins = pluginRegistry.installedPlugins
    for (let id in plugins) {
      let m = plugins[id]
      if (!m) continue
      if (!Array.isArray(m.kinds) || m.kinds.indexOf("service") === -1) continue
      if (!m.entryPoints || !m.entryPoints.service) continue
      if (!pluginRegistry.isEnabled(id)) continue
      let authenticationService = shell.isAuthenticationService(m, id)
      if (_services[id]) {
        if (authenticationService) {
          // A service that gains a trusted authentication capability must move
          // out of the host's public service map before it is recreated.
          let published = _services[id]
          if (published && typeof published.destroy === "function") published.destroy()
          let withoutPublished = ({})
          for (let publishedId in _services)
            if (publishedId !== id) withoutPublished[publishedId] = _services[publishedId]
          _services = withoutPublished
        } else {
          // A kept instance outlives the rescan; hand it the fresh manifest.
          let kept = _services[id]
          if (kept && "shell" in kept) kept.shell = shell
          if (kept && "manifest" in kept) kept.manifest = m
          continue
        }
      }
      if (AuthServiceStore.has(id)) {
        if (authenticationService) {
          AuthServiceStore.updateManifest(id, m)
          continue
        }
        // A service that loses its trusted authentication capability can move
        // back to the ordinary service map only after the isolated copy dies.
        AuthServiceStore.destroy(id)
      }
      ensureService(id)
    }
    // Drop services for plugins that have been disabled or removed, or that
    // no longer declare a service entry point.
    for (let existingId in _services) {
      let stillThere = plugins[existingId]
      let stillService = stillThere && Array.isArray(stillThere.kinds)
        && stillThere.kinds.indexOf("service") !== -1
        && stillThere.entryPoints && stillThere.entryPoints.service
      let stillEnabled = stillThere && pluginRegistry.isEnabled(existingId)
      if (stillService && stillEnabled) continue
      let inst = _services[existingId]
      if (inst && typeof inst.destroy === "function") inst.destroy()
      let next = ({})
      for (let k in _services) if (k !== existingId) next[k] = _services[k]
      _services = next
    }
    // Authentication services are retained outside the root object graph, so
    // reconcile their disable/remove lifecycle separately from _services.
    var authenticationIds = AuthServiceStore.ids()
    for (let ai = 0; ai < authenticationIds.length; ai++) {
      let authenticationId = authenticationIds[ai]
      let authenticationManifest = plugins[authenticationId]
      let stillAuthenticationService = authenticationManifest
        && Array.isArray(authenticationManifest.kinds)
        && authenticationManifest.kinds.indexOf("service") !== -1
        && authenticationManifest.entryPoints
        && authenticationManifest.entryPoints.service
      if (stillAuthenticationService && pluginRegistry.isEnabled(authenticationId)
          && shell.isAuthenticationService(authenticationManifest, authenticationId)) continue
      AuthServiceStore.destroy(authenticationId)
    }
  }

  function serviceKeepLoaded(pluginId) {
    var plugins = pluginRegistry && pluginRegistry.installedPlugins
    var manifest = plugins ? plugins[pluginId] : null
    return !!(manifest && manifest.keepLoaded === true)
  }

  // keepLoaded services (lock, idle, polkit) must survive plugin hot-reload.
  // Destroying nomarchy.lock drops the ext-session-lock client while Hyprland
  // still holds the lock, which surfaces the crashed-lockscreen fallback.
  function unloadPluginServices() {
    var next = ({})
    for (let existingId in _services) {
      if (serviceKeepLoaded(existingId)) {
        next[existingId] = _services[existingId]
        continue
      }
      let inst = _services[existingId]
      if (inst && typeof inst.destroy === "function") inst.destroy()
    }
    _services = next
    var authenticationIds = AuthServiceStore.ids()
    for (let ai = 0; ai < authenticationIds.length; ai++) {
      let authenticationId = authenticationIds[ai]
      if (!serviceKeepLoaded(authenticationId))
        AuthServiceStore.destroy(authenticationId)
    }
  }

  Connections {
    target: shell.pluginRegistry
    function onPluginsChanged() {
      if (!shell.pluginReloading) shell._syncServices()
    }
  }

  // Writes inline settings to a bar layout entry or top-level plugin entry in
  // shell.json. moduleName is the entry id; settings is the merged plugin
  // state. Returns true if anything actually changed. Compute the proposed
  // new shellConfig in a local clone, and only persist if anything actually
  // changed so reactive bindings do not dirty shell.json unnecessarily.
  function updateEntryInline(moduleName, settings) {
    var stripped = Util.canonicalWidgetId(moduleName)
    var copy = JSON.parse(JSON.stringify(shellConfig || builtinShellConfig))
    if (!Util.isPlainObject(copy.bar)) copy.bar = { layout: {} }
    if (!Util.isPlainObject(copy.bar.layout)) copy.bar.layout = {}
    if (!Array.isArray(copy.plugins)) copy.plugins = []

    var sections = Util.barSections
    var foundInLayout = false
    var dirty = false
    for (let s = 0; s < sections.length; s++) {
      let arr = copy.bar.layout[sections[s]] || []
      for (let i = 0; i < arr.length; i++) {
        if (arr[i] && Util.canonicalWidgetId(arr[i].id) === stripped) {
          let next = { id: stripped }
          for (let k in settings) if (k !== "id") next[k] = settings[k]
          if (JSON.stringify(arr[i]) !== JSON.stringify(next)) {
            arr[i] = next
            dirty = true
          }
          foundInLayout = true
        }
      }
    }
    if (!foundInLayout) {
      for (let j = 0; j < copy.plugins.length; j++) {
        if (copy.plugins[j] && copy.plugins[j].id === stripped) {
          let pnext = { id: stripped }
          for (let pk in settings) if (pk !== "id") pnext[pk] = settings[pk]
          if (JSON.stringify(copy.plugins[j]) !== JSON.stringify(pnext)) {
            copy.plugins[j] = pnext
            dirty = true
          }
        }
      }
    }
    if (!dirty) return false
    persistShellConfig(copy)
    return true
  }

  // ---------------------------------------------------------- on-demand panels

  // openPanelIds is a plain object treated as a set. A plugin id maps to
  // `true` while the panel is summoned; deleting the key (well, building a new
  // object without it) hides it. Reassigning the whole object is required for
  // QML to notice the change.
  property var openPanelIds: ({})

  // Pending payloads to deliver to a plugin's open() once its loader resolves.
  // Keyed by plugin id; the value is an array so two summon() calls before
  // the Loader resolves both reach the plugin in arrival order rather than
  // the second clobbering the first.
  property var pendingPayloads: ({})

  // Bar-widget panels (audio, bluetooth, network, power, monitor, etc.)
  // are mounted inside the bar, not via the panel loader below. Route
  // summon/hide/toggle to the live bar instance so panel hotkeys survive
  // plugin/bar reloads: the bar re-creates the widget, while a fixed IPC
  // target only ever routes to one of the per-monitor instances.
  function isBarWidgetPanelPlugin(pluginId) {
    var plugins = shell.pluginRegistry.installedPlugins
    var m = plugins[String(pluginId || "")]
    if (!m || !Array.isArray(m.kinds)) return false
    if (m.kinds.indexOf("bar-widget") === -1) return false
    // Plugins that are also panel/overlay/menu kinds are owned by the
    // panel loader (e.g. nomarchy.menu); let that path handle them.
    var loaderKinds = ["panel", "overlay", "menu"]
    for (let i = 0; i < loaderKinds.length; i++) {
      if (m.kinds.indexOf(loaderKinds[i]) !== -1) return false
    }
    return true
  }

  function summon(pluginId, payloadJson) {
    var id = shell.pluginRegistry.resolveEnabledId(pluginId)
    if (!id) return false
    var plugins = shell.pluginRegistry.installedPlugins
    if (!plugins[id]) {
      console.warn("summon: unknown plugin", id)
      return false
    }
    // A disabled plugin has no Loader, so setting openPanelIds would only
    // produce an invisible "open" state that toggle() then has to unwind.
    // Tell the caller plainly instead of silently no-op'ing.
    if (!shell.pluginRegistry.isEnabled(id)) {
      console.warn("summon: plugin not enabled, not summoning:", id)
      return false
    }
    // Modal overlays are exclusive: other UI opening dismisses them.
    const modalOverlays = ["nomarchy.menu", "nomarchy.image-picker", "nomarchy.clipboard",
      "nomarchy.emojis", "nomarchy.reminders", "nomarchy.wifiqr"]
    for (let i = 0; i < modalOverlays.length; i++) {
      if (modalOverlays[i] !== id && shell.isPluginOpen(modalOverlays[i]))
        shell.hide(modalOverlays[i])
    }
    // Bar widgets take no payload; payloadJson is dropped on this path.
    if (shell.isBarWidgetPanelPlugin(id)) {
      let summoned = shell.bar && typeof shell.bar.summonBarWidget === "function"
        && shell.bar.summonBarWidget(id)
      if (!summoned) console.warn("summon: no live bar widget for:", id)
      return summoned === true
    }
    var next = ({})
    for (let k in openPanelIds) next[k] = openPanelIds[k]
    next[id] = true
    openPanelIds = next

    // Stash payload so the Loader.onLoaded handler can hand it to open().
    var pending = ({})
    for (let p in pendingPayloads) pending[p] = pendingPayloads[p].slice()
    var queue = pending[id] || []
    queue.push(payloadJson || "")
    pending[id] = queue
    pendingPayloads = pending

    // If the plugin is keepLoaded and already mounted, deliver immediately.
    deliverIfLoaded(id)
    return true
  }

  function hide(pluginId) {
    var id = shell.pluginRegistry.resolveEnabledId(pluginId)
    if (!id) return false
    if (shell.isBarWidgetPanelPlugin(id)) {
      let hidden = shell.bar && typeof shell.bar.hideBarWidget === "function"
        && shell.bar.hideBarWidget(id)
      if (!hidden) console.warn("hide: no live bar widget for:", id)
      return hidden === true
    }
    invokeIfLoaded(id, "close", null)
    if (!openPanelIds[id]) return true
    var next = ({})
    for (let k in openPanelIds) if (k !== id) next[k] = openPanelIds[k]
    openPanelIds = next
    return true
  }

  function isPluginOpen(pluginId) {
    var id = shell.pluginRegistry.resolveEnabledId(pluginId)
    if (shell.isBarWidgetPanelPlugin(id)) {
      return shell.bar && typeof shell.bar.isBarWidgetOpen === "function"
        ? shell.bar.isBarWidgetOpen(id)
        : false
    }
    var loader = panelLoaders[id]
    if (loader && loader.item && loader.item.opened !== undefined)
      return loader.item.opened === true
    return openPanelIds[id] === true
  }

  function toggle(pluginId, payloadJson) {
    var id = shell.pluginRegistry.resolveEnabledId(pluginId)
    return isPluginOpen(id) ? hide(id) : summon(id, payloadJson)
  }

  // Map of pluginId -> Loader, populated by the Instantiator delegate below.
  property var panelLoaders: ({})

  function registerPanelLoader(pluginId, loader) {
    var next = ({})
    for (let k in panelLoaders) next[k] = panelLoaders[k]
    next[pluginId] = loader
    panelLoaders = next
    deliverIfLoaded(pluginId)
  }

  function unregisterPanelLoader(pluginId) {
    if (!panelLoaders[pluginId]) return
    var next = ({})
    for (let k in panelLoaders) if (k !== pluginId) next[k] = panelLoaders[k]
    panelLoaders = next
  }

  function unloadPanels() {
    for (let id in panelLoaders) hide(id)
    panelEntryModel.clear()
    panelLoaders = ({})
    pendingPayloads = ({})
    openPanelIds = ({})
  }

  function deliverIfLoaded(pluginId) {
    var loader = panelLoaders[pluginId]
    if (!loader || !loader.item) return
    var queue = pendingPayloads[pluginId]
    if (!Array.isArray(queue) || queue.length === 0) return
    if (typeof loader.item.open === "function") {
      for (let i = 0; i < queue.length; i++) {
        try { loader.item.open(queue[i]) } catch (e) {
          console.warn("plugin " + pluginId + " open() threw:", e)
        }
      }
    }
    var next = ({})
    for (let k in pendingPayloads) if (k !== pluginId) next[k] = pendingPayloads[k].slice()
    pendingPayloads = next
  }

  function invokeIfLoaded(pluginId, method, arg) {
    var loader = panelLoaders[pluginId]
    if (!loader || !loader.item) return
    if (typeof loader.item[method] !== "function") return
    try { loader.item[method](arg) } catch (e) {
      console.warn("plugin " + pluginId + " " + method + "() threw:", e)
    }
  }

  function callIfLoaded(pluginId, method, arg) {
    var id = shell.pluginRegistry.resolveEnabledId(pluginId)
    var loader = panelLoaders[id]
    if (!loader || !loader.item) return "unknown"
    if (typeof loader.item[method] !== "function") return "unknown"
    try {
      let result = loader.item[method](arg)
      return result === undefined || result === null ? "ok" : String(result)
    } catch (e) {
      console.warn("plugin " + id + " " + method + "() threw:", e)
      return "error"
    }
  }

  // One Loader per discoverable panel/overlay/menu plugin. Active when the
  // host marks it open. The Loader holds onto the instance while active so the
  // plugin's FloatingWindow + state survive between summons within a session.
  //
  // The entries live in a ListModel synced in place. Handing the Instantiator
  // a fresh array instead rebuilt every panel on every plugin change, four
  // times over during startup: each rebuild started a new asynchronous load of
  // every keepLoaded panel while the last was in flight, so two OSDs could run
  // at once, each registering its IPC handler. A full plugin reload clears
  // the model in unloadPanels, so panels still rebuild from fresh code then.
  ListModel { id: panelEntryModel }

  function syncPanelEntries() {
    var wanted = ({})
    var order = []
    var entries = computePanelEntries()
    for (let i = 0; i < entries.length; i++) {
      let entry = entries[i]
      entry.sourceUrl = String(shell.pluginRegistry.entryPointUrl(entry.manifest, entry.kind) || "")
      wanted[entry.id] = entry
      order.push(entry.id)
    }

    // Keep an entry whose plugin still loads the same way; drop the rest.
    for (let j = panelEntryModel.count - 1; j >= 0; j--) {
      let row = panelEntryModel.get(j)
      let next = wanted[row.pluginId]
      if (next && next.kind === row.entryKind && next.keepLoaded === row.keepLoaded && next.sourceUrl === row.sourceUrl) {
        delete wanted[row.pluginId]
      } else {
        panelEntryModel.remove(j)
      }
    }

    for (let k = 0; k < order.length; k++) {
      let added = wanted[order[k]]
      if (!added) continue
      panelEntryModel.append({ pluginId: added.id, entryKind: added.kind, keepLoaded: added.keepLoaded, sourceUrl: added.sourceUrl })
    }
  }

  function computePanelEntries() {
    var out = []
    var plugins = shell.pluginRegistry.installedPlugins
    var panelKinds = ["panel", "overlay", "menu"]
    for (let id in plugins) {
      let m = plugins[id]
      if (!m || !Array.isArray(m.kinds)) continue
      let matched = false
      for (let i = 0; i < panelKinds.length; i++)
        if (m.kinds.indexOf(panelKinds[i]) !== -1) { matched = true; break }
      if (!matched) continue
      if (!shell.pluginRegistry.isEnabled(id)) continue
      let kind = m.kinds.indexOf("panel") !== -1 ? "panel"
        : (m.kinds.indexOf("overlay") !== -1 ? "overlay" : "menu")
      out.push({ id: id, manifest: m, kind: kind, keepLoaded: m.keepLoaded === true })
    }
    return out
  }

  Connections {
    target: shell.pluginRegistry
    function onPluginsChanged() { if (!shell.pluginReloading) shell.syncPanelEntries() }
  }

  Instantiator {
    model: panelEntryModel
    active: true

    delegate: QtObject {
      id: panelEntry
      required property string pluginId
      required property string entryKind
      required property bool keepLoaded
      required property string sourceUrl
      // The manifest can be replaced on a rescan without the entry changing.
      readonly property var manifest: shell.pluginRegistry.installedPlugins[pluginId]

      property Loader panelLoader: Loader {
        source: panelEntry.sourceUrl
        active: panelEntry.sourceUrl !== "" && (panelEntry.keepLoaded || shell.openPanelIds[panelEntry.pluginId] === true)
        asynchronous: true
        onLoaded: {
          if (!item) return
          if ("nomarchyPath" in item) item.nomarchyPath = shell.nomarchyPath
          if ("shell" in item) item.shell = shell
          if ("manifest" in item) item.manifest = panelEntry.manifest
          if ("barWidgetRegistry" in item) item.barWidgetRegistry = shell.barWidgetRegistry
          if ("pluginRegistry" in item) item.pluginRegistry = shell.pluginRegistry
          // Plugins that pair a panel UI with a service entry read shared
          // state off `service`. Hand them the matching singleton if one was
          // loaded.
          if ("service" in item) item.service = shell.serviceFor(panelEntry.pluginId)
          shell.registerPanelLoader(panelEntry.pluginId, this)
        }
        onStatusChanged: {
          if (status === Loader.Error) {
            // Loader.errorString() reflects the source-load failure even when
            // sourceComponent is null. Surface both so the user sees something
            // actionable instead of a panel that silently refuses to open.
            let detail = errorString && errorString() ? errorString() : ""
            if (!detail && sourceComponent) detail = sourceComponent.errorString()
            console.warn("panel plugin " + panelEntry.pluginId + " failed to load:", detail)
            shell.hide(panelEntry.pluginId)
          }
        }
        Component.onDestruction: shell.unregisterPanelLoader(panelEntry.pluginId)
      }
    }
  }

  // ---------------------------------------------------------- plugin loader

  // Mirror plugin registry state into BarWidgetRegistry whenever it changes.
  // Each enabled plugin with kind "bar-widget" gets a Component created from
  // its manifest entry point and registered under its manifest id. Built-in
  // widgets use the same first-party manifest contract as third-party widgets.
  Connections {
    target: shell.pluginRegistry
    function onPluginsChanged() { if (!shell.pluginReloading) shell.syncPluginWidgets() }
  }

  property var pluginWidgetComponents: ({})

  function syncPluginWidgets() {
    var plugins = shell.pluginRegistry.installedPlugins
    var seen = ({})

    for (let pluginId in plugins) {
      let manifest = plugins[pluginId]
      if (!manifest || !manifest.kinds || manifest.kinds.indexOf("bar-widget") === -1) continue
      if (!shell.pluginRegistry.isEnabled(pluginId)) continue

      let registryKey = String(manifest.id)
      seen[registryKey] = true

      // Already loaded with matching source — leave it alone.
      let existing = pluginWidgetComponents[registryKey]
      let url = shell.pluginRegistry.entryPointUrl(manifest, "barWidget")
      if (!url) {
        console.warn("Plugin " + manifest.id + " has no barWidget entry point")
        continue
      }
      let meta = manifest.barWidget || {}
      meta = {
        displayName: meta.displayName || manifest.name,
        description: meta.description || manifest.description,
        category: meta.category || "Plugin",
        allowMultiple: meta.allowMultiple === true,
        defaults: meta.defaults || {},
        settingsForm: meta.settingsForm || "",
        schema: meta.schema || [],
        pluginId: manifest.id,
        sourceDir: manifest.__sourceDir || "",
        source: "plugin",
        firstParty: !!manifest.__isFirstParty
      }

      // A load already in flight for this URL registers itself when it
      // finishes. Starting a second one produces a second Component for the
      // same widget, and swapping a slot's component rebuilds its item —
      // briefly running two of the widget, each registering its IPC handler.
      if (existing && existing.url === url && !existing.component) continue

      // If the component URL is unchanged, just refresh the metadata in
      // place. We can't skip this even when the URL matches: manifests can
      // change schema, defaults, or sourceDir between rescans, and the
      // settings panel reads metadata from the registry.
      if (existing && existing.url === url && shell.barWidgetRegistry.has(registryKey)) {
        shell.barWidgetRegistry.register(registryKey, existing.component, meta)
        continue
      }

      loadPluginWidget(registryKey, url, meta)
    }

    // Drop registrations for plugins that are no longer present or enabled.
    var allIds = shell.barWidgetRegistry.availableIds()
    for (let i = 0; i < allIds.length; i++) {
      let id = allIds[i]
      if (!pluginWidgetComponents[id]) continue
      if (!seen[id]) {
        shell.barWidgetRegistry.unregister(id)
        let next = ({})
        for (let k in pluginWidgetComponents) if (k !== id) next[k] = pluginWidgetComponents[k]
        pluginWidgetComponents = next
      }
    }
  }

  function unloadPluginWidgets() {
    for (let id in pluginWidgetComponents) shell.barWidgetRegistry.unregister(id)
    pluginWidgetComponents = ({})
  }

  function reloadPlugins() {
    if (shell.pluginReloading || shell.pluginRegistry.scanning) {
      shell.pluginReloadPending = true
      return
    }
    shell.pluginReloading = true
    shell.unloadPanels()
    shell.unloadPluginServices()
    shell.unloadPluginWidgets()
    Qt.callLater(shell.finishPluginReload)
  }

  function finishPluginReload() {
    if (!shell.pluginReloading) return
    if (shell.pluginRegistry.scanning) {
      shell.pluginReloadPending = true
      return
    }
    if (typeof Qt.clearComponentCache === "function") Qt.clearComponentCache()
    shell.pluginRegistry.rescan()
  }

  Connections {
    target: shell.pluginRegistry
    function onScanFinished() {
      if (shell.pluginReloadPending) {
        shell.pluginReloadPending = false
        shell.pluginReloading = false
        Qt.callLater(shell.reloadPlugins)
        return
      }
      shell.pluginReloading = false
      shell._syncServices()
      shell.syncPanelEntries()
      shell.syncPluginWidgets()
    }
  }

  function setPluginWidgetComponent(registryKey, entry) {
    var next = ({})
    for (let k in pluginWidgetComponents) if (k !== registryKey) next[k] = pluginWidgetComponents[k]
    if (entry) next[registryKey] = entry
    pluginWidgetComponents = next
  }

  function loadPluginWidget(registryKey, url, meta) {
    // Claim the key before the component exists. Qt.createComponent is
    // asynchronous and syncPluginWidgets runs several times while the shell
    // starts, so without a marker the later passes cannot tell a load in
    // flight from one that never happened.
    setPluginWidgetComponent(registryKey, { url: url, component: null })

    var comp = Qt.createComponent(url, Component.Asynchronous)
    function finalize() {
      if (comp.status === Component.Ready) {
        shell.barWidgetRegistry.register(registryKey, comp, meta)
        shell.setPluginWidgetComponent(registryKey, { url: url, component: comp })
      } else if (comp.status === Component.Error) {
        console.warn("Plugin widget " + registryKey + " failed: " + comp.errorString())
        // Drop the claim so a later rescan can retry.
        shell.setPluginWidgetComponent(registryKey, null)
        shell.pluginRegistry.pluginLoadFailed(registryKey, comp.errorString())
      }
    }
    if (comp.status === Component.Loading) {
      comp.statusChanged.connect(finalize)
    } else {
      finalize()
    }
  }

  // ------------------------------------------------------ global shortcuts
  //
  // Bindings that open a menu route or panel, or step the volume, dispatch
  // these through Hyprland, so a keypress reaches the shell without spawning
  // an IPC client or script. The list is shared with default/hypr/helpers.lua, which binds a
  // route or panel missing from it through the command instead.

  function parseShortcuts(raw) {
    var entries = []
    var lines = String(raw || "").split("\n")
    for (let i = 0; i < lines.length; i++) {
      let match = /^([A-Za-z]+)\s+(\S+)\s*$/.exec(lines[i])
      if (match && ["menu", "panel", "audio", "brightness", "ipc"].indexOf(match[1]) !== -1)
        entries.push({ kind: match[1], target: match[2], name: match[1] + "." + match[2] })
    }
    return entries
  }

  // The IPC targets an ipc shortcut may name, and the service that owns each.
  readonly property var ipcShortcutServices: ({ media: "nomarchy.media", notifications: "nomarchy.notifications" })

  function runShortcut(entry) {
    if (entry.kind === "menu") {
      shell.toggle("nomarchy.menu", JSON.stringify({ menu: entry.target }))
    } else if (entry.kind === "ipc") {
      // "media.next" runs the media service's own IPC handler for next.
      let dot = entry.target.indexOf(".")
      let target = entry.target.slice(0, dot)
      let method = entry.target.slice(dot + 1)
      let service = shell.serviceFor(shell.ipcShortcutServices[target] || "")
      if (!service || !service.runShortcut(method))
        Util.execArgv(["nomarchy-shell", target, method])
    } else if (entry.kind === "brightness") {
      if (!shell.brightnessKeys.handle(entry.target))
        Util.execArgv(["nomarchy-brightness-display", entry.target === "raise" ? "+5%" : "5%-"])
    } else if (entry.kind === "audio") {
      let media = shell.serviceFor("nomarchy.media")
      if (!media || !media.handleVolumeKey(entry.target))
        Util.execArgv(["nomarchy-audio-output-volume", entry.target])
    } else {
      shell.toggle(entry.target, "{}")
    }
  }

  FileView {
    id: shortcutsFile
    path: shell.nomarchyPath + "/default/nomarchy/shortcuts"
    watchChanges: true
    onFileChanged: reload()
  }

  Variants {
    model: shell.parseShortcuts(shortcutsFile.text())

    GlobalShortcut {
      required property var modelData

      appid: "nomarchy"
      name: modelData.name
      description: modelData.kind === "audio" || modelData.kind === "brightness" ? (modelData.kind === "audio" ? "Volume " : "Brightness ") + modelData.target : (modelData.kind === "ipc" ? "Run " + modelData.target : "Toggle the " + modelData.target + " " + modelData.kind)
      onPressed: shell.runShortcut(modelData)
    }
  }

  // Windows port: hotkeys the engine registers itself (Hyprland binds them on Linux).
  GlobalShortcut {
    appid: "nomarchy"
    name: "nomarchy-menu-key"
    description: "Nomarchy menu"
    // Ctrl+Alt+Space is Claude's global shortcut, so another program already owns it.
    keys: "Alt+Shift+Space"
    onPressed: shell.toggle("nomarchy.menu", "{\"menu\":\"root\"}")
  }

  GlobalShortcut {
    appid: "nomarchy"
    name: "nomarchy-apps-key"
    description: "Nomarchy apps"
    keys: "Alt+Space"
    onPressed: shell.toggle("nomarchy.menu", "{\"menu\":\"apps\"}")
  }

  GlobalShortcut {
    appid: "nomarchy"
    name: "nomarchy-theme-key"
    description: "Theme switcher"
    keys: "Ctrl+Alt+T"
    onPressed: shell.toggle("nomarchy.image-picker", "{\"source\":\"themes\"}")
  }

  GlobalShortcut {
    appid: "nomarchy"
    name: "nomarchy-background-key"
    description: "Background switcher"
    keys: "Ctrl+Alt+B"
    onPressed: shell.toggle("nomarchy.image-picker", "{\"source\":\"wallpapers\"}")
  }

  GlobalShortcut {
    appid: "nomarchy"
    name: "nomarchy-emoji-key"
    description: "Emoji picker (Windows)"
    keys: "Ctrl+Alt+E"
    onPressed: Quickshell.execDetached(["powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", String(Quickshell.shellDir) + "/tools/winkeys.ps1", "emoji"])
  }

  GlobalShortcut {
    appid: "nomarchy"
    name: "nomarchy-clipboard-key"
    description: "Clipboard history (Windows)"
    keys: "Ctrl+Alt+V"
    onPressed: Quickshell.execDetached(["powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", String(Quickshell.shellDir) + "/tools/winkeys.ps1", "clipboard"])
  }

  // The Unix-socket IPC server (SocketServer) is left out of the Windows port: the engine has
  // no Quickshell.Io sockets. ShellIpc targets below still register with IpcRegistry.

  // --------------------------------------------------- image selector IPC

  function imagePickerItem() {
    var loader = panelLoaders["nomarchy.image-picker"]
    return loader && loader.item ? loader.item : null
  }

  Commons.ShellIpc {
    target: "image-selector"

    function open(imageDirs: string,
                  imageRowsB64: string,
                  selectedImage: string,
                  selectionFile: string,
                  doneFile: string,
                  showLabels: string,
                  filterable: string): string {
      var payload = JSON.stringify({
        imageDirs: imageDirs,
        imageRows: Util.decodeBase64(imageRowsB64),
        selectedImage: selectedImage,
        selectionFile: selectionFile,
        doneFile: doneFile,
        showLabels: showLabels,
        filterable: filterable
      })
      return shell.summon("nomarchy.image-picker", payload) ? "ok" : "unknown"
    }

    function preload(imageRowsB64: string,
                     selectedImage: string,
                     showLabels: string,
                     filterable: string): string {
      var picker = shell.imagePickerItem()
      if (picker && typeof picker.preloadRows === "function") {
        picker.preloadRows(Util.decodeBase64(imageRowsB64), selectedImage,
                           showLabels, filterable)
      }
      return "ok"
    }

    function cancel(doneFile: string): string {
      var picker = shell.imagePickerItem()
      if (picker && typeof picker.closeSelector === "function") {
        picker.closeSelector(doneFile || "")
      } else {
        shell.hide("nomarchy.image-picker")
      }
      return "ok"
    }

    function ping(): string {
      return "ok"
    }

  }

  // ---------------------------------------------------------- shell IPC

  Commons.ShellIpc {
    target: "shell"

    function prepareThemeIntro(fromPath: string, token: string, colorsB64: string, shellB64: string): void {
      shell.bootIntro.prepareTheme(fromPath, token, colorsB64, shellB64)
    }

    // A theme switch whose cover is up hands the rest over: the still, the
    // intro if there is one, the reveal and Hyprland's reload.
    function playThemeIntro(token: string, stillPath: string, introPath: string, prepared: string): string {
      return shell.backgroundSwitch.play(token, stillPath, introPath, prepared)
    }

    // nomarchy-theme-bg-set's change, with the intro it found or none.
    function switchBackground(path: string, introPath: string): string {
      return shell.backgroundSwitch.switchTo(path, introPath)
    }

    // What the latest background selection names, ahead of the link while
    // its change is still queued or setting up.
    function selectedBackground(): string {
      return shell.backgroundSwitch.selected()
    }

    // A cover is up or revealing, so the screen does not yet show a frame a
    // new switch could capture as its own outgoing cover.
    function themeIntroBusy(): string {
      return shell.backgroundSwitch.busy ? "pending" : "ready"
    }

    function themeIntroStatus(token: string): string {
      return shell.bootIntro.themeStatus(token)
    }

    function themeIntroCoverStatus(token: string): string {
      return shell.bootIntro.themeCoverStatus(token)
    }

    function wallpaperTheme(): string {
      return shell.wallpaperTheme.request(true)
    }

    function ping(): string {
      return "ok"
    }

    function applyTheme(colorsB64: string, shellB64: string): string {
      if (shell.bootIntro) shell.bootIntro.cancelTheme()
      var background = shell.firstPartyServiceFor("nomarchy.background")
      if (background && typeof background.setPendingTheme === "function" && typeof background.applyPendingTheme === "function") {
        background.setPendingTheme(colorsB64, shellB64)
        background.applyPendingTheme()
        return "ok"
      }
      var colorsRaw = ""
      var shellRaw = ""
      try { colorsRaw = Qt.atob(String(colorsB64 || "")) } catch (e) { colorsRaw = "" }
      try { shellRaw = Qt.atob(String(shellB64 || "")) } catch (e2) { shellRaw = "" }
      Commons.Color.loadColors(colorsRaw)
      Commons.Color.loadShell(shellRaw)
      Style.scheduleRefresh()
      return "ok"
    }

    // Super+I goes through the bar's reader, which keeps a choice made before
    // any text field has focus until one does.
    function cycleInput(direction: string): string {
      return Commons.InputMethodState.cycle(direction === "back") ? "ok" : "not running"
    }

    function rescanPlugins(): void {
      shell.reloadPlugins()
    }

    function reloadConfig(): string {
      userConfigFile.reload()
      return "ok"
    }

    // Named for the two-state toggle it once was; it now cycles the bar
    // background from clear to glassy to opaque and around.
    function toggleBarTransparency(): string {
      if (shell.bar && typeof shell.bar.cycleBackground === "function") {
        shell.bar.cycleBackground()
        return "ok"
      }
      return "no-bar"
    }

    function setPluginEnabled(id: string, enabled: string): string {
      return shell.pluginRegistry.setEnabled(id, enabled === "true") ? "ok" : "unknown"
    }

    function enablePlugin(id: string, placementJson: string): string {
      try {
        let placement = JSON.parse(placementJson || "{}")
        if (shell.pluginRegistry.setEnabled(id, true, placement)) return "ok"
        return shell.pluginRegistry.lastEnableError || "unknown"
      } catch (e) {
        return "invalid placement: " + e
      }
    }

    // Enable, but only where the widget is not on the bar already, so a caller
    // that cannot know whether it ran before leaves a placed widget alone.
    function putBarWidget(id: string, placementJson: string): string {
      try {
        let error = shell.pluginRegistry.putBarWidget(id, JSON.parse(placementJson || "{}"))
        return error ? error : "ok"
      } catch (e) {
        return "invalid placement: " + e
      }
    }

    function moveBarWidget(id: string, placementJson: string): string {
      try {
        let error = shell.pluginRegistry.moveBarWidget(id, JSON.parse(placementJson || "{}"))
        return error ? error : "ok"
      } catch (e) {
        return "invalid placement: " + e
      }
    }

    function setBarWidget(id: string, key: string, valueJson: string, selectorJson: string): string {
      try {
        let value = JSON.parse(valueJson)
        let selector = JSON.parse(selectorJson || "{}")
        let error = shell.pluginRegistry.setBarWidget(id, key, value, selector)
        return error ? error : "ok"
      } catch (e) {
        return "invalid widget setting: " + e
      }
    }

    function listPlugins(): string {
      var out = []
      var plugins = shell.pluginRegistry.installedPlugins
      for (let id in plugins) {
        let kinds = plugins[id].kinds || []
        let isBarOption = Array.isArray(kinds) && kinds.indexOf("bar") !== -1
        let isBarWidget = Array.isArray(kinds) && kinds.indexOf("bar-widget") !== -1
        let active = isBarOption && shell.isActiveBarOption(id)
        let metadata = plugins[id].nomarchy
        let clonedFrom = Util.isPlainObject(metadata) ? String(metadata.clonedFrom || "") : ""
        out.push({
          id: id,
          name: plugins[id].name,
          kinds: kinds,
          // What `nomarchy plugin enable/disable` toggles: for a widget that is
          // its place in the bar, not whether its component is loadable.
          enabled: isBarOption ? active
            : (isBarWidget ? shell.pluginRegistry.inBar(id) : shell.pluginRegistry.isEnabled(id)),
          active: active,
          // A bar has no off, only a successor: you leave one by enabling
          // another, so there is nothing for disable to do to it. Said here so
          // that a caller offering the verbs does not have to read kinds and
          // work it out again.
          canDisable: !isBarOption,
          firstParty: !!plugins[id].__isFirstParty,
          clonedFrom: clonedFrom
        })
      }
      // Consumers should not each invent their own presentation order.
      out.sort(function(left, right) {
        var leftName = String(left.name || left.id)
        var rightName = String(right.name || right.id)
        if (leftName < rightName) return -1
        if (leftName > rightName) return 1
        return String(left.id).localeCompare(String(right.id))
      })
      return JSON.stringify(out)
    }

    // Returns the effective shell.json content as JSON. Useful for debugging
    // and for CLI tools that want to inspect the merged state without
    // re-implementing the load logic.
    function listShellConfig(): string {
      return JSON.stringify(shell.shellConfig || {})
    }

    function debugBarGeometry(): string {
      return JSON.stringify(shell.bar && shell.bar.debugBarGeometry ? shell.bar.debugBarGeometry() : [])
    }

    function summon(id: string, payloadJson: string): string {
      return shell.summon(id, payloadJson) ? "ok" : "unknown"
    }

    function hide(id: string): void {
      shell.hide(id)
    }

    function toggle(id: string, payloadJson: string): void {
      shell.toggle(id, payloadJson)
    }

    function isOpen(id: string): string {
      return shell.isPluginOpen(id) ? "open" : "closed"
    }

    // A bar section's panels answer to their position as well as their id, so a
    // hotkey can mean "the third panel in the right section" and keep meaning
    // it after the bar is rearranged. Returns the id it acted on, or "unknown"
    // when the section holds no panel at that position.
    function togglePanelAt(section: string, index: string): string {
      var id = shell.bar && typeof shell.bar.panelWidgetIdAt === "function"
        ? shell.bar.panelWidgetIdAt(section, index)
        : ""
      if (!id) return "unknown"
      shell.toggle(id, "{}")
      return id
    }

    function call(id: string, method: string, arg: string): string {
      return shell.callIfLoaded(id, method, arg)
    }
  }
}
