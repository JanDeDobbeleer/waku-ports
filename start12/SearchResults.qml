pragma ComponentBehavior: Bound

import QtQuick
import waku.services as S
import "AppRowHelpers.js" as AppRowHelpers

// Apps and direct Windows Settings pages matching the search text, best first.
Item {
    id: root

    property string query: ""
    readonly property var windowsSettings: [
        { name: "Settings", icon: "settings", settingsUri: "ms-settings:", keywords: ["windows settings", "all settings"] },
        { name: "Apps & features", icon: "applications-system", settingsUri: "ms-settings:appsfeatures", keywords: ["apps", "installed apps", "add remove programs", "add or remove programs", "programs and features", "uninstall", "settings"] },
        { name: "Network & Internet", icon: "network-wired", settingsUri: "ms-settings:network", keywords: ["network", "wifi", "internet", "settings"] },
        { name: "Bluetooth & Devices", icon: "bluetooth", settingsUri: "ms-settings:bluetooth", keywords: ["bluetooth", "devices", "settings"] },
        { name: "Sound", icon: "audio-volume-high", settingsUri: "ms-settings:sound", keywords: ["audio", "volume", "settings"] },
        { name: "Notifications", icon: "notifications", settingsUri: "ms-settings:notifications", keywords: ["notifications", "alerts", "settings"] },
        { name: "Power & Battery", icon: "battery", settingsUri: "ms-settings:powersleep", keywords: ["power", "battery", "sleep", "settings"] },
        { name: "Windows Update", icon: "system-software-update", settingsUri: "ms-settings:windowsupdate", keywords: ["update", "updates", "settings"] },
        { name: "Accounts", icon: "user-identity", settingsUri: "ms-settings:yourinfo", keywords: ["account", "profile", "your info", "settings"] },
        { name: "Privacy & Security", icon: "security-high", settingsUri: "ms-settings:privacy", keywords: ["privacy", "security", "settings"] }
    ]
    readonly property var settingsResults: {
        const terms = query.toLowerCase().replace(/[^a-z0-9]+/g, " ").trim().split(/\s+/);
        if (!terms[0])
            return [];
        return windowsSettings.filter(page => {
            const text = [page.name, page.keywords.join(" ")].join(" ").toLowerCase().replace(/[^a-z0-9]+/g, " ");
            return terms.every(term => text.includes(term));
        });
    }
    readonly property var appResults: query === "" ? [] : S.AppsService.search(query, 40)
    readonly property var results: settingsResults.concat(appResults)
    readonly property var first: results.length > 0 ? results[0] : null

    signal launch(entry: var)
    signal context(entry: S.DesktopEntry, point: point)

    Text {
        text: root.results.length > 0 ? "Best match" : "No apps or settings match"
        color: Style.text
        font.family: Style.font
        font.pixelSize: Style.smallSize
        font.weight: Font.DemiBold
    }

    ListView {
        y: 28
        width: parent.width
        height: parent.height - 28
        clip: true
        model: root.results

        delegate: AppRow {
            required property var modelData
            required property int index
            width: ListView.view.width
            entry: modelData
            highlighted: index === 0
            onActivated: root.launch(modelData)
            onContextRequested: point => {
                if (AppRowHelpers.settingsUri(modelData) === "")
                    root.context(modelData, point);
            }
        }
    }
}
