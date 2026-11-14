.pragma library

function migrate27(adapter, logger, rawJson) {
    logger.i("Settings", "Migrating settings to v27");

    // Check rawJson for old property (adapter doesn't expose removed properties)
    if (rawJson?.ui?.settingsPanelAttachToBar !== undefined) {
      if (rawJson.ui.settingsPanelAttachToBar === true) {
        adapter.ui.settingsPanelMode = "attached";
      } else {
        adapter.ui.settingsPanelMode = "centered";
      }
      logger.i("Settings", "Migrated settingsPanelAttachToBar to settingsPanelMode: " + adapter.ui.settingsPanelMode);
    }

    return true;
}

function migrate28(adapter, logger, rawJson) {
    logger.i("Settings", "Migrating settings to v28");

    // Check bar widgets in all sections
    const sections = ["left", "center", "right"];

    for (const section of sections) {
      if (!rawJson?.bar?.widgets?.[section])
        continue;

      const widgets = rawJson.bar.widgets[section];
      for (let i = 0; i < widgets.length; i++) {
        if (widgets[i].id === "TaskbarGrouped") {
          // Convert TaskbarGrouped to Workspace with showApplications
          const oldWidget = widgets[i];
          adapter.bar.widgets[section][i] = {
            id: "Workspace",
            showApplications: true,
            labelMode: oldWidget.labelMode || "index",
            hideUnoccupied: oldWidget.hideUnoccupied || false,
            showLabelsOnlyWhenOccupied: oldWidget.showLabelsOnlyWhenOccupied ?? true,
            colorizeIcons: oldWidget.colorizeIcons || false
          };
          logger.i("Settings", "Migrated TaskbarGrouped to Workspace in " + section + " section");
        }
      }
    }

    return true;
}

function migrate32(adapter, logger, rawJson) {
    logger.i("Settings", "Migrating settings to v32");

    // Check rawJson for old property (adapter doesn't expose removed properties)
    if (rawJson?.systemMonitor?.enableNvidiaGpu !== undefined) {
      adapter.systemMonitor.enableDgpuMonitoring = rawJson.systemMonitor.enableNvidiaGpu;
      logger.i("Settings", "Migrated systemMonitor.enableNvidiaGpu to enableDgpuMonitoring: " + adapter.systemMonitor.enableDgpuMonitoring);
    }

    return true;
}

function migrate33(adapter, logger, rawJson) {
    logger.i("Settings", "Migrating settings to v33");

    if (rawJson?.wallpaper?.randomEnabled !== undefined) {
      // We'll keep randomEnabled for backward compatibility but set wallpaperChangeMode
      if (rawJson.wallpaper.randomEnabled === true) {
        adapter.wallpaper.wallpaperChangeMode = "random";
        logger.i("Settings", "Migrated wallpaper.randomEnabled=true to wallpaperChangeMode=random");
      } else {
        adapter.wallpaper.wallpaperChangeMode = "random";
        logger.i("Settings", "Set wallpaperChangeMode=random (randomEnabled was false)");
      }
    } else {
      adapter.wallpaper.wallpaperChangeMode = "random";
      logger.i("Settings", "Set default wallpaperChangeMode=random");
    }

    return true;
}

function migrate35(adapter, logger, rawJson) {
    logger.i("Settings", "Migrating settings to v35");

    if (rawJson?.bar?.transparent !== undefined) {
      if (rawJson.bar.transparent === true) {
        adapter.bar.backgroundOpacity = 0;
        adapter.bar.useSeparateOpacity = true;
        logger.i("Settings", "Migrated bar.transparent=true to backgroundOpacity=0, useSeparateOpacity=true");
      }
    }

    return true;
}

