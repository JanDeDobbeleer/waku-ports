.pragma library

function matchIconRule(name, iconRule) {
    if (!iconRule.icon)
        return false;
    if (iconRule.regex) {
        const expression = new RegExp(iconRule.regex, iconRule.flags || "");
        if (expression.test(name))
            return true;
    } else if (iconRule.name === name) {
        return true;
    }
    return false;
}

function matchIconRuleList(name, rules) {
    if (!rules || !rules.values)
        return "";
    for (let i = 0; i < rules.values.length; i++) {
        const rule = rules.values[i];
        if (matchIconRule(name, rule))
            return rule.icon;
    }
    return "";
}

function appCategoryIcon(name, fallback, rules, categoryIcons, desktopEntries) {
    const matchingIcon = matchIconRuleList(name, rules);
    if (matchingIcon)
        return matchingIcon;
    const categories = desktopEntries.heuristicLookup(name)?.categories;
    if (categories) {
        for (const key in categoryIcons) {
            if (categories.includes(key))
                return categoryIcons[key];
        }
    }
    return fallback;
}

function matchIcon(text, rules, fallback) {
    for (let i = 0; i < rules.length; i++) {
        const needles = rules[i][0];
        for (let j = 0; j < needles.length; j++) {
            if (text.includes(needles[j]))
                return rules[i][1];
        }
    }
    return fallback;
}

function networkIcon(strength, isSecure, icons) {
    const level = Math.max(0, Math.min(4, Math.floor(strength / 20)));
    const icon = icons[level];
    return isSecure && level > 0 ? icon + "_locked" : icon;
}

function trayIcon(id, icon, tray, quickshell, qt) {
    const subscriptions = tray.iconSubs.values;
    for (let i = 0; i < subscriptions.length; i++) {
        const substitution = subscriptions[i];
        if (substitution.id === id)
            return substitution.image ? qt.resolvedUrl(substitution.image) : quickshell.iconPath(substitution.icon);
    }
    if (icon.includes("?path=")) {
        const parts = icon.split("?path=");
        const fileName = parts[0].slice(parts[0].lastIndexOf("/") + 1);
        const themed = quickshell.iconPath(fileName, true);
        icon = themed ? themed : qt.resolvedUrl(parts[1] + "/" + fileName);
    }
    return icon;
}

function batteryIcon(percentage, charging) {
    if (percentage === 1)
        return charging ? "battery_charging_full" : "battery_full";
    let level = Math.floor(percentage * 7);
    if (charging && (level === 4 || level === 1))
        level--;
    return charging ? "battery_charging_" + ((level + 3) * 10) : "battery_" + level + "_bar";
}
