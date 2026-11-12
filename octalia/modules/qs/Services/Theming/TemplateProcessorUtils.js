.pragma library

function schemeTypes(types, variants, variantMap) {
  return types.filter(t => variants.includes(variantMap[t.key]));
}

function isTemplateEnabled(templateId, Settings) {
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

function getSchemeType(root, Settings) {
    const method = Settings.data.colorSchemes.generationMethod;
    return root.schemeTypes.some(s => s.key === method) ? method : "tonal-spot";
}

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

function onFromImageFinished(path, scheme, root, Settings, Logger, ColorSchemeService) {
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