function migrate36(adapter, logger, rawJson, Settings, Os) {
    logger.i("Settings", "Migrating settings to v36");

    const usagePath = Settings.cacheDir + "emoji_usage.json";

    if (!usagePath.endsWith("emoji_usage.json")) {
      logger.w("Settings", "Skipping emoji usage cleanup due to unexpected path: " + usagePath);
      return true;
    }

    try {
      // Ensure dir exists then remove the file
      Os.rm(usagePath, false);
      logger.i("Settings", "Cleared legacy emoji usage file at: " + usagePath);
    } catch (e) {
      logger.w("Settings", "Failed to clear emoji usage cache: " + e);
    }

    return true;
}

function migrate37(adapter, logger, rawJson) {
    logger.i("Settings", "Migrating settings to v37 (WiFi → Network)");

    let changed = false;

    function migrateArray(contextName, rawArr, adapterArr, setItem) {
      var key;
      var newObj;
      if (!adapterArr)
        return;
      const len = adapterArr.length;
      for (let i = 0; i < len; i++) {
        // Prefer raw item if present, otherwise use adapter item
        const item = rawArr && rawArr[i] !== undefined ? rawArr[i] : adapterArr[i];

        if (item === undefined || item === null)
          continue;

        // Case 1: simple string entries
        if (typeof item === "string") {
          if (item === "WiFi") {
            setItem(i, "Network");
            changed = true;
            logger.i("Settings", `Migrated ${contextName}[${i}] from WiFi to Network (string entry)`);
          }
          continue;
        }

        // Case 2: object entries with id
        let id = item.id !== undefined ? item.id : (item.widgetId !== undefined ? item.widgetId : undefined);
        if (id === "WiFi") {
          newObj = {};
          for (key in item)
            newObj[key] = item[key];
          if (newObj.id !== undefined)
            newObj.id = "Network";
          if (newObj.widgetId !== undefined && newObj.id === undefined)
            newObj.widgetId = "Network"; // fallback if older schema used widgetId
          setItem(i, newObj);
          changed = true;
          logger.i("Settings", `Migrated ${contextName}[${i}] from WiFi to Network (object entry)`);
        }
      }
    }

    // --- Bar widgets: left/center/right
    const sections = ["left", "center", "right"];
    for (const section of sections) {
      const rawArr = rawJson?.bar?.widgets?.[section];
      const adapterArr = adapter?.bar?.widgets?.[section];
      migrateArray(`bar.widgets.${section}`, rawArr, adapterArr, function (i, v) {
        adapter.bar.widgets[section][i] = v;
      });
    }

    // --- Control Center shortcuts: left/right
    const rawLeft = rawJson?.controlCenter?.shortcuts?.left;
    const adLeft = adapter?.controlCenter?.shortcuts?.left;
    migrateArray("controlCenter.shortcuts.left", rawLeft, adLeft, function (i, v) {
      adapter.controlCenter.shortcuts.left[i] = v;
    });

    const rawRight = rawJson?.controlCenter?.shortcuts?.right;
    const adRight = adapter?.controlCenter?.shortcuts?.right;
    migrateArray("controlCenter.shortcuts.right", rawRight, adRight, function (i, v) {
      adapter.controlCenter.shortcuts.right[i] = v;
    });

    if (!changed) {
      logger.i("Settings", "No WiFi widget IDs found to migrate; leaving settings unchanged");
    }

    return true;
}

function migrate38(adapter, logger, rawJson) {
    logger.i("Migration38", "Migrating bar margins from percentages to integers");

    // Use rawJson to read original values, adapter to write new values (following migration patterns)
    const rawVertical = rawJson?.bar?.marginVertical;
    const rawHorizontal = rawJson?.bar?.marginHorizontal;

    // Only migrate if values exist and are percentages (<= 1.0)
    if (rawVertical !== undefined && typeof rawVertical === 'number' && rawVertical <= 1.0) {
      const marginXL = 18; // Standard value of Style.marginXL
      adapter.bar.marginVertical = Math.round(rawVertical * marginXL);
      logger.d("Migration38", "Converted marginVertical from " + rawVertical + " to " + adapter.bar.marginVertical + "px");
    }

    if (rawHorizontal !== undefined && typeof rawHorizontal === 'number' && rawHorizontal <= 1.0) {
      const marginXL = 18; // Standard value of Style.marginXL
      adapter.bar.marginHorizontal = Math.round(rawHorizontal * marginXL);
      logger.d("Migration38", "Converted marginHorizontal from " + rawHorizontal + " to " + adapter.bar.marginHorizontal + "px");
    }

    return true;
}

