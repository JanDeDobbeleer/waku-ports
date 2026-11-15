.pragma library

function appRows() {
  var pages = [
    { id: "apps-features", label: "Apps & features", uri: "ms-settings:appsfeatures", aliases: ["apps", "installed apps", "add remove programs", "add or remove programs", "programs and features", "uninstall"] },
    { id: "network", label: "Network & Internet", uri: "ms-settings:network", aliases: ["network", "wifi", "internet"] },
    { id: "bluetooth", label: "Bluetooth & Devices", uri: "ms-settings:bluetooth", aliases: ["bluetooth", "devices"] },
    { id: "sound", label: "Sound", uri: "ms-settings:sound", aliases: ["sound", "audio", "volume"] },
    { id: "notifications", label: "Notifications", uri: "ms-settings:notifications", aliases: ["notifications", "alerts"] },
    { id: "power", label: "Power & Battery", uri: "ms-settings:powersleep", aliases: ["power", "battery", "sleep"] },
    { id: "update", label: "Windows Update", uri: "ms-settings:windowsupdate", aliases: ["update", "updates"] },
    { id: "accounts", label: "Accounts", uri: "ms-settings:yourinfo", aliases: ["account", "profile", "your info"] },
    { id: "privacy", label: "Privacy & Security", uri: "ms-settings:privacy", aliases: ["privacy", "security"] },
    { id: "settings", label: "Settings", uri: "ms-settings:", aliases: ["windows settings", "all settings"] }
  ]
  var rows = []
  for (var i = 0; i < pages.length; i++) {
    var page = pages[i]
    rows.push({
      id: "apps.windows-settings." + page.id,
      parent: "apps",
      kind: "action",
      icon: "󰒓",
      appIcon: "",
      appId: "",
      label: page.label,
      title: "",
      target: "",
      description: "Windows Settings",
      action: "explorer.exe " + page.uri,
      provider: "",
      aliases: page.aliases,
      searchTerms: ["settings"],
      when: "",
      checked: "",
      disabled: "",
      order: 0
    })
  }
  return rows
}
