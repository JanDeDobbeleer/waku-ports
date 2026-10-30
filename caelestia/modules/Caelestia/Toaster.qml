pragma Singleton

import QtQuick

// Port of upstream Toaster: the queue of toasts shown by the toast list. The newest toast is
// first. toasts is a plain array that is replaced on every change.
QtObject {
    id: root

    property var toasts: []

    function toast(title: string, message: var, icon: var, type: var, timeout: var): void {
        const kind = type ?? Toast.Info;
        let ms = timeout ?? 5000;
        if (ms <= 0)
            ms = kind === Toast.Warning ? 7000 : kind === Toast.Error ? 10000 : 5000;
        let ic = icon ?? "";
        if (!ic) {
            switch (kind) {
            case Toast.Success:
                ic = "check_circle_unread";
                break;
            case Toast.Warning:
                ic = "warning";
                break;
            case Toast.Error:
                ic = "error";
                break;
            default:
                ic = "info";
            }
        }

        const t = toastComponent.createObject(root, {
            title: title,
            message: message ?? "",
            icon: ic,
            type: kind,
            timeout: ms
        });
        t.finishedClose.connect(() => {
            const i = root.toasts.indexOf(t);
            if (i < 0)
                return;
            root.toasts = root.toasts.filter(x => x !== t);
            t.destroy();
        });
        root.toasts = [t, ...root.toasts];
    }

    property Component toastComponent: Component {
        Toast {}
    }
}
