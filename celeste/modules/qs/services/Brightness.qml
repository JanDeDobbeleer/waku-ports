pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Celeste.Config
import waku.services as S
import qs.components.misc
import qs.services
import qs.compat
import "BrightnessHelpers.js" as BrightnessHelpers

// Brightness over waku's ControlCenter service (DDC/CI and the laptop panel). ControlCenter has
// one brightness value for the selected source, so every screen's `Monitor` shows that value.
// waku gap: no per-screen brightness.
Singleton {
    id: root

    readonly final property bool available: S.ControlCenter.brightnessAvailable
    readonly final property list<Monitor> monitors: variants.instances

    function getMonitorForScreen(screen: ShellScreen): Monitor {
        return BrightnessHelpers.getMonitorForScreen(screen, monitors);
    }

    function adjustForScreen(screen: ShellScreen, delta: real): void {
        BrightnessHelpers.adjustForScreen(screen, delta, monitors);
    }

    function getMonitor(query: string): Monitor {
        return BrightnessHelpers.getMonitor(query, monitors, Hypr);
    }

    function increaseBrightness(): void {
        BrightnessHelpers.adjustActive(1, GlobalConfig.services.brightnessIncrement, monitors, Hypr);
    }

    function decreaseBrightness(): void {
        BrightnessHelpers.adjustActive(-1, GlobalConfig.services.brightnessIncrement, monitors, Hypr);
    }

    Variants {
        id: variants

        model: Quickshell.screens // Don't respect excluded screens cause ipc

        Monitor {}
    }

    CustomShortcut {
        name: "brightnessUp"
        description: "Increase brightness"
        onPressed: root.increaseBrightness()
    }

    CustomShortcut {
        name: "brightnessDown"
        description: "Decrease brightness"
        onPressed: root.decreaseBrightness()
    }

    IpcHandler {
        function get(): real {
            return getFor("active");
        }

        // Allows searching by active/model/serial/id/name
        function getFor(query: string): real {
            return root.getMonitor(query)?.brightness ?? -1;
        }

        function set(value: string): string {
            return setFor("active", value);
        }

        // Handles brightness value like brightnessctl: 0.1, +0.1, 0.1-, 10%, +10%, 10%-
        function setFor(query: string, value: string): string {
            return BrightnessHelpers.setFor(root.getMonitor(query), query, value);
        }

        target: "brightness"
    }

    component Monitor: QtObject {
        id: monitor

        required final property ShellScreen modelData
        readonly final property bool isDdc: false
        readonly final property bool isAppleDisplay: false
        // 0..1. Stays 0 while the machine has no controllable display.
        readonly final property real brightness: S.ControlCenter.brightnessAvailable ? S.ControlCenter.brightness / 100 : 0

        function setBrightness(value: real): void {
            if (!S.ControlCenter.brightnessAvailable)
                return;
            S.ControlCenter.setBrightness(Math.round(Math.max(0, Math.min(1, value)) * 100));
        }
    }
}
