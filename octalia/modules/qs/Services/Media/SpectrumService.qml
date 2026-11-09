pragma Singleton

import QtQuick 6.10
import Quickshell
import qs.compat

// Stub. The audio visualiser needs octalia-qs's PwAudioSpectrum (PipeWire); waku has no
// equivalent yet, so the bands stay empty and the visualiser shows nothing.
Singleton {
  id: root

  property var _registeredComponents: ({})
  readonly property int _registeredCount: Object.keys(_registeredComponents).length
  property var values: []
  property bool isIdle: true

  function registerComponent(componentId) {
    root._registeredComponents[componentId] = true;
    root._registeredComponents = Object.assign({}, root._registeredComponents);
  }

  function unregisterComponent(componentId) {
    delete root._registeredComponents[componentId];
    root._registeredComponents = Object.assign({}, root._registeredComponents);
  }

  function isRegistered(componentId) {
    return root._registeredComponents[componentId] === true;
  }
}
