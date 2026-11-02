pragma Singleton

import QtQuick
import Quickshell
import waku.services as S
import qs.Commons
import qs.compat

Singleton {
  id: root

  // Component registration - only poll when something needs lock key state
  function registerComponent(componentId) {
    root._registered[componentId] = true;
    root._registered = Object.assign({}, root._registered);
    Logger.d("LockKeys", "Component registered:", componentId, "- total:", root._registeredCount);
  }

  function unregisterComponent(componentId) {
    delete root._registered[componentId];
    root._registered = Object.assign({}, root._registered);
    Logger.d("LockKeys", "Component unregistered:", componentId, "- total:", root._registeredCount);
  }

  property var _registered: ({})
  readonly property int _registeredCount: Object.keys(_registered).length
  readonly property bool shouldRun: _registeredCount > 0

  property bool capsLockOn: false
  property bool numLockOn: false
  property bool scrollLockOn: false

  signal capsLockChanged(bool active)
  signal numLockChanged(bool active)
  signal scrollLockChanged(bool active)

  // The engine's DesktopState reads the toggle state of the lock keys (GetKeyState) and polls only
  // while something is connected to it, so the connection is held only while a consumer registered.
  function _sync(emit) {
    const caps = S.DesktopState.capsLock;
    const num = S.DesktopState.numLock;
    const scroll = S.DesktopState.scrollLock;
    if (root.capsLockOn !== caps) {
      root.capsLockOn = caps;
      if (emit)
        root.capsLockChanged(caps);
    }
    if (root.numLockOn !== num) {
      root.numLockOn = num;
      if (emit)
        root.numLockChanged(num);
    }
    if (root.scrollLockOn !== scroll) {
      root.scrollLockOn = scroll;
      if (emit)
        root.scrollLockChanged(scroll);
    }
  }

  onShouldRunChanged: {
    // First read after polling starts updates the properties only (the OSD listens to the signals
    // and would flash on startup).
    if (shouldRun)
      _sync(false);
  }

  Connections {
    target: root.shouldRun ? S.DesktopState : null
    function onCapsLockChanged() {
      root._sync(true);
    }
    function onNumLockChanged() {
      root._sync(true);
    }
    function onScrollLockChanged() {
      root._sync(true);
    }
  }

  Component.onCompleted: {
    Logger.i("LockKeysService", "Service started (polling deferred until a consumer registers).");
  }
}
