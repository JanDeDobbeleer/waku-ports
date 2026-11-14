import QtQuick
import Quickshell
import Quickshell.Services.UPower
import Celeste
import Celeste.Config
import Celeste.I18n
import Celeste.Services
import "BatteryMonitorHelpers.js" as BatteryMonitorHelpers

Scope {
    id: root

    readonly final property list<var> warnLevels: BatteryMonitorHelpers.sortWarnLevels(GlobalConfig.general.battery.warnLevels)
    final property real lastPercentage: 100

    function handleBatteryWarnings(): void {
        root.lastPercentage = BatteryMonitorHelpers.handleWarnings(UPower.displayDevice.percentage * 100, UPower.onBattery, root.lastPercentage, root.warnLevels, hibernateTimer, GlobalConfig.general.battery.criticalLevel, Toaster, Tr, Toast.Error, Toast.Warning);
    }

    Connections {
        function onOnBatteryChanged(): void {
            if (!UPower.displayDevice.ready)
                return;

            if (UPower.onBattery) {
                if (GlobalConfig.utilities.toasts.chargingChanged)
                    Toaster.toast(Tr.tr("Charger unplugged"), Tr.tr("Battery is discharging"), "power_off", Toast.Info, 5000);
                root.handleBatteryWarnings();
            } else {
                if (GlobalConfig.utilities.toasts.chargingChanged)
                    Toaster.toast(Tr.tr("Charger plugged in"), Tr.tr("Battery is charging"), "power", Toast.Info, 5000);
                root.lastPercentage = 100;
            }
        }

        target: UPower
    }

    Connections {
        function onReadyChanged(): void {
            if (!UPower.displayDevice.ready)
                return;
            root.handleBatteryWarnings();
        }

        target: UPower.displayDevice
    }

    Connections {
        function onPercentageChanged(): void {
            if (!UPower.displayDevice.ready)
                return;
            root.handleBatteryWarnings();
        }

        target: UPower.displayDevice
    }

    Timer {
        id: hibernateTimer

        interval: 5000
        // SessionManager hibernates, or only logs under CELESTE_DRYRUN=1 or services.allowSystemActions=false.
        onTriggered: SessionManager.exec(["hibernate"], true)
    }
}
