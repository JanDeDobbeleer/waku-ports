pragma Singleton

import "ToastUtils.js" as ToastUtils

import QtQuick 6.10
import Quickshell

Singleton {
  id: root

  // Simple signal-based notification system
  // actionLabel: optional label for clickable action link
  // actionCallback: optional function to call when action is clicked
  signal notify(string title, string description, string icon, string type, int duration, string actionLabel, var actionCallback)
  signal dismiss

  // Convenience methods
  function showNotice(title: var, description: var, icon: var): void {
    ToastUtils.showNotice(root, title, description, icon, undefined, undefined, undefined);
  }

  function showNoticeDetailed(title: var, description: var, icon: var, duration: var, actionLabel: var, actionCallback: var): void {
    ToastUtils.showNotice(root, title, description, icon, duration, actionLabel, actionCallback);
  }

  function showWarning(title: var, description: var): void {
    ToastUtils.showWarning(root, title, description, undefined, undefined, undefined);
  }

  function showWarningDetailed(title: var, description: var, duration: var, actionLabel: var, actionCallback: var): void {
    ToastUtils.showWarning(root, title, description, duration, actionLabel, actionCallback);
  }

  function showError(title: var, description: var): void {
    ToastUtils.showError(root, title, description, undefined, undefined, undefined);
  }

  function showErrorDetailed(title: var, description: var, duration: var, actionLabel: var, actionCallback: var): void {
    ToastUtils.showError(root, title, description, duration, actionLabel, actionCallback);
  }

  function dismissToast() {
    dismiss();
  }
}
