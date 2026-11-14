.pragma library

function visibleToasts(toasts, shouldShow, maxToasts) {
    var visible = [];
    var activeCount = 0;
    for (var i = 0; i < toasts.length; i++) {
        var toast = toasts[i];
        if (!shouldShow(toast))
            continue;
        visible.push(toast);
        if (!toast.closed && ++activeCount > maxToasts)
            break;
    }
    return visible;
}
function close(toast) { toast.close(); }
function lock(toast, item) { toast.lock(item); }
function unlock(toast, item) { toast.unlock(item); }

function itemHeight(item) { return item.implicitHeight; }
