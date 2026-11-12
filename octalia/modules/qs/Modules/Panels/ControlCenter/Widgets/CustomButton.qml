pragma ComponentBehavior: Bound

import QtQuick 6.10
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import "./CustomButtonUtils.js" as CustomButtonUtils

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

    function _updatePropertiesFromSettings(): void {
      if (!root.widgetSettings) {
        return;
      }

      root.onClickedCommand = CustomButtonUtils.field(root.widgetSettings, "onClicked") || "";
      root.onRightClickedCommand = CustomButtonUtils.field(root.widgetSettings, "onRightClicked") || "";
      root.onMiddleClickedCommand = CustomButtonUtils.field(root.widgetSettings, "onMiddleClicked") || "";
      root.stateChecksJson = CustomButtonUtils.field(root.widgetSettings, "stateChecksJson") || "[]"; // Populate from widgetSettings
      root._parsedStateChecks = CustomButtonUtils.parseStateChecks(root.stateChecksJson, Logger);
      root.enableOnStateLogic = CustomButtonUtils.field(root.widgetSettings, "enableOnStateLogic") || false;

      root.updateState();
    }

    function onWidgetSettingsChanged(): void {
      if (root.widgetSettings) {
        _updatePropertiesFromSettings();
      }
    }
  }

  Process {
    id: stateCheckProcessExecutor
    running: false
    command: root._currentStateCheckIndex !== -1 && CustomButtonUtils.arrayLength(root._parsedStateChecks) > root._currentStateCheckIndex ? ["cmd", "/c", root._parsedStateChecks[root._currentStateCheckIndex].command] : []
    onExited: function (exitCode) {
      var currentCheckItem = root._parsedStateChecks[root._currentStateCheckIndex];
      var currentCommand = currentCheckItem.command;
      if (exitCode === 0) {
        // Command succeeded, this is the active state
        root._isHot = true;
        root._activeStateIcon = currentCheckItem.icon || CustomButtonUtils.field(root.widgetSettings, "icon") || "heart";
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
      if (root.enableOnStateLogic && CustomButtonUtils.arrayLength(root._parsedStateChecks) > 0) {
        root._currentStateCheckIndex = 0;
        root._checkNextState();
      } else {
        root._isHot = false;
        root._activeStateIcon = CustomButtonUtils.field(root.widgetSettings, "icon") || "heart";
      }
    }
  }

  function _checkNextState(): void {
    var currentCheckItem;
    if (root._currentStateCheckIndex < CustomButtonUtils.arrayLength(root._parsedStateChecks)) {
      currentCheckItem = root._parsedStateChecks[root._currentStateCheckIndex];
      if (currentCheckItem && currentCheckItem.command) {
        stateCheckProcessExecutor.running = true;
      } else {
        _currentStateCheckIndex++;
        _checkNextState();
      }
    } else {
      // All checks failed
      _isHot = false;
      root._activeStateIcon = CustomButtonUtils.field(root.widgetSettings, "icon") || "heart";
    }
  }

  function updateState(): void {
    if (!root.enableOnStateLogic || CustomButtonUtils.arrayLength(root._parsedStateChecks) === 0) {
      _isHot = false;
      root._activeStateIcon = CustomButtonUtils.field(root.widgetSettings, "icon") || "heart";
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
