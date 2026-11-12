.pragma library

function length(value) { return value.length; }

function collectSchemes(root, bundledSchemes, downloadedSchemes, Settings, Logger) {
    var basename;

    var files = [];
    const sources = [[bundledSchemes, root.schemesDirectory], [downloadedSchemes, root.downloadedSchemesDirectory]];
    for (const [model, dir] of sources) {
      // A folder that does not exist yet (Os.mkdirp is asynchronous) lists some other directory, so
      // keep only the entries that really sit in this one.
      const prefix = dir.toLowerCase() + "/";
      for (let k = 0; k < model.count; k++) {
        const name = model.get(k, "fileName");
        const path = String(model.get(k, "filePath")).replace(/\\/g, "/");
        if (path.toLowerCase() !== prefix + name.toLowerCase())
          continue;
        files.push(dir + "/" + name + "/" + name + ".json");
      }
    }
    files.sort(function (a, b) {
      return root.getBasename(a).toLowerCase().localeCompare(root.getBasename(b).toLowerCase());
    });
    root.schemes = files;
    root.scanning = false;
    Logger.d("ColorScheme", "Listed", root.schemes.length, "schemes");
    // Normalize stored scheme to basename and re-apply if necessary
    var stored = Settings.data.colorSchemes.predefinedScheme;
    if (stored) {
      basename = root.getBasename(stored);
      if (basename !== stored) {
        Settings.data.colorSchemes.predefinedScheme = basename;
      }
      if (!Settings.data.colorSchemes.useWallpaperColors) {
        root.applyScheme(basename);
      }
    }
}

function loadScheme(root, schemeReader, Settings, AppThemeService, Logger) {
      var data, variant;
      try {
        data = JSON.parse(schemeReader.text());
        variant = data;
        // If scheme provides dark/light variants, pick based on settings
        if (data && (data.dark || data.light)) {
          if (Settings.data.colorSchemes.darkMode) {
            variant = data.dark || data.light;
          } else {
            variant = data.light || data.dark;
          }
        }
        root.writeColorsToDisk(variant);
        root.lastPredefinedSchemeData = data;
        Logger.i("ColorScheme", "Applying color scheme:", root.getBasename(schemeReader.path));

        // Generate templates for predefined color schemes
        if (root.hasEnabledTemplates() || Settings.data.templates.enableUserTheming) {
          AppThemeService.generateFromPredefinedScheme(data);
        }
      } catch (e) {
        Logger.e("ColorScheme", "Failed to parse scheme JSON:", schemeReader.path, e);
      }
}

function hasEnabledTemplates(activeTemplates) {
    if (!activeTemplates || activeTemplates.length === 0) {
      return false;
    }
    for (let i = 0; i < activeTemplates.length; i++) {
      if (activeTemplates[i].enabled) {
        return true;
      }
    }
    return false;
}

function writeColorsToDisk(obj, out, colorsWriter, root) {
    function pick(o, a, b, fallback) {
      return (o && (o[a] || o[b])) || fallback;
    }
    out.mPrimary = pick(obj, "mPrimary", "primary", out.mPrimary);
    out.mOnPrimary = pick(obj, "mOnPrimary", "onPrimary", out.mOnPrimary);
    out.mSecondary = pick(obj, "mSecondary", "secondary", out.mSecondary);
    out.mOnSecondary = pick(obj, "mOnSecondary", "onSecondary", out.mOnSecondary);
    out.mTertiary = pick(obj, "mTertiary", "tertiary", out.mTertiary);
    out.mOnTertiary = pick(obj, "mOnTertiary", "onTertiary", out.mOnTertiary);
    out.mError = pick(obj, "mError", "error", out.mError);
    out.mOnError = pick(obj, "mOnError", "onError", out.mOnError);
    out.mSurface = pick(obj, "mSurface", "surface", out.mSurface);
    out.mOnSurface = pick(obj, "mOnSurface", "onSurface", out.mOnSurface);
    out.mSurfaceVariant = pick(obj, "mSurfaceVariant", "surfaceVariant", out.mSurfaceVariant);
    out.mOnSurfaceVariant = pick(obj, "mOnSurfaceVariant", "onSurfaceVariant", out.mOnSurfaceVariant);
    out.mOutline = pick(obj, "mOutline", "outline", out.mOutline);
    out.mShadow = pick(obj, "mShadow", "shadow", out.mShadow);
    out.mHover = pick(obj, "mHover", "hover", out.mHover);
    out.mOnHover = pick(obj, "mOnHover", "onHover", out.mOnHover);

    // Force a rewrite by updating the path
    colorsWriter.path = "";
    colorsWriter.path = root.colorsJsonFilePath;
    colorsWriter.writeAdapter();
}
