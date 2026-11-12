pragma Singleton
import "ThemeIconsUtils.js" as ThemeIconsUtils

import QtQuick 6.10
import Quickshell
import qs.Commons
import qs.Services.System

Singleton {
  id: root

  property real scoreThreshold: 0.2

  // Manual overrides for tricky apps
  property var substitutions: ({
                                 "code-url-handler": "visual-studio-code",
                                 "Code": "visual-studio-code",
                                 "gnome-tweaks": "org.gnome.tweaks",
                                 "pavucontrol-qt": "pavucontrol",
                                 "wps": "wps-office2019-kprometheus",
                                 "wpsoffice": "wps-office2019-kprometheus",
                                 "footclient": "foot"
                               })

  // Dynamic fixups
  property var regexSubstitutions: [
    {
      "regex": /^steam_app_(\d+)$/,
      "replace": "steam_icon_$1"
    },
    {
      "regex": /Minecraft.*/,
      "replace": "minecraft-launcher"
    },
    {
      "regex": /.*polkit.*/,
      "replace": "system-lock-screen"
    },
    {
      "regex": /gcr.prompter/,
      "replace": "system-lock-screen"
    }
  ]

  property list<DesktopEntry> entryList: []
  property var preppedNames: []
  property var preppedIcons: []
  property var preppedIds: []

  Component.onCompleted: refreshEntries()

  Connections {
    target: DesktopEntries.applications
    function onValuesChanged(): var {
      root.refreshEntries();
    }
  }

  function refreshEntries(): void {
    ThemeIconsUtils.refreshEntries(root, DesktopEntries);
  }

  function updatePreppedData(): void {
    ThemeIconsUtils.updatePreppedData(root, FuzzySort);
  }

  function iconForAppId(appId: var, fallbackName: var): var {
    return ThemeIconsUtils.iconForAppId(appId, fallbackName, root);
  }

  // Robust lookup strategy
  function findAppEntry(str: var): var {
    return ThemeIconsUtils.findAppEntry(str, root);
  }

  function iconFromName(iconName: var, fallbackName: var): var {
    return ThemeIconsUtils.iconFromName(iconName, fallbackName, Quickshell);
  }

  function distroLogoPath(): var {
    return HostService.osLogo;
  }

  // --- Lookup Helpers ---

  function checkHeuristic(str: var): var {
    if (typeof DesktopEntries !== 'undefined' && DesktopEntries.heuristicLookup) {
      const entry = DesktopEntries.heuristicLookup(str);
      if (entry)
        return entry;
    }
    return null;
  }

  function checkSubstitutions(str: var): var {
    let effectiveStr = substitutions[str];
    if (!effectiveStr)
      effectiveStr = substitutions[str.toLowerCase()];

    if (effectiveStr && effectiveStr !== str) {
      return findAppEntry(effectiveStr);
    }
    return null;
  }

  function checkRegex(str: var): var {
    return ThemeIconsUtils.checkRegex(str, root);
  }

  function checkSimpleTransforms(str: var): var {
    if (typeof DesktopEntries === 'undefined' || !DesktopEntries.byId)
      return null;

    const lower = str.toLowerCase();

    const variants = [str, lower, getFromReverseDomain(str), getFromReverseDomain(str).toLowerCase(), normalizeWithHyphens(str), str.replace(/_/g, '-').toLowerCase(), str.replace(/-/g, '_').toLowerCase()];

    for (let i = 0; i < variants.length; i++) {
      const variant = variants[i];
      if (variant) {
        const entry = DesktopEntries.byId(variant);
        if (entry)
          return entry;
      }
    }
    return null;
  }

  function checkFuzzySearch(str: var): var {
    return ThemeIconsUtils.checkFuzzySearch(str, root, FuzzySort);
  }

  function checkCleanMatch(str: var): var {
    return ThemeIconsUtils.checkCleanMatch(str, root, DesktopEntries);
  }

  function fuzzyQuery(search: var, preppedData: var): var {
    return ThemeIconsUtils.fuzzyQuery(search, preppedData, FuzzySort);
  }

  function iconExists(iconName: var): var {
    return ThemeIconsUtils.iconExists(iconName, Quickshell);
  }

  function getFromReverseDomain(str: var): string {
    if (!str)
      return "";
    return str.split('.').slice(-1)[0];
  }

  function normalizeWithHyphens(str: var): var {
    if (!str)
      return "";
    return str.toLowerCase().replace(/\s+/g, "-");
  }

  // Deprecated shim
  function guessIcon(str: var): var {
    return ThemeIconsUtils.guessIcon(str, root);
  }
}
