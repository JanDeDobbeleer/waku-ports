.pragma library

function refreshEntries(root, DesktopEntries) {
    if (typeof DesktopEntries === 'undefined')
      return;

    const values = Array.from(DesktopEntries.applications.values);
    if (values) {
      root.entryList = values.sort((a, b) => a.name.localeCompare(b.name));
      root.updatePreppedData();
    }
}

function updatePreppedData(root, FuzzySort) {
    if (typeof FuzzySort === 'undefined')
      return;

    const list = Array.from(root.entryList);
    root.preppedNames = list.map(a => ({
                                    name: FuzzySort.prepare(`${a.name} `),
                                    entry: a
                                  }));
    root.preppedIcons = list.map(a => ({
                                    name: FuzzySort.prepare(`${a.icon} `),
                                    entry: a
                                  }));
    root.preppedIds = list.map(a => ({
                                  name: FuzzySort.prepare(`${a.id} `),
                                  entry: a
                                }));
}

function findAppEntry(str, root) {
    if (!str || str.length === 0)
      return null;

    let result = null;

    result = root.checkHeuristic(str);
    if (result)
      return result;
    result = root.checkSubstitutions(str);
    if (result)
      return result;
    result = root.checkRegex(str);
    if (result)
      return result;
    result = root.checkSimpleTransforms(str);
    if (result)
      return result;
    result = root.checkFuzzySearch(str);
    if (result)
      return result;
    result = root.checkCleanMatch(str);
    if (result)
      return result;

    return null;
}

function iconFromName(iconName, fallbackName, Quickshell) {
    const fallback = fallbackName || "application-x-executable";
    try {
      if (iconName && typeof Quickshell !== 'undefined' && Quickshell.iconPath) {
        const p = Quickshell.iconPath(iconName, fallback);
        if (p && p !== "")
          return p;
      }
    } catch (e) {}

    try {
      return Quickshell.iconPath ? (Quickshell.iconPath(fallback, true) || "") : "";
    } catch (e2) {
      return "";
    }
}

function checkRegex(str, root) {
    for (let i = 0; i < root.regexSubstitutions.length; i++) {
      const sub = root.regexSubstitutions[i];
      const replaced = str.replace(sub.regex, sub.replace);
      if (replaced !== str) {
        return root.findAppEntry(replaced);
      }
    }
    return null;
}

function checkFuzzySearch(str, root, FuzzySort) {
    if (typeof FuzzySort === 'undefined')
      return null;

    // Check filenames (IDs) first
    if (root.preppedIds.length > 0) {
      let results = root.fuzzyQuery(str, root.preppedIds);
      if (results.length === 0) {
        const underscored = str.replace(/-/g, '_').toLowerCase();
        if (underscored !== str)
          results = root.fuzzyQuery(underscored, root.preppedIds);
      }
      if (results.length > 0)
        return results[0];
    }

    // Then icons
    if (root.preppedIcons.length > 0) {
      const results = root.fuzzyQuery(str, root.preppedIcons);
      if (results.length > 0)
        return results[0];
    }

    // Then names
    if (root.preppedNames.length > 0) {
      const results = root.fuzzyQuery(str, root.preppedNames);
      if (results.length > 0)
        return results[0];
    }

    return null;
}

function checkCleanMatch(str, root, DesktopEntries) {
    if (!str || str.length <= 3)
      return null;
    if (typeof DesktopEntries === 'undefined' || !DesktopEntries.byId)
      return null;

    // Aggressive fallback: strip all separators
    const cleanStr = str.toLowerCase().replace(/[\.\-_]/g, '');
    const list = Array.from(root.entryList);

    for (let i = 0; i < list.length; i++) {
      const entry = list[i];
      const cleanId = (entry.id || "").toLowerCase().replace(/[\.\-_]/g, '');
      if (cleanId.includes(cleanStr) || cleanStr.includes(cleanId)) {
        return entry;
      }
    }
    return null;
}

function fuzzyQuery(search, preppedData, FuzzySort) {
    if (!search || !preppedData || preppedData.length === 0)
      return [];
    return FuzzySort.go(search, preppedData, {
                          all: true,
                          key: "name"
                        }).map(r => r.obj.entry);
}

function iconExists(iconName, Quickshell) {
    if (!iconName || iconName.length === 0)
      return false;
    if (iconName.startsWith("/"))
      return true;

    const path = Quickshell.iconPath(iconName, true);
    return path && path.length > 0 && !path.includes("image-missing");
}

function guessIcon(str, root) {
    const entry = root.findAppEntry(str);
    return entry ? entry.icon : "image-missing";
}

function iconForAppId(appId, fallbackName, root) {
    const fallback = fallbackName || "application-x-executable";
    if (!appId)
      return root.iconFromName(fallback, fallback);

    const entry = root.findAppEntry(appId);
    if (entry) {
      return root.iconFromName(entry.icon, fallback);
    }

    return root.iconFromName(appId, fallback);
}
