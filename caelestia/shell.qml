import QtQuick
import Quickshell
import Caelestia.Config
import qs.services
import qs.modules.drawers
import qs.modules.bar
import qs.daemons
import waku.services as S

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

        // The built-in waku tiler is the default on every port (keys.conf drives it).
        S.Tiling.layout = "mainStack";
        S.Tiling.gap = 8;
        S.Tiling.ratio = 0.5;
        S.Tiling.enabled = true;
    }

    Binding {
        target: ShellState
        property: "shellRoot"
        value: root
    }

    // Modules
    Drawers {}
    DebugIpc {}

    // Daemons
    Shortcuts {}
    BatteryMonitor {}
    GameMode {}
    IdleInhibit {}
    IdleMonitors {}
}
