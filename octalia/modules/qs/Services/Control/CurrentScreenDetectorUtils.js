.pragma library

function findScreenWithBar(Settings, Quickshell) {
  const monitors = Settings.data.bar.monitors || [];
  let primaryCandidate = null;
  let firstWithBar = null;

  for (let i = 0; i < Quickshell.screens.length; i++) {
    const s = Quickshell.screens[i];
    const hasBar = monitors.length === 0 || monitors.includes(s.name);

    if (hasBar) {
      // Check if this is at 0x0 (primary position)
      if (s.x === 0 && s.y === 0) {
        primaryCandidate = s;
      }
        // Track first screen with bar as fallback
        if (!firstWithBar) {
          firstWithBar = s;
        }
      }
    }
    return primaryCandidate || firstWithBar || Quickshell.screens[0];
}

function withCurrentScreen(callback, skipBarCheck, root, Logger, Quickshell, CompositorService, Settings, screenDetectorLoader) {
          if (root.pendingCallback) {
            Logger.w("CurrentScreenDetector", "Another detection is pending, ignoring new call");
            return;
          }

            // Single monitor setup can execute immediately
            if (Quickshell.screens.length === 1) {
              callback(Quickshell.screens[0]);
              return;
            }

              // Try compositor-specific focused monitor detection first
              let screen = CompositorService.getFocusedScreen();

              if (screen) {
                // Apply the bar check if configured (skip for overlay launcher etc.)
                if (!skipBarCheck && !Settings.data.general.allowPanelsOnScreenWithoutBar) {
                  const monitors = Settings.data.bar.monitors || [];
                  const hasBar = monitors.length === 0 || monitors.includes(screen.name);
                  if (!hasBar) {
                    screen = root.findScreenWithBar();
                  }
                }
                Logger.d("CurrentScreenDetector", "Using compositor-detected screen:", screen.name);
                callback(screen);
                return;
              }
              root.detectedScreen = null;
              root.pendingCallback = callback;
              root.pendingSkipBarCheck = !!skipBarCheck;
              screenDetectorLoader.active = true;
}

function onTriggered(root, Logger, Settings, screenDetectorLoader) {
                        var callback, monitors;
                        Logger.d("CurrentScreenDetector", "Screen debounced to:", root.detectedScreen?.name || "null");

                        // Execute pending callback if any
                        if (root.pendingCallback) {
                          if (!root.pendingSkipBarCheck && !Settings.data.general.allowPanelsOnScreenWithoutBar) {
                            // If we explicitly disabled panels on screen without bar, check if bar is configured
                            // for this screen, and fallback to primary screen if necessary
                            monitors = Settings.data.bar.monitors || [];
                            const hasBar = monitors.length === 0 || monitors.includes(root.detectedScreen?.name);
                            if (!hasBar) {
                              root.detectedScreen = root.findScreenWithBar();
                            }
                          }

                          Logger.d("CurrentScreenDetector", "Executing callback on screen:", root.detectedScreen.name);
                          // Store callback locally and clear pendingCallback first to prevent deadlock
                          // if the callback throws an error
                          callback = root.pendingCallback;
                          root.pendingCallback = null;
                          root.pendingSkipBarCheck = false;
                          try {
                            callback(root.detectedScreen);
                          } catch (e) {
                            Logger.e("CurrentScreenDetector", "Callback failed:", e);
                          }
                        }

                        // Clean up
                        screenDetectorLoader.active = false;
}