function migrate40(adapter, logger, rawJson, templateIds) {
    logger.i("Migration39", "Migrating templates from boolean format to activeTemplates array");

    // Check if old format exists (any boolean template property)
    const oldTemplates = rawJson?.templates;
    if (!oldTemplates) {
      logger.d("Migration39", "No templates section found, skipping migration");
      return true;
    }

    // Check if already migrated (has activeTemplates array)
    if (Array.isArray(oldTemplates.activeTemplates)) {
      logger.d("Migration39", "Already has activeTemplates array, skipping migration");
      return true;
    }

    // Build the new activeTemplates array from old boolean values
    const activeTemplates = [];
    for (const templateId of templateIds) {
      if (oldTemplates[templateId] === true) {
        activeTemplates.push({
                               "id": templateId,
                               "enabled": true
                             });
        logger.d("Migration40", "Migrated enabled template: " + templateId);
      }
    }

    // Write the new format
    adapter.templates.activeTemplates = activeTemplates;
    logger.i("Migration40", "Migrated " + activeTemplates.length + " templates to new array format");

    return true;
}

function migrate42(adapter, logger, rawJson) {
    logger.i("Migration42", "Migrating randomEnabled to automationEnabled");

    const wallpaper = rawJson?.wallpaper;
    if (!wallpaper) {
      logger.d("Migration42", "No wallpaper section found, skipping migration");
      return true;
    }

    // Check if already migrated (has automationEnabled)
    if (wallpaper.automationEnabled !== undefined) {
      logger.d("Migration42", "Already has automationEnabled, skipping migration");
      return true;
    }

    // Migrate randomEnabled to automationEnabled
    const oldValue = wallpaper.randomEnabled ?? false;
    adapter.wallpaper.automationEnabled = oldValue;
    logger.i("Migration42", "Migrated randomEnabled=" + oldValue + " to automationEnabled=" + oldValue);

    return true;
}

function migrate43(adapter, logger, rawJson) {
    logger.i("Migration43", "Migrating recursiveSearch to viewMode");

    const wallpaper = rawJson?.wallpaper;
    if (!wallpaper) {
      logger.d("Migration43", "No wallpaper section found, skipping migration");
      return true;
    }

    // Check if already migrated (has viewMode)
    if (wallpaper.viewMode !== undefined) {
      logger.d("Migration43", "Already has viewMode, skipping migration");
      return true;
    }

    // Migrate recursiveSearch to viewMode
    const oldValue = wallpaper.recursiveSearch ?? false;
    const newValue = oldValue ? "recursive" : "single";
    adapter.wallpaper.viewMode = newValue;
    logger.i("Migration43", "Migrated recursiveSearch=" + oldValue + " to viewMode=" + newValue);

    return true;
}

