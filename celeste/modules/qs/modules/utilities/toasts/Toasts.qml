pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Celeste
import Celeste.Config
import qs.components
import qs.services
import "ToastsHelpers.js" as ToastsHelpers

Item {
    id: root

    readonly final property int spacing: Tokens.spacing.small
    final property bool flag

    function shouldShowToast(toast: Toast): bool {
        if (!Notifs.hasFullscreen())
            return true;
        if (GlobalConfig.utilities.toasts.fullscreen === "all")
            return true;
        if (GlobalConfig.utilities.toasts.fullscreen === "important")
            return toast.type === Toast.Warning || toast.type === Toast.Error;
        return false;
    }

    implicitWidth: Tokens.sizes.utilities.toastWidth - Tokens.padding.medium * 2
    implicitHeight: {
        let h = -spacing;
        for (let i = 0; i < repeater.count; i++) {
            const item = repeater.itemAt(i) as ToastWrapper;
            if (!item.modelData.closed && !item.previewHidden)
                h += ToastsHelpers.itemHeight(item) + spacing;
        }
        return h;
    }

    Repeater {
        id: repeater

        model: ScriptModel {
            values: ToastsHelpers.visibleToasts(Toaster.toasts, root.shouldShowToast, Config.utilities.maxToasts)
            onValuesChanged: root.flagChanged()
        }

        ToastWrapper {}
    }

    component ToastWrapper: MouseArea {
        id: toast

        required final property int index
        required final property Toast modelData

        readonly final property bool previewHidden: {
            let extraHidden = 0;
            for (let i = 0; i < index; i++)
                if (Toaster.toasts[i].closed)
                    extraHidden++;
            return index >= Config.utilities.maxToasts + extraHidden;
        }

        onPreviewHiddenChanged: {
            if (initAnim.running && previewHidden)
                initAnim.stop();
        }

        opacity: modelData.closed || previewHidden ? 0 : 1
        scale: modelData.closed || previewHidden ? 0.7 : 1

        anchors.bottomMargin: {
            root.flag; // Force update
            let y = 0;
            for (let i = 0; i < index; i++) {
                const item = repeater.itemAt(i) as ToastWrapper;
                if (item && !item.modelData.closed && !item.previewHidden)
                    y += ToastsHelpers.itemHeight(item) + root.spacing;
            }
            return y;
        }

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        implicitHeight: toastInner.implicitHeight

        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: ToastsHelpers.close(modelData)

        Component.onCompleted: ToastsHelpers.lock(modelData, this)

        Anim {
            id: initAnim

            Component.onCompleted: running = !toast.previewHidden

            target: toast
            properties: "opacity,scale"
            from: 0
            to: 1
        }

        ParallelAnimation {
            running: toast.modelData.closed
            onStarted: toast.anchors.bottomMargin = toast.anchors.bottomMargin
            onFinished: ToastsHelpers.unlock(toast.modelData, toast)

            Anim {
                type: Anim.DefaultEffects
                target: toast
                property: "opacity"
                to: 0
            }
            Anim {
                target: toast
                property: "scale"
                to: 0.7
            }
        }

        ToastItem {
            id: toastInner

            modelData: toast.modelData
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on scale {
            Anim {}
        }

        Behavior on anchors.bottomMargin {
            Anim {}
        }
    }
}
