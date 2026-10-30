import QtQuick
import Quickshell
import Caelestia.Config
import qs.services
import qs.modules.drawers
import qs.daemons

// Trimmed from upstream: no Background (WlrLayer.Background is not behind the icons), AreaPicker,
// Lock. IdleMonitors loads without a lock. Modules to add, per work package:
//   WP6: qs.modules.launcher, qs.modules.osd, qs.modules.session
//   WP7: qs.modules.notifications, qs.modules.sidebar, qs.modules.utilities (toasts)
//   WP8: qs.modules.dashboard
ShellRoot {
    id: root

    Component.onCompleted: {
        // Force certain singletons to load on shell init instead of lazily
        Notifs;
        Players;
        Brightness;
        Weather.reload();

        if (GlobalConfig.utilities.vpn.enabled)
            VPN;
    }

    FontLoader {
        source: Qt.resolvedUrl("assets/google-sans-flex/GoogleSansFlex-VariableFont_GRAD,ROND,opsz,slnt,wdth,wght.ttf")
    }

    // Upstream expects Material Symbols Rounded to be installed. Windows has none, so the port ships it
    // (Apache-2.0, google/material-design-icons).
    FontLoader {
        source: Qt.resolvedUrl("assets/material-symbols/MaterialSymbolsRounded.ttf")
    }

    Binding {
        target: ShellState
        property: "shellRoot"
        value: root
    }

    // Modules
    Drawers {}

    // Daemons
    Shortcuts {}
    BatteryMonitor {}
    GameMode {}
    IdleInhibit {}
    IdleMonitors {}
}
