.pragma library

function close(toast) {
    if (!toast.closed)
        toast.closed = true;
    if (toast._locks.length === 0)
        toast.finishedClose();
}
function lock(toast, sender) {
    var locks = toast._locks;
    if (locks.indexOf(sender) !== -1)
        return;
    toast._locks = locks.concat([sender]);
    if (sender.destroyed)
        sender.destroyed.connect(function() { unlock(toast, sender); });
}
function unlock(toast, sender) {
    var locks = toast._locks;
    var index = locks.indexOf(sender);
    if (index !== -1)
        toast._locks = locks.slice(0, index).concat(locks.slice(index + 1));
    if (index !== -1 && toast.closed)
        close(toast);
}
