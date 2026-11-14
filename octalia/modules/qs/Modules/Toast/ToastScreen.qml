pragma ComponentBehavior: Bound

import QtQuick 6.10
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services.UI
import "./ToastScreenUtils.js" as ToastScreenUtils

Item {
  id: root

  required property ShellScreen screen

  // Local queue for this screen only (bounded to prevent memory issues)
  property var messageQueue: []
  property int maxQueueSize: 10
  property bool isShowingToast: false

  // If true, immediately show new toasts
  property bool replaceOnNew: true

  Connections {
    target: ToastService

    function onNotify(title: var, description: var, icon: var, type: var, duration: var, actionLabel: var, actionCallback: var): void {
      root.enqueueToast({
                          "title": title,
                          "description": description,
                          "icon": icon,
                          "type": type,
                          "duration": duration,
                          "actionLabel": actionLabel || "",
                          "actionCallback": actionCallback || null,
                          "timestamp": Date.now()
                        });
    }

    function onDismiss(): void {
      root.dismissToast();
    }
  }

  // Clear queue on component destruction to prevent orphaned toasts
  Component.onDestruction: {
    messageQueue = [];
    isShowingToast = false;
    hideTimer.stop();
    quickSwitchTimer.stop();
  }

  function dismissToast(): void {
    if (windowLoader.item) {
      hideTimer.stop();
      ToastScreenUtils.hideToast(windowLoader.item);
    }
  }

  function enqueueToast(toastData: var): void {
    // Safe logging - fix the substring bug
    var descPreview = (ToastScreenUtils.field(toastData, "description") || "").substring(0, 100).replace(/\n/g, " ");
    Logger.d("ToastScreen", "Queuing", ToastScreenUtils.field(toastData, "type"), ":", ToastScreenUtils.field(toastData, "title"), descPreview);

    // Bounded queue to prevent unbounded memory growth
    if (ToastScreenUtils.arrayLength(messageQueue) >= maxQueueSize) {
      Logger.d("ToastScreen", "Queue full, dropping oldest toast");
      messageQueue.shift();
    }

    if (replaceOnNew && isShowingToast) {
      // Cancel current toast and clear queue for latest toast
      messageQueue = []; // Clear existing queue
      messageQueue.push(toastData);

      // Hide current toast immediately
      root.dismissToast();

      // Process new toast after a brief delay
      isShowingToast = false;
      quickSwitchTimer.restart();
    } else {
      // Queue the toast
      messageQueue.push(toastData);
      processQueue();
    }
  }

  Timer {
    id: quickSwitchTimer
    interval: 50 // Brief delay for smooth transition
    onTriggered: root.processQueue()
  }

  function processQueue(): void {
    if (ToastScreenUtils.arrayLength(messageQueue) === 0 || isShowingToast) {
      return;
    }

    var data = messageQueue.shift();
    isShowingToast = true;

    // Store the toast data for when loader is ready
    windowLoader.pendingToast = data;

    // Activate the loader - onStatusChanged will handle showing the toast
    windowLoader.active = true;
  }

  function onToastHidden(): void {
    isShowingToast = false;

    // Deactivate the loader to completely remove the window and free memory
    windowLoader.active = false;

    // Small delay before processing next toast
    hideTimer.restart();
  }

  Timer {
    id: hideTimer
    interval: 200
    onTriggered: root.processQueue()
  }

  // The loader that creates/destroys the PanelWindow as needed
  // This is good for RAM efficiency when toasts are infrequent
  Loader {
    id: windowLoader
    active: false // Only active when showing a toast

    // Store pending toast data
    property var pendingToast: null

    onStatusChanged: {
      // When loader becomes ready, show the pending toast
      if (status === Loader.Ready && pendingToast !== null) {
        ToastScreenUtils.showToast(item, pendingToast);
        pendingToast = null;
      }
    }

    sourceComponent: PanelWindow {
      id: panel

      property alias toastItem: toastContent

      screen: root.screen

      // Parse location setting
      readonly property string location: Settings.data.notifications?.location || "top_right"
      readonly property bool isTop: location.startsWith("top")
      readonly property bool isBottom: location.startsWith("bottom")
      readonly property bool isLeft: location.endsWith("_left")
      readonly property bool isRight: location.endsWith("_right")
      readonly property bool isCentered: location === "top" || location === "bottom"

      readonly property bool isFramed: Settings.data.bar.barType === "framed"
      readonly property real frameThickness: Settings.data.bar.frameThickness ?? 8

      readonly property string barPos: Settings.getBarPositionForScreen(panel.screen?.name)
      readonly property bool isFloating: Settings.data.bar.barType === "floating"
      readonly property real barHeight: Style.getBarHeightForScreen(panel.screen?.name)

      // Calculate bar and frame offsets for each edge separately
      readonly property int barOffsetTop: {
        if (barPos !== "top")
          return isFramed ? frameThickness : 0;
        const floatMarginV = isFloating ? Math.ceil(Settings.data.bar.marginVertical) : 0;
        return barHeight + floatMarginV;
      }

      readonly property int barOffsetBottom: {
        if (barPos !== "bottom")
          return isFramed ? frameThickness : 0;
        const floatMarginV = isFloating ? Math.ceil(Settings.data.bar.marginVertical) : 0;
        return barHeight + floatMarginV;
      }

      readonly property int barOffsetLeft: {
        if (barPos !== "left")
          return isFramed ? frameThickness : 0;
        const floatMarginH = isFloating ? Math.ceil(Settings.data.bar.marginHorizontal) : 0;
        return barHeight + floatMarginH;
      }

      readonly property int barOffsetRight: {
        if (barPos !== "right")
          return isFramed ? frameThickness : 0;
        const floatMarginH = isFloating ? Math.ceil(Settings.data.bar.marginHorizontal) : 0;
        return barHeight + floatMarginH;
      }

      readonly property int shadowPadding: Style.shadowBlurMax + Style.marginL

      // Anchoring
      anchors.top: isTop
      anchors.bottom: isBottom
      anchors.left: isLeft
      anchors.right: isRight

      // Margins for PanelWindow - only apply bar offset for the specific edge where the bar is
      margins.top: isTop ? barOffsetTop - shadowPadding + Style.marginM : 0
      margins.bottom: isBottom ? barOffsetBottom - shadowPadding + Style.marginM : 0
      margins.left: isLeft ? barOffsetLeft - shadowPadding + Style.marginM : 0
      margins.right: isRight ? barOffsetRight - shadowPadding + Style.marginM : 0

      implicitWidth: Math.round(toastContent.width)
      implicitHeight: Math.round(toastContent.height)

      color: "transparent"

      WlrLayershell.layer: (Settings.data.notifications && Settings.data.notifications.overlayLayer) ? WlrLayer.Overlay : WlrLayer.Top
      WlrLayershell.namespace: "octalia-toast-" + (screen?.name || "unknown")
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      WlrLayershell.exclusionMode: ExclusionMode.Ignore

      // Make shadow area click-through, only toast content is clickable
      mask: Region {
        x: 0
        y: 0
        width: panel.width
        height: panel.height
        intersection: Intersection.Xor

        Region {
          // The clickable content area is inset by shadowPadding from all edges
          x: panel.shadowPadding
          y: panel.shadowPadding
          width: Math.max(0, panel.width - panel.shadowPadding * 2)
          height: Math.max(0, panel.height - panel.shadowPadding * 2)
          intersection: Intersection.Subtract
        }
      }

      function showToast(title: var, description: var, icon: var, type: var, duration: var, actionLabel: var, actionCallback: var): void {
        toastContent.show(title, description, icon, type, duration, actionLabel, actionCallback);
      }

      function hideToast(): void {
        toastContent.hideImmediately();
      }

      Toast {
        id: toastContent
        onHidden: root.onToastHidden()
      }
    }
  }
}
