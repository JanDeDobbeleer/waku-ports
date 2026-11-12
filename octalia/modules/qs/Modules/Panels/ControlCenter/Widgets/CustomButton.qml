pragma ComponentBehavior: Bound

import QtQuick 6.10
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets

Item {
  id: root

  property string widgetId: "CustomButton"
  property var widgetSettings: null

  property string onClickedCommand: ""
  property string onRightClickedCommand: ""
  property string onMiddleClickedCommand: ""
  property string stateChecksJson: "[]" // Store state checks as JSON string

  property bool enableOnStateLogic: false

  property string _currentIcon: "heart" // Default icon
  property bool _isHot: false
  property var _parsedStateChecks: [] // Local array for parsed state checks

  property int _currentStateCheckIndex: -1
  property string _activeStateIcon: ""

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Connections {
    target: root

    function _updatePropertiesFromSettings() {
      if (!root.widgetSettings) {
        return;
      }

      root.onClickedCommand = root.widgetSettings.onClicked || "";
      root.onRightClickedCommand = root.widgetSettings.onRightClicked || "";
      root.onMiddleClickedCommand = root.widgetSettings.onMiddleClicked || "";
      root.stateChecksJson = root.widgetSettings.stateChecksJson || "[]"; // Populate from widgetSettings
      try {
        root._parsedStateChecks = JSON.parse(root.stateChecksJson);
      } catch (e) {
        Logger.e("CustomButton", "Failed to parse stateChecksJson:", e.message);
        root._parsedStateChecks = [];
      }
      root.enableOnStateLogic = root.widgetSettings.enableOnStateLogic || false;

      root.updateState();
    }

    function onWidgetSettingsChanged() {
      if (root.widgetSettings) {
        _updatePropertiesFromSettings();
      }
    }
  }

  Process {
    id: stateCheckProcessExecutor
    running: false
    command: root._currentStateCheckIndex !== -1 && root._parsedStateChecks.length > root._currentStateCheckIndex ? ["cmd", "/c", root._parsedStateChecks[root._currentStateCheckIndex].command] : []
    onExited: function (exitCode, stdout, stderr) {
      var currentCheckItem = root._parsedStateChecks[root._currentStateCheckIndex];
      var currentCommand = currentCheckItem.command;
      if (exitCode === 0) {
        // Command succeeded, this is the active state
        root._isHot = true;
        root._activeStateIcon = currentCheckItem.icon || root.widgetSettings.icon || "heart";
      } else {
        // Command failed, try next one
        root._currentStateCheckIndex++;
        root._checkNextState();
      }
    }
  }

  Timer {
    id: stateUpdateTimer
    interval: 200
    running: false
    repeat: false
    onTriggered: {
      if (root.enableOnStateLogic && root._parsedStateChecks.length > 0) {
        root._currentStateCheckIndex = 0;
        root._checkNextState();
      } else {
        root._isHot = false;
        root._activeStateIcon = root.widgetSettings.icon || "heart";
      }
    }
  }

  function _checkNextState() {
    var currentCheckItem;
    if (_currentStateCheckIndex < _parsedStateChecks.length) {
      currentCheckItem = _parsedStateChecks[_currentStateCheckIndex];
      if (currentCheckItem && currentCheckItem.command) {
        stateCheckProcessExecutor.running = true;
      } else {
        _currentStateCheckIndex++;
        _checkNextState();
      }
    } else {
      // All checks failed
      _isHot = false;
      _activeStateIcon = widgetSettings.icon || "heart";
    }
  }

  function updateState() {
    if (!enableOnStateLogic || _parsedStateChecks.length === 0) {
      _isHot = false;
      _activeStateIcon = widgetSettings.icon || "heart";
      return;
    }
    stateUpdateTimer.restart();
  }

  NIconButtonHot {
    id: button
    icon: root._activeStateIcon
    hot: root._isHot
    onClicked: {
      if (root.onClickedCommand) {
        Quickshell.execDetached(["cmd", "/c", root.onClickedCommand]);
        root.updateState();
      }
    }
    onRightClicked: {
      if (root.onRightClickedCommand) {
        Quickshell.execDetached(["cmd", "/c", root.onRightClickedCommand]);
        root.updateState();
      }
    }
    onMiddleClicked: {
      if (root.onMiddleClickedCommand) {
        Quickshell.execDetached(["cmd", "/c", root.onMiddleClickedCommand]);
        root.updateState();
      }
    }
  }
}
