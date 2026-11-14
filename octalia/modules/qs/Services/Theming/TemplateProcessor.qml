pragma Singleton

import "TemplateProcessorUtils.js" as TemplateUtils

import QtQuick 6.10
import Quickshell
import waku.services as S

import qs.Commons
import qs.Services.Theming

// Wallpaper-derived colors, generated in process by the engine's ColorScheme (waku.services).
// Upstream shells out to a python template processor that also writes the app/terminal themes;
// on Windows only Octalia's own colors.json is produced, from the wallpaper image.
Singleton {
  id: root

  // Emitted when a wallpaper color generation finished (also after falling back to the
  // predefined scheme), so pending hooks are released.
  signal colorsGenerated

  // Octalia generation method -> engine variant (S.ColorScheme.variants). Methods without an
  // engine equivalent ("dysfunctional") are left out of schemeTypes.
  readonly property var variantMap: ({
      "tonal-spot": "tonalspot",
      "content": "content",
      "fruit-salad": "fruitsalad",
      "rainbow": "rainbow",
      "monochrome": "monochrome",
      "vibrant": "vibrant",
      "faithful": "fidelity",
      "muted": "neutral"
    })

  readonly property var allSchemeTypes: [
    {
      "key": "tonal-spot",
      "name": "M3-Tonal Spot" // Do not translate
    },
    {
      "key": "content",
      "name": "M3-Content" // Do not translate
    },
    {
      "key": "fruit-salad",
      "name": "M3-Fruit Salad" // Do not translate
    },
    {
      "key": "rainbow",
      "name": "M3-Rainbow" // Do not translate
    },
    {
      "key": "monochrome",
      "name": "M3-Monochrome" // Do not translate
    },
    {
      "key": "vibrant",
      "name": I18n.tr("common.vibrant")
    },
    {
      "key": "faithful",
      "name": I18n.tr("common.faithful")
    },
    {
      "key": "muted",
      "name": I18n.tr("common.color-muted")
    },
  ]

  // Only the methods the engine has a variant for.
  readonly property var schemeTypes: TemplateUtils.schemeTypes(allSchemeTypes, S.ColorScheme.variants, root.variantMap)

  // The request in flight; a result that does not match it is stale and dropped.
  property string pendingPath: ""
  property bool pendingDark: true
  property string pendingVariant: ""

  // Check if a template is enabled in the activeTemplates array
  function isTemplateEnabled(templateId: var): bool {
    return TemplateUtils.isTemplateEnabled(templateId, Settings);
  }

  // Get scheme type, defaulting to tonal-spot if not a recognized value
  function getSchemeType(): var {
    return TemplateUtils.getSchemeType(root, Settings);
  }

  function samePath(a: var, b: var): bool {
    return String(a).split("\\").join("/") === String(b).split("\\").join("/");
  }

  // Generates colors.json from the wallpaper image (debounced).
  function processWallpaperColors(wallpaperPath: var, mode: var): void {
    Logger.d("TemplateProcessor", `processWallpaperColors called: path=${wallpaperPath}, mode=${mode}`);
    pendingPath = String(wallpaperPath || "").replace(/^file:\/+(?=[A-Za-z]:)/, "");
    pendingDark = mode !== "light";
    pendingVariant = root.variantMap[getSchemeType()] || "tonalspot";
    debounceTimer.restart();
  }

  // Predefined schemes need no generation here: ColorSchemeService writes colors.json itself and
  // the python app templates are not available on Windows.
  function processPredefinedScheme(schemeData: var, mode: var, wallpaperPath: var): void {
    cancelPending();
  }

  function request() {
    if (!pendingPath || !Settings.data.colorSchemes.useWallpaperColors)
      return;
    S.ColorScheme.fromImage(pendingPath, pendingVariant, pendingDark);
  }

  function cancelPending() {
    pendingPath = "";
    debounceTimer.stop();
  }

  // Maps the M3 roles of an engine scheme onto Octalia's keys, with the roles the upstream
  // templates/octalia.json uses (surfaceContainer -> mSurfaceVariant, outlineVariant -> mOutline,
  // tertiary -> mHover).
  function octaliaColors(c: var): var {
    return TemplateUtils.octaliaColors(c);
  }

  function applyFallback() {
    if (Settings.data.colorSchemes.predefinedScheme)
      ColorSchemeService.applyScheme(Settings.data.colorSchemes.predefinedScheme);
  }

  Timer {
    id: debounceTimer
    interval: 150
    repeat: false
    onTriggered: root.request()
  }

  Connections {
    target: Settings.data.colorSchemes
    function onUseWallpaperColorsChanged() {
      if (!Settings.data.colorSchemes.useWallpaperColors)
        root.cancelPending();
    }
  }

  Connections {
    target: S.ColorScheme

    function onFromImageFinished(path: var, scheme: var) {
      TemplateUtils.onFromImageFinished(path, scheme, root, Settings, Logger, ColorSchemeService);
    }

    function onFromImageFailed(path: var, error: var): void {
      if (!root.pendingPath || !root.samePath(path, root.pendingPath))
        return;
      Logger.w("TemplateProcessor", "No scheme for", path, error);
      root.pendingPath = "";
      root.applyFallback();
      root.colorsGenerated();
    }
  }
}
