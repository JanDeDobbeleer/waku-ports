pragma ComponentBehavior: Bound

import "CurrentScreenDetectorUtils.js" as ScreenUtils

import QtQuick 6.10
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services.Compositor

/**
* Detects which screen the cursor is currently on by creating a temporary
* invisible PanelWindow. Use withCurrentScreen() to get the screen asynchronously.
*
* Usage:
*   CurrentScreenDetector {
*     id: screenDetector
*   }
*
*   function doSomething() {
*     screenDetector.withCurrentScreen(function(screen) {
*       // screen is the ShellScreen where cursor is
*     })
*   }
*/
Item {
  id: root

  // Pending callback to execute once screen is detected
  property var pendingCallback: null
  property bool pendingSkipBarCheck: false

  // Detected screen
  property var detectedScreen: null

  // Signal emitted when screen is detected from the PanelWindow
  signal screenDetected(var detectedScreen)

  onScreenDetected: function (detectedScreen) {
    root.detectedScreen = detectedScreen;
    screenDetectorDebounce.restart();
  }

  /**
  * Find a fallback screen that has a bar configured.
  * Prioritizes the screen at position 0x0 (likely the primary screen).
  */
  function findScreenWithBar(): var {
    return ScreenUtils.findScreenWithBar(Settings, Quickshell);
  }
          /**
          * Execute callback with the screen where the cursor currently is.
          * On single-monitor setups, executes immediately.
          * On multi-monitor setups, briefly opens an invisible window to detect the screen.
          */
          function withCurrentScreen(callback: var, skipBarCheck: var): void {
            ScreenUtils.withCurrentScreen(callback, skipBarCheck, root, Logger, Quickshell, CompositorService, Settings, screenDetectorLoader);
          }
                    Timer {
                      id: screenDetectorDebounce
                      running: false
                      interval: 40
                      onTriggered: ScreenUtils.onTriggered(root, Logger, Settings, screenDetectorLoader)
                    }

                    // Invisible dummy PanelWindow to detect which screen should receive the action
                    Loader {
                      id: screenDetectorLoader
                      active: false

                      sourceComponent: PanelWindow {
                        implicitWidth: 0
                        implicitHeight: 0
                        color: "transparent"
                        WlrLayershell.exclusionMode: ExclusionMode.Ignore
                        WlrLayershell.namespace: "octalia-screen-detector"
                        mask: Region {}

                        onScreenChanged: root.screenDetected(screen)
                      }
                    }
                  }
