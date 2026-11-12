.pragma library

function getMonitorsText(separator, screens, scales) {
  const sep = separator || "\n";
  const lines = [];
  for (let i = 0; i < screens.length; i++) {
    const screen = screens[i];
    const name = screen.name || "Unknown";
    const scaleData = scales[name];
    const scaleValue = (typeof scaleData === "object" && scaleData !== null) ? (scaleData.scale || 1.0) : (scaleData || 1.0);
    lines.push(name + ": " + screen.width + "x" + screen.height + " @ " + scaleValue + "x");
  }
  return lines.join(sep);
}

function monitorText(screen, scales) {
  const name = screen ? (screen.name || "Unknown") : "Unknown";
  const scaleData = scales[name];
  const scaleValue = (typeof scaleData === "object" && scaleData !== null) ? (scaleData.scale || 1.0) : (scaleData || 1.0);
  return name + ": " + (screen ? (screen.width || 0) : 0) + "x" + (screen ? (screen.height || 0) : 0) + " @ " + scaleValue + "x";
}

function getChangelogScreen(openedPanel, settingsWindow, panelService) {
  return (openedPanel && openedPanel.screen) || (settingsWindow && settingsWindow.screen) || panelService.findScreenForPanels();
}

function handleGitExit(exitCode, output, owner) {
  Logger.d("VersionSubTab", "gitProcess - Process exited with code:", exitCode);
  if (exitCode === 0) {
    const gitOutput = output.text.trim();
    Logger.d("VersionSubTab", "gitProcess - gitOutput:", gitOutput);
    if (gitOutput) {
      owner.commitInfo = gitOutput;
      Logger.d("VersionSubTab", "gitProcess - Set commitInfo to:", owner.commitInfo);
    }
  } else {
    Logger.d("VersionSubTab", "gitProcess - Git command failed. Exit code:", exitCode);
  }
}
