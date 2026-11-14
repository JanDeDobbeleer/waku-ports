.pragma library

function executeWallpaperHook(wallpaperPath, screenName, Settings, Quickshell, Logger) {
    if (!Settings.data.hooks?.enabled) {
      return;
    }

    const script = Settings.data.hooks?.wallpaperChange;
    if (!script || script === "") {
      return;
    }

    try {
      const theme = Settings.data.colorSchemes.darkMode ? "dark" : "light";
      let command = script.replace(/\$1/g, wallpaperPath);
      command = command.replace(/\$2/g, screenName || "");
      command = command.replace(/\$3/g, theme);
      Quickshell.execDetached(["cmd", "/c", command]);
      Logger.d("HooksService", `Executed wallpaper hook: ${command}`);
    } catch (e) {
      Logger.e("HooksService", `Failed to execute wallpaper hook: ${e}`);
    }
}

function executeDarkModeHook(isDarkMode, Settings, Quickshell, Logger) {
    if (!Settings.data.hooks?.enabled) {
      return;
    }

    const script = Settings.data.hooks?.darkModeChange;
    if (!script || script === "") {
      return;
    }

    try {
      const command = script.replace(/\$1/g, isDarkMode ? "true" : "false");
      Quickshell.execDetached(["cmd", "/c", command]);
      Logger.d("HooksService", `Executed dark mode hook: ${command}`);
    } catch (e) {
      Logger.e("HooksService", `Failed to execute dark mode hook: ${e}`);
    }
}

function executeLockHook(Settings, Quickshell, Logger) {
    if (!Settings.data.hooks?.enabled) {
      return;
    }

    const script = Settings.data.hooks?.screenLock;
    if (!script || script === "") {
      return;
    }

    try {
      // Pass "lock" as $1 via shell arguments so the script receives it
      Quickshell.execDetached(["cmd", "/c", script, "lock-hook", "lock"]);
      Logger.d("HooksService", `Executed screen lock hook: ${script}`);
    } catch (e) {
      Logger.e("HooksService", `Failed to execute screen lock hook: ${e}`);
    }
}

function executeUnlockHook(Settings, Quickshell, Logger) {
    if (!Settings.data.hooks?.enabled) {
      return;
    }

    const script = Settings.data.hooks?.screenUnlock;
    if (!script || script === "") {
      return;
    }

    try {
      // Pass "unlock" as $1 via shell arguments so the script receives it
      Quickshell.execDetached(["cmd", "/c", script, "unlock-hook", "unlock"]);
      Logger.d("HooksService", `Executed screen unlock hook: ${script}`);
    } catch (e) {
      Logger.e("HooksService", `Failed to execute screen unlock hook: ${e}`);
    }
}

function executePerformanceModeEnabledHook(Settings, Quickshell, Logger) {
    if (!Settings.data.hooks?.enabled) {
      return;
    }

    const script = Settings.data.hooks?.performanceModeEnabled;
    if (!script || script === "") {
      return;
    }

    try {
      Quickshell.execDetached(["cmd", "/c", script]);
    } catch (e) {
      Logger.e("HooksService", `Failed to execute performance mode enabled hook: ${e}`);
    }
}

function executePerformanceModeDisabledHook(Settings, Quickshell, Logger) {
    if (!Settings.data.hooks?.enabled) {
      return;
    }

    const script = Settings.data.hooks?.performanceModeDisabled;
    if (!script || script === "") {
      return;
    }

    try {
      Quickshell.execDetached(["cmd", "/c", script]);
    } catch (e) {
      Logger.e("HooksService", `Failed to execute performance mode disabled hook: ${e}`);
    }
}

function executeColorGenerationHook(Settings, Quickshell, Logger) {
    if (!Settings.data.hooks?.enabled) {
      return;
    }

    const script = Settings.data.hooks?.colorGeneration;
    if (!script || script === "") {
      return;
    }

    try {
      const theme = Settings.data.colorSchemes.darkMode ? "dark" : "light";
      const command = script.replace(/\$1/g, theme);
      Quickshell.execDetached(["cmd", "/c", command]);
      Logger.d("HooksService", `Executed color generation hook: ${command}`);
    } catch (e) {
      Logger.e("HooksService", `Failed to execute color generation hook: ${e}`);
    }
}

function executeStartupHook(Settings, Quickshell, Logger) {
    if (!Settings.data.hooks?.enabled) {
      return;
    }

    const script = Settings.data.hooks?.startup;
    if (!script || script === "") {
      return;
    }

    try {
      Quickshell.execDetached(["cmd", "/c", script]);
      Logger.d("HooksService", `Executed startup hook: ${script}`);
    } catch (e) {
      Logger.e("HooksService", `Failed to execute startup hook: ${e}`);
    }
}

function executeSessionHook(root, Settings, Logger, action, callback) {
    if (!Settings.data.hooks?.enabled) {
      callback();

      return;
    }

    const script = Settings.data.hooks?.session;
    if (!script) {
      callback();

      return;
    }

    Logger.i("HooksService", `Executing session hook for ${action}`);
    root.runPowerHook(`${script} ${action}`, callback);
}

function executePendingWallpaperHook(root, hook) {
  root.executeWallpaperHook(hook.path, hook.screenName);
}

function lockScreenActive(lockScreen) {
  return lockScreen.active;
}

function call(callback) {
  callback();
}
