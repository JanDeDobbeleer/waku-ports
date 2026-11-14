.pragma library

function lock(notification, item) { notification.lock(item); }
function unlock(notification, item) { notification.unlock(item); }
function stopTimer(timer) { timer.stop(); }
function startTimer(timer) { timer.start(); }
function close(notification) { notification.close(); }
function progressAngle(hints) { return ((hints.value || 0) / 100) * 360; }
function actionText(action) { return action.text; }
