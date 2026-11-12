pragma Singleton

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
  readonly property var schemeTypes: allSchemeTypes.filter(t => S.ColorScheme.variants.includes(root.variantMap[t.key]))

  // The request in flight; a result that does not match it is stale and dropped.
  property string pendingPath: ""
  property bool pendingDark: true
  property string pendingVariant: ""

  // Check if a template is enabled in the activeTemplates array
  function isTemplateEnabled(templateId): bool {
    const activeTemplates = Settings.data.templates.activeTemplates;
    if (!activeTemplates)
      return false;
    for (let i = 0; i < activeTemplates.length; i++) {
      if (activeTemplates[i].id === templateId && activeTemplates[i].enabled) {
        return true;
      }
    }
    return false;
  }

  // Get scheme type, defaulting to tonal-spot if not a recognized value
  function getSchemeType() {
    const method = Settings.data.colorSchemes.generationMethod;
    return schemeTypes.some(s => s.key === method) ? method : "tonal-spot";
  }

  function samePath(a, b) {
    return String(a).split("\\").join("/") === String(b).split("\\").join("/");
  }

  // Generates colors.json from the wallpaper image (debounced).
  function processWallpaperColors(wallpaperPath, mode) {
    Logger.d("TemplateProcessor", `processWallpaperColors called: path=${wallpaperPath}, mode=${mode}`);
    pendingPath = String(wallpaperPath || "").replace(/^file:\/+(?=[A-Za-z]:)/, "");
    pendingDark = mode !== "light";
    pendingVariant = root.variantMap[getSchemeType()] || "tonalspot";
    debounceTimer.restart();
  }

  // Predefined schemes need no generation here: ColorSchemeService writes colors.json itself and
  // the python app templates are not available on Windows.
  function processPredefinedScheme(schemeData, mode, wallpaperPath) {
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
  function octaliaColors(c) {
    function role(name, fallbackName) {
      return c[name] !== undefined ? c[name] : c[fallbackName];
    }
    return {
      "mPrimary": c.primary,
      "mOnPrimary": c.onPrimary,
      "mSecondary": c.secondary,
      "mOnSecondary": c.onSecondary,
      "mTertiary": c.tertiary,
      "mOnTertiary": c.onTertiary,
      "mError": c.error,
      "mOnError": c.onError,
      "mSurface": c.surface,
      "mOnSurface": c.onSurface,
      "mSurfaceVariant": role("surfaceContainer", "surfaceVariant"),
      "mOnSurfaceVariant": c.onSurfaceVariant,
      "mOutline": role("outlineVariant", "outline"),
      "mShadow": role("shadow", "surface"),
      "mHover": c.tertiary,
      "mOnHover": c.onTertiary
    };
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

    function onFromImageFinished(path, scheme) {
      if (!root.pendingPath || !root.samePath(path, root.pendingPath) || !Settings.data.colorSchemes.useWallpaperColors)
        return;
      // A result asked for before a dark/light switch arrives with the old mode.
      if (scheme.dark !== root.pendingDark)
        return;
      root.pendingPath = "";
      if (!scheme.valid) {
        Logger.w("TemplateProcessor", "Invalid scheme for", path);
        root.applyFallback();
      } else {
        ColorSchemeService.writeColorsToDisk(root.octaliaColors(scheme.colors));
      }
      root.colorsGenerated();
    }

    function onFromImageFailed(path, error) {
      if (!root.pendingPath || !root.samePath(path, root.pendingPath))
        return;
      Logger.w("TemplateProcessor", "No scheme for", path, error);
      root.pendingPath = "";
      root.applyFallback();
      root.colorsGenerated();
    }
  }
}
