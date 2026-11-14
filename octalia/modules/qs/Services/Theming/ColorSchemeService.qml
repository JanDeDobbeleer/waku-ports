pragma Singleton
import "ColorSchemeServiceUtils.js" as ColorSchemeUtils

import Qt.labs.folderlistmodel

import QtQuick 6.10
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.Theming
import qs.Services.UI
import qs.compat

Singleton {
  id: root

  property var schemes: []
  property bool scanning: false
  property string schemesDirectory: String(Quickshell.shellDir).replace(/\\/g, "/") + "/Assets/ColorScheme"
  property string downloadedSchemesDirectory: String(Settings.configDir).replace(/\\/g, "/") + "colorschemes"
  property string colorsJsonFilePath: Settings.configDir + "colors.json"
  // Last successfully parsed predefined scheme JSON (full object). Used to refresh app templates
  // on wallpaper changes without re-running applyScheme (avoids rewriting colors.json when unchanged).
  property var lastPredefinedSchemeData: null

  // prefer-light/prefer-dark only; GTK template post_hook still runs full gtk-refresh.
  function pushSystemColorScheme() {
    if (!Settings.data.colorSchemes.syncGsettings)
      return;
    if (TemplateProcessor.isTemplateEnabled("gtk"))
      return;
  }

  Connections {
    target: Settings.data.colorSchemes
    function onDarkModeChanged() {
      Logger.d("ColorScheme", "Detected dark mode change");
      if (!Settings.data.colorSchemes.useWallpaperColors && Settings.data.colorSchemes.predefinedScheme) {
        // Re-apply current scheme to pick the right variant
        root.applyScheme(Settings.data.colorSchemes.predefinedScheme);
      }
      root.pushSystemColorScheme();
      // Toast: dark/light mode switched
      const enabled = !!Settings.data.colorSchemes.darkMode;
      const label = enabled ? I18n.tr("tooltips.switch-to-dark-mode") : I18n.tr("tooltips.switch-to-light-mode");
      const description = I18n.tr("common.enabled");
      ToastService.showNotice(label, description, "dark-mode");
    }
  }

  // --------------------------------
  function init() {
    // does nothing but ensure the singleton is created
    // do not remove
    Logger.i("ColorScheme", "Service started");
    loadColorSchemes();
  }

  function loadColorSchemes() {
    Logger.d("ColorScheme", "Load colorScheme");
    scanning = true;
    schemes = [];
    // Use find command to locate all scheme.json files in both directories
    // First ensure the downloaded schemes directory exists
    Os.mkdirp(downloadedSchemesDirectory);
    // Find in both preinstalled and downloaded directories
    collectSchemes();
  }

  function getBasename(path: var): string {
    if (!path)
      return "";
    var chunks = path.split("/");
    // Get the filename without extension
    var filename = chunks[chunks.length - 1];
    var schemeName = filename.replace(".json", "");
    // Convert back to display names for special cases
    if (schemeName === "Octalia-default") {
      return "Octalia (default)";
    } else if (schemeName === "Octalia-legacy") {
      return "Octalia (legacy)";
    } else if (schemeName === "Tokyo-Night") {
      return "Tokyo Night";
    } else if (schemeName === "Rosepine") {
      return "Rose Pine";
    }
    return schemeName;
  }

  function resolveSchemePath(nameOrPath: var): var {
    var i;
    if (!nameOrPath)
      return "";
    if (nameOrPath.indexOf("/") !== -1) {
      return nameOrPath;
    }
    // Handle special cases for Octalia schemes
    var schemeName = nameOrPath.replace(".json", "");
    if (schemeName === "Octalia (default)") {
      schemeName = "Octalia-default";
    } else if (schemeName === "Octalia (legacy)") {
      schemeName = "Octalia-legacy";
    } else if (schemeName === "Tokyo Night") {
      schemeName = "Tokyo-Night";
    } else if (schemeName === "Rose Pine") {
      schemeName = "Rosepine";
    }
    // Check preinstalled directory first, then downloaded directory
    var preinstalledPath = schemesDirectory + "/" + schemeName + "/" + schemeName + ".json";
    var downloadedPath = downloadedSchemesDirectory + "/" + schemeName + "/" + schemeName + ".json";
    // Try to find the scheme in the loaded schemes list to determine which directory it's in
    for (i = 0; i < ColorSchemeUtils.length(schemes); i++) {
      if (schemes[i].indexOf("/" + schemeName + "/") !== -1 || schemes[i].indexOf("/" + schemeName + ".json") !== -1) {
        return schemes[i];
      }
    }
    // Fallback: prefer preinstalled, then downloaded
    return preinstalledPath;
  }

  function applyScheme(nameOrPath: var): void {
    // Force reload by bouncing the path
    var filePath = resolveSchemePath(nameOrPath);
    schemeReader.path = "";
    schemeReader.path = filePath;
  }

  function setPredefinedScheme(schemeName: var): void {
    var i;
    Logger.i("ColorScheme", "Attempting to set predefined scheme to:", schemeName);

    var resolvedPath = resolveSchemePath(schemeName);
    var basename = getBasename(schemeName);

    // Check if the scheme actually exists in the loaded schemes list
    var schemeExists = false;
    for (i = 0; i < ColorSchemeUtils.length(schemes); i++) {
      if (getBasename(schemes[i]) === basename) {
        schemeExists = true;
        break;
      }
    }

    if (schemeExists) {
      Settings.data.colorSchemes.predefinedScheme = basename;
      applyScheme(schemeName);
      ToastService.showNotice(I18n.tr("panels.color-scheme.title"), basename, "settings-color-scheme");
    } else {
      Logger.e("ColorScheme", "Scheme not found:", schemeName);
      ToastService.showError(I18n.tr("panels.color-scheme.title"), `'${basename}' ` + I18n.tr("common.not-found"));
    }
  }

  // The scheme folders (<dir>/<Name>/<Name>.json), listed by Qt instead of `find`. Both models watch
  // their folder, so a downloaded scheme shows up without another scan.
  FolderListModel {
    id: bundledSchemes
    folder: "file:///" + root.schemesDirectory
    showFiles: false
    showDirs: true
    showDotAndDotDot: false
    onStatusChanged: root.collectSchemes()
    onCountChanged: root.collectSchemes()
  }

  FolderListModel {
    id: downloadedSchemes
    folder: "file:///" + root.downloadedSchemesDirectory
    showFiles: false
    showDirs: true
    showDotAndDotDot: false
    onStatusChanged: root.collectSchemes()
    onCountChanged: root.collectSchemes()
  }

  function collectSchemes(): void {
    if (!scanning || bundledSchemes.status !== FolderListModel.Ready || downloadedSchemes.status === FolderListModel.Loading)
      return;
    ColorSchemeUtils.collectSchemes(root, bundledSchemes, downloadedSchemes, Settings, Logger);
  }
  // Internal loader to read a scheme file
  FileView {
    id: schemeReader
    onLoaded: {
      ColorSchemeUtils.loadScheme(root, schemeReader, Settings, AppThemeService, Logger);
    }
  }

  // Check if any templates are enabled
  function hasEnabledTemplates(): bool {
    return ColorSchemeUtils.hasEnabledTemplates(Settings.data.templates.activeTemplates);
  }

  // Writer to colors.json using a JsonAdapter for safety
  FileView {
    id: colorsWriter
    path: root.colorsJsonFilePath
    printErrors: false
    onSaved:

    // Logger.i("ColorScheme", "Colors saved")
    {}
    JsonAdapter {
      id: out
      property color mPrimary: "#000000"
      property color mOnPrimary: "#000000"
      property color mSecondary: "#000000"
      property color mOnSecondary: "#000000"
      property color mTertiary: "#000000"
      property color mOnTertiary: "#000000"
      property color mError: "#000000"
      property color mOnError: "#000000"
      property color mSurface: "#000000"
      property color mOnSurface: "#000000"
      property color mSurfaceVariant: "#000000"
      property color mOnSurfaceVariant: "#000000"
      property color mOutline: "#000000"
      property color mShadow: "#000000"
      property color mHover: "#000000"
      property color mOnHover: "#000000"
    }
  }

  function writeColorsToDisk(obj: var): void {
    ColorSchemeUtils.writeColorsToDisk(obj, out, colorsWriter, root);
  }
}
