pragma Singleton

import "SpectrumUtils.js" as SpectrumUtils

import QtQuick 6.10
import Quickshell

// Stub. The audio visualiser needs octalia-qs's PwAudioSpectrum (PipeWire); waku has no
// equivalent yet, so the bands stay empty and the visualiser shows nothing.
Singleton {
  id: root

  property var _registeredComponents: ({})
  readonly property int _registeredCount: Object.keys(_registeredComponents).length
  property var values: []
  property bool isIdle: true

  function registerComponent(componentId: var): void {
    root._registeredComponents[componentId] = true;
    root._registeredComponents = Object.assign({}, root._registeredComponents);
  }

  function unregisterComponent(componentId: var): void {
    SpectrumUtils.unregister(root._registeredComponents, componentId);
    root._registeredComponents = Object.assign({}, root._registeredComponents);
  }

  function isRegistered(componentId: var): bool {
    return root._registeredComponents[componentId] === true;
  }
}
