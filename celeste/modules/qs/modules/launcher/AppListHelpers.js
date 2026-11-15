.pragma library

function itemHeight(item) { return item ? item.implicitHeight : 0; }

function searchText(search) { return search.text; }

function stringField(entry, key) {
    return entry && entry[key] !== undefined ? String(entry[key]) : "";
}

function isFavourite(entry, favourites, strings) {
    return entry && strings.testRegexList(favourites, stringField(entry, "id"));
}

var windowsSettings = [
    { id: "windows-settings-home", name: "Settings", genericName: "Windows Settings", icon: "settings", settingsUri: "ms-settings:", keywords: ["all settings"] },
    { id: "windows-settings-apps", name: "Apps & features", genericName: "Windows Settings", comment: "Installed apps, Add or Remove Programs", icon: "applications-system", settingsUri: "ms-settings:appsfeatures", keywords: ["apps", "installed apps", "programs and features", "uninstall", "add remove programs", "add or remove programs"] },
    { id: "windows-settings-network", name: "Network & Internet", genericName: "Windows Settings", icon: "network-wired", settingsUri: "ms-settings:network", keywords: ["network", "wifi", "internet"] },
    { id: "windows-settings-bluetooth", name: "Bluetooth & Devices", genericName: "Windows Settings", icon: "bluetooth", settingsUri: "ms-settings:bluetooth", keywords: ["bluetooth", "devices"] },
    { id: "windows-settings-sound", name: "Sound", genericName: "Windows Settings", icon: "audio-volume-high", settingsUri: "ms-settings:sound", keywords: ["audio", "volume"] },
    { id: "windows-settings-notifications", name: "Notifications", genericName: "Windows Settings", icon: "notifications", settingsUri: "ms-settings:notifications", keywords: ["notifications", "alerts"] },
    { id: "windows-settings-power", name: "Power & Battery", genericName: "Windows Settings", icon: "battery", settingsUri: "ms-settings:powersleep", keywords: ["power", "battery", "sleep"] },
    { id: "windows-settings-update", name: "Windows Update", genericName: "Windows Settings", icon: "system-software-update", settingsUri: "ms-settings:windowsupdate", keywords: ["update", "updates"] },
    { id: "windows-settings-accounts", name: "Accounts", genericName: "Windows Settings", icon: "user-identity", settingsUri: "ms-settings:yourinfo", keywords: ["account", "profile", "your info"] },
    { id: "windows-settings-privacy", name: "Privacy & Security", genericName: "Windows Settings", icon: "security-high", settingsUri: "ms-settings:privacy", keywords: ["privacy", "security"] }
];

function windowsSettingsResults(query) {
    var terms = String(query || "").toLowerCase().replace(/[^a-z0-9]+/g, " ").trim().split(/\s+/);
    if (!terms[0]) return [];

    return windowsSettings.filter(function(page) {
        var text = [page.name, page.genericName, page.comment, page.keywords.join(" ")].join(" ")
            .toLowerCase().replace(/[^a-z0-9]+/g, " ");
        return terms.every(function(term) { return text.indexOf(term) >= 0; });
    });
}