function migrate44(adapter, logger, rawJson, Settings, Os, Quickshell) {
    logger.i("Migration44", "Updating PAM pam/password.conf");

    const configDir = Settings.configDir;
    const pamConfigDir = configDir + "pam";
    const pamConfigFile = pamConfigDir + "/password.conf";
    const pamConfigDirEsc = pamConfigDir.replace(/'/g, "'\\''");
    const pamConfigFileEsc = pamConfigFile.replace(/'/g, "'\\''");

    // Ensure directory exists
    Os.mkdirp(pamConfigDir);

    // Generate the PAM config file content (updated version)
    var configContent = "auth sufficient pam_fprintd.so timeout=-1\n";
    configContent += "auth sufficient /run/current-system/sw/lib/security/pam_fprintd.so timeout=-1 # for NixOS\n";
    configContent += "auth required pam_unix.so\n";

    // Write the config file using heredoc
    var script = `cat > '${pamConfigFileEsc}' << 'EOF'\n`;
    script += configContent;
    script += "EOF\n";
    Quickshell.execDetached(["sh", "-c", script]);

    logger.d("Migration44", "PAM config file updated at:", pamConfigFile);

    return true;
}

function migrate45(adapter, logger, rawJson) {
    logger.i("Migration45", "Migrating bar settings...");

    if (rawJson?.bar?.floating) {
      adapter.bar.barType = "floating";
    } else {
      adapter.bar.barType = "simple";
    }

    return true;
}

function migrate46(adapter, logger, rawJson, Settings, Quickshell) {
    logger.i("Migration46", "Removing legacy PAM configuration file");

    const configDir = Settings.configDir;
    const pamConfigDir = configDir + "pam";
    // Remove the entire pam directory if it exists
    const script = `rm -rf '${pamConfigDir}'`;
    Quickshell.execDetached(["sh", "-c", script]);

    logger.d("Migration46", "Cleaned up legacy PAM config");

    return true;
}

function migrate47(adapter, logger, rawJson, Settings, Os) {
    logger.i("Migration47", "Removing network_stats.json cache");

    const networkStatsFile = Settings.cacheDir + "network_stats.json";
    Os.rm(networkStatsFile);

    logger.d("Migration47", "Removed network_stats.json");

    return true;
}

function migrate48(adapter, logger, rawJson) {
    logger.i("Settings", "Migrating settings to v48");

    if (rawJson?.notifications?.batteryWarningThreshold !== undefined) {
      adapter.systemMonitor.batteryWarningThreshold = rawJson.notifications.batteryWarningThreshold;
      logger.i("Settings", "Migrated notifications.batteryWarningThreshold to systemMonitor: " + adapter.systemMonitor.batteryWarningThreshold);
    }

    if (rawJson?.notifications?.batteryCriticalThreshold !== undefined) {
      adapter.systemMonitor.batteryCriticalThreshold = rawJson.notifications.batteryCriticalThreshold;
      logger.i("Settings", "Migrated notifications.batteryCriticalThreshold to systemMonitor: " + adapter.systemMonitor.batteryCriticalThreshold);
    }

    return true;
}

function migrate49(adapter, logger, rawJson, Settings, Os) {
    logger.i("Settings", "Migrating settings to v49");

    Os.rm(Settings.cacheDir + "launcher_app_usage.json");
    logger.i("Settings", "Removed old launcher_app_usage.json");

    return true;
}

function migrate50(adapter, logger, rawJson) {
    logger.i("Settings", "Migrating settings to v50");

    const keybinds = rawJson?.general?.keybinds;
    if (!keybinds)
      return true;

    const keys = ["keyUp", "keyDown", "keyLeft", "keyRight", "keyEnter", "keyEscape"];
    for (const key of keys) {
      if (keybinds[key] !== undefined && typeof keybinds[key] === "string") {
        adapter.general.keybinds[key] = [keybinds[key]];
        logger.i("Settings", "Migrated keybinds." + key + " from string to array: [" + keybinds[key] + "]");
      }
    }

    return true;
}

function migrate53(adapter, logger, rawJson) {
    logger.i("Settings", "Migrating settings to v53");

    const powerOptions = rawJson?.sessionMenu?.powerOptions;
    if (!powerOptions || !Array.isArray(powerOptions))
      return true;

    // Check if any power option has a keybind defined
    const hasAnyKeybind = powerOptions.some(opt => opt.keybind && opt.keybind !== "");
    if (hasAnyKeybind)
      return true;

    // No keybinds defined — apply defaults matching the action order
    const defaultKeybinds = {
      "lock": "1",
      "suspend": "2",
      "hibernate": "3",
      "reboot": "4",
      "logout": "5",
      "shutdown": "6"
    };

    const updatedOptions = Array.from(adapter.sessionMenu.powerOptions);
    for (let i = 0; i < powerOptions.length; i++) {
      const action = powerOptions[i].action;
      if (defaultKeybinds[action] && updatedOptions[i]) {
        updatedOptions[i] = Object.assign({}, updatedOptions[i], { keybind: defaultKeybinds[action] });
        logger.i("Settings", "Set keybind '" + defaultKeybinds[action] + "' for session menu action: " + action);
      }
    }
    adapter.sessionMenu.powerOptions = updatedOptions;

    return true;
}

function migrate54(adapter, logger, rawJson) {
    var updated;
    logger.i("Settings", "Migrating settings to v54");

    const keybinds = rawJson?.general?.keybinds;
    if (!keybinds)
      return true;

    const keyEnter = keybinds.keyEnter;
    if (!keyEnter || !Array.isArray(keyEnter))
      return true;

    // Only add "Enter" if the first entry is "Return" and "Enter" isn't already present
    if (keyEnter[0] === "Return" && !keyEnter.includes("Enter")) {
      updated = Array.from(keyEnter);
      updated.splice(1, 0, "Enter");
      adapter.general.keybinds.keyEnter = updated;
      logger.i("Settings", "Added 'Enter' (numpad) as second default keybind for keyEnter");
    }

    return true;
}

function migrate55(adapter, logger, rawJson) {
    logger.i("Settings", "Migrating settings to v55");

    // Check if the old setting exists
    if (rawJson.controlCenter && rawJson.controlCenter.openAtMouseOnBarRightClick !== undefined) {
      if (!rawJson.bar)
        rawJson.bar = {};

      rawJson.bar.rightClickFollowMouse = rawJson.controlCenter.openAtMouseOnBarRightClick;
      delete rawJson.controlCenter.openAtMouseOnBarRightClick;

      logger.i("Settings", "Successfully moved openAtMouseOnBarRightClick to bar.rightClickFollowMouse");
    }

    return true;
}

function migrate56(adapter, logger, rawJson, Settings, Quickshell) {
    logger.i("Settings", "Migrating settings to v56 (Color Scheme Migration)");

    const scriptPath = Quickshell.shellDir + "/Scripts/python/src/theming/migrate-colorschemes.py";
    const configDir = Settings.configDir;

    logger.i("Settings", `Running color scheme migration script: ${scriptPath} with configDir: ${configDir}`);

    // Run the migration script detached
    Quickshell.execDetached(["python3", scriptPath, configDir]);

    return true;
}

function migrate57(adapter, logger, rawJson) {
    logger.i("Settings", "Migrating settings to v57 (cavaFrameRate -> spectrumFrameRate)");

    if (rawJson && rawJson.audio && rawJson.audio.cavaFrameRate !== undefined) {
      adapter.audio.spectrumFrameRate = rawJson.audio.cavaFrameRate;
      logger.i("Settings", "Migrated cavaFrameRate:", rawJson.audio.cavaFrameRate, "-> spectrumFrameRate");
    }

    return true;
}

function migrate58(adapter, logger, rawJson) {
    logger.i("Settings", "Migrating settings to v58 (dock.dockType: static -> attached)");

    if (rawJson && rawJson.dock && rawJson.dock.dockType === "static") {
      adapter.dock.dockType = "attached";
      logger.i("Settings", "Migrated dock.dockType: static -> attached");
    }

    return true;
}

function migrate59(adapter, logger, rawJson) {
    var newValue;
    var oldValue;
    logger.i("Settings", "Migrating settings to v59 (wallpaper.transitionType: string -> array)");

    if (rawJson && rawJson.wallpaper && typeof rawJson.wallpaper.transitionType === "string") {
      oldValue = rawJson.wallpaper.transitionType;


      if (oldValue === "random") {
        newValue = ["fade", "disc", "stripes", "wipe", "pixelate", "honeycomb"];
      } else if (oldValue === "none") {
        newValue = [];
      } else {
        newValue = [oldValue];
      }

      adapter.wallpaper.transitionType = newValue;
      logger.i("Settings", "Migrated wallpaper.transitionType:", oldValue, "->", JSON.stringify(newValue));
    }

    return true;
}
