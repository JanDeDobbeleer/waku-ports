.pragma library

function completeSetup(panel, root, closeTimer, settings, wallpaperService, updateService, telemetryService, logger) {
  if (panel.isCompleting) {
    logger.w("SetupWizard", "completeSetup() called while already completing, ignoring");
    return;
  }
  try {
    logger.i("SetupWizard", root.telemetryOnlyMode ? "Completing telemetry wizard" : "Completing setup with selected options");
    panel.isCompleting = true;
    if (!root.telemetryOnlyMode) {
      if (wallpaperService && wallpaperService.refreshWallpapersList) {
        if (panel.selectedWallpaperDirectory !== settings.data.wallpaper.directory) {
          settings.data.wallpaper.directory = panel.selectedWallpaperDirectory;
          wallpaperService.refreshWallpapersList();
        }
        if (panel.selectedWallpaper !== "")
          wallpaperService.changeWallpaper(panel.selectedWallpaper, undefined);
      }
      settings.data.general.scaleRatio = panel.selectedScaleRatio;
      settings.data.bar.position = panel.selectedBarPosition;
      updateService.markChangelogSeen(updateService.currentVersion);
    }
    telemetryService.init();
    settings.saveImmediate();
    logger.i("SetupWizard", "Setup completed successfully, waiting for settings save confirmation");
    if (root.telemetryOnlyMode)
      root.telemetryWizardCompleted();
    closeTimer.start();
  } catch (error) {
    logger.e("SetupWizard", "Error completing setup:", error);
    panel.isCompleting = false;
  }
}
