import QtQuick
import Quickshell
import waku.services as S

// The widgets page: a clock, load rings, your drives and a Run box. Built while the menu is open,
// so nothing samples the system while the menu is closed.
Item {
    id: root

    signal ran

    function bytes(n) {
        if (n >= 1073741824)
            return (n / 1073741824).toFixed(0) + " GB";
        if (n >= 1048576)
            return (n / 1048576).toFixed(0) + " MB";
        return (n / 1024).toFixed(0) + " KB";
    }

    function rate(n) {
        if (n >= 1048576)
            return (n / 1048576).toFixed(1);
        return (n / 1024).toFixed(0);
    }

    function rateUnit(n) {
        return n >= 1048576 ? "M" : "K";
    }

    function focusRun() {
        run.forceActiveFocus();
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }
    S.Cpu {
        id: cpu
        interval: 1500
    }
    S.Memory {
        id: mem
        interval: 3000
    }
    S.Gpu {
        id: gpu
        interval: 2000
    }
    S.Disks {
        id: disks
        interval: 15000
    }

    Column {
        anchors.fill: parent
        spacing: 12

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 0
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 4
                Text {
                    text: Qt.formatDateTime(clock.date, "h:mm")
                    color: Style.text
                    font.family: Style.display
                    font.pixelSize: 32
                    font.weight: Font.DemiBold
                }
                Text {
                    y: 12
                    text: Qt.formatDateTime(clock.date, "ss AP")
                    color: Style.accent
                    font.family: Style.font
                    font.pixelSize: 14
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(clock.date, "ddd d MMM yyyy")
                color: Style.dim
                font.family: Style.font
                font.pixelSize: Style.smallSize
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 32

            Ring {
                value: cpu.percent / 100
                centerText: cpu.ready ? Math.round(cpu.percent) : "…"
                unit: "%"
                caption: "CPU"
                color: Style.accent
            }
            Ring {
                value: mem.percent / 100
                centerText: mem.ready ? Math.round(mem.percent) : "…"
                unit: "%"
                caption: "MEM"
                color: Style.warn
            }
            Ring {
                visible: gpu.available
                value: gpu.percent / 100
                centerText: gpu.ready ? Math.round(gpu.percent) : "…"
                unit: "%"
                caption: "GPU"
                color: Style.good
            }
            Ring {
                value: Math.min(1, S.Network.rxBytesPerSecond / 12500000)   // full ring at 100 Mbit/s
                centerText: root.rate(S.Network.rxBytesPerSecond)
                unit: root.rateUnit(S.Network.rxBytesPerSecond)
                caption: "NET ↓"
                color: Style.net
            }
        }

        Column {
            width: parent.width
            spacing: 2
            Repeater {
                model: disks.disks
                DriveBar {
                    required property var modelData
                    width: parent.width
                    letter: String(modelData.mount).substring(0, 2)
                    used: modelData.percent / 100
                    freeText: root.bytes(modelData.free) + " free"
                    color: modelData.system ? "#e0b84c" : Style.accent
                }
            }
        }
    }

    Column {
        anchors.bottom: parent.bottom
        width: parent.width
        spacing: 4

        Text {
            text: "RUN"
            color: Style.dim
            font.family: Style.font
            font.pixelSize: 10
        }
        Rectangle {
            width: parent.width
            height: 28
            radius: 4
            color: "#26ffffff"
            border.color: run.activeFocus ? Style.accent : "transparent"
            border.width: 1

            Text {
                x: 8
                anchors.verticalCenter: parent.verticalCenter
                text: ">"
                color: Style.accent
                font.family: Style.font
                font.pixelSize: Style.fontSize
            }
            TextInput {
                id: run
                x: 24
                width: parent.width - 32
                anchors.verticalCenter: parent.verticalCenter
                color: Style.text
                selectionColor: Style.accent
                font.family: Style.font
                font.pixelSize: Style.fontSize
                clip: true
                onAccepted: {
                    if (text.trim() === "")
                        return;
                    Quickshell.execDetached(["cmd.exe", "/c", "start", "", text.trim()]);
                    text = "";
                    root.ran();
                }
            }
            Text {
                x: 24
                anchors.verticalCenter: parent.verticalCenter
                visible: run.text === "" && !run.activeFocus
                text: "Type a command…"
                color: Style.faint
                font.family: Style.font
                font.pixelSize: Style.fontSize
            }
        }
        Text {
            text: "Enter to run"
            color: Style.faint
            font.family: Style.font
            font.pixelSize: 10
        }
    }
}
