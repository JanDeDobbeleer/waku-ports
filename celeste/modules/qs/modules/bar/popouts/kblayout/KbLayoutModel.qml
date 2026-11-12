pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import Celeste
import Celeste.Config
import Celeste.I18n
import "KbLayoutHelpers.js" as KbLayoutHelpers

// TODO: handle this better later

Item {
    id: model

    property alias visibleModel: visibleList
    final property string activeLabel: ""
    final property int activeIndex: -1
    final property var _xkbMap: ({})
    final property bool _notifiedLimit: false

    function start() {
        xkbXmlBase.running = true;
        getKbLayoutOpt.running = true;
    }

    function refresh() {
        _notifiedLimit = false;
        getKbLayoutOpt.running = true;
    }

    function switchTo(idx: int): void {
        switchProc.command = ["hyprctl", "switchxkblayout", "all", String(idx)];
        switchProc.running = true;
    }

    function _buildXmlMap(xml: string): void {
        KbLayoutHelpers.buildXmlMap(model, xml, Tr, layoutsModel, fetchActiveLayouts);
    }

    function _short(desc: string): string {
        return KbLayoutHelpers.short(desc, Tr);
    }

    function _setLayouts(raw: string): void {
        KbLayoutHelpers.setLayouts(model, raw, layoutsModel, Tr);
    }

    function _rebuildVisible(): void {
        KbLayoutHelpers.rebuildVisible(model, visibleList, layoutsModel, GlobalConfig, Toaster, Tr);
    }

    function _pretty(token: string): string {
        return KbLayoutHelpers.pretty(model._xkbMap, token, Tr);
    }

    visible: false

    ListModel {
        id: visibleList
    }

    ListModel {
        id: layoutsModel
    }

    Process {
        id: xkbXmlBase

        command: ["xmllint", "--xpath", "//layout/configItem[name and description]", "/usr/share/X11/xkb/rules/base.xml"]
        stdout: StdioCollector {
            onStreamFinished: model._buildXmlMap(text)
        }
        onExited: exitCode => {
            if (exitCode !== 0)
                xkbXmlEvdev.running = true;
        }
    }

    Process {
        id: xkbXmlEvdev

        command: ["xmllint", "--xpath", "//layout/configItem[name and description]", "/usr/share/X11/xkb/rules/evdev.xml"]
        stdout: StdioCollector {
            onStreamFinished: model._buildXmlMap(text)
        }
    }

    Process {
        id: getKbLayoutOpt

        command: ["hyprctl", "-j", "getoption", "input:kb_layout"]
        stdout: StdioCollector {
            onStreamFinished: {
                KbLayoutHelpers.readLayoutOption(text, model, fetchActiveLayouts, fetchLayoutsFromDevices)
            }
        }
    }

    Process {
        id: fetchLayoutsFromDevices

        command: ["hyprctl", "-j", "devices"]
        stdout: StdioCollector {
            onStreamFinished: KbLayoutHelpers.readDeviceLayouts(text, model, fetchActiveLayouts)
        }
    }

    Process {
        id: fetchActiveLayouts

        command: ["hyprctl", "-j", "devices"]
        stdout: StdioCollector {
            onStreamFinished: KbLayoutHelpers.readActiveLayout(text, model, layoutsModel)
        }
    }

    Process {
        id: switchProc

        onExited: fetchActiveLayouts.running = true
    }
}
