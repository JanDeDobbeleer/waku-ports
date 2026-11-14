.pragma library

function field(object, name) {
  return object ? object[name] : undefined;
}

function arrayLength(value) {
  return value && typeof value.length === "number" ? value.length : 0;
}

function sameNode(left, right) {
  return !!left && !!right && field(left, "id") === field(right, "id");
}

function isCaptureStream(node) {
  const properties = field(node, "properties");
  if (!properties)
    return false;
  if (properties["stream.capture.sink"] !== undefined)
    return true;
  const mediaClass = properties["media.class"] || "";
  if (mediaClass.includes("Capture") || mediaClass === "Stream/Input" || mediaClass === "Stream/Input/Audio")
    return true;
  return (properties["media.role"] || "") === "Capture";
}

function isValidMatch(searchTerm, entry) {
  if (!entry)
    return false;
  const search = searchTerm.toLowerCase();
  const id = (field(entry, "id") || "").toLowerCase();
  const name = (field(entry, "name") || "").toLowerCase();
  const icon = (field(entry, "icon") || "").toLowerCase();
  return id.includes(search) || name.includes(search) || icon.includes(search) || search.includes(id.split(".").pop()) || search.includes(name.replace(/\s+/g, ""));
}

function appName(node, themeIcons) {
  if (!node)
    return "Unknown App";
  const properties = field(node, "properties");
  const description = field(node, "description") || "";
  const name = field(node, "name") || "";
  if (!properties) {
    if (description)
      return description;
    if (name) {
      const nameParts = name.split(/[-_]/);
      if (nameParts.length > 0 && nameParts[0])
        return nameParts[0].charAt(0).toUpperCase() + nameParts[0].slice(1);
      return name;
    }
    return "Unknown App";
  }
  const binaryName = properties["application.process.binary"] || "";
  let entry;
  let binParts;
  let nameParts;
  let parts;
  if (binaryName) {
    binParts = binaryName.split("/");
    if (binParts.length > 0) {
      const binName = binParts[binParts.length - 1].toLowerCase();
      entry = themeIcons.findAppEntry(binName);
      if (entry && field(entry, "name") && isValidMatch(binName, entry))
        return field(entry, "name");
    }
  }
  let computedAppName = properties["application.name"] || "";
  const mediaName = properties["media.name"] || "";
  const mediaTitle = properties["media.title"] || "";
  const appId = properties["application.id"] || "";
  if (appId) {
    entry = themeIcons.findAppEntry(appId);
    if (entry && field(entry, "name") && isValidMatch(appId, entry))
      return field(entry, "name");
    if (!computedAppName) {
      parts = appId.split(".");
      if (parts.length > 0 && parts[0])
        computedAppName = parts[0].charAt(0).toUpperCase() + parts[0].slice(1);
    }
  }
  if (!computedAppName && binaryName) {
    binParts = binaryName.split("/");
    if (binParts.length > 0 && binParts[binParts.length - 1])
      computedAppName = binParts[binParts.length - 1].charAt(0).toUpperCase() + binParts[binParts.length - 1].slice(1);
  }
  let result = computedAppName || mediaTitle || mediaName || binaryName || description || name;
  if (!result || result === "" || result === "Unknown App") {
    if (name) {
      nameParts = name.split(/[-_]/);
      if (nameParts.length > 0 && nameParts[0])
        result = nameParts[0].charAt(0).toUpperCase() + nameParts[0].slice(1);
    }
  }
  return result || "Unknown App";
}

function appStreamTitle(node, applicationName) {
  if (!node)
    return "";
  const properties = field(node, "properties");
  const artist = properties ? (properties["media.artist"] || "").trim() : "";
  const title = properties ? (properties["media.title"] || "").trim() : "";
  const mediaName = properties ? (properties["media.name"] || "").trim() : "";
  let raw = "";
  if (title && artist)
    raw = artist + " — " + title;
  else if (title)
    raw = title;
  else if (artist)
    raw = artist;
  else if (mediaName)
    raw = mediaName;
  if (!raw)
    raw = (field(node, "description") || "").trim();
  if (!raw)
    return "";
  if (raw.toLowerCase() === applicationName.trim().toLowerCase())
    return "";
  return raw;
}

function appIcon(node, themeIcons) {
  const fallback = themeIcons.iconFromName("application-x-executable", "application-x-executable");
  if (!node)
    return fallback;
  const properties = field(node, "properties");
  const name = field(node, "name") || "";
  let entry;
  let nameParts;
  let binParts;
  if (!properties) {
    if (name) {
      nameParts = name.split(/[-_]/);
      if (nameParts.length > 0) {
        entry = themeIcons.findAppEntry(nameParts[0].toLowerCase());
        if (entry && field(entry, "icon") && isValidMatch(nameParts[0].toLowerCase(), entry))
          return themeIcons.iconFromName(field(entry, "icon"), "application-x-executable");
      }
    }
    return fallback;
  }
  const binaryName = properties["application.process.binary"] || "";
  if (binaryName) {
    binParts = binaryName.split("/");
    if (binParts.length > 0) {
      const binName = binParts[binParts.length - 1].toLowerCase();
      entry = themeIcons.findAppEntry(binName);
      if (entry && field(entry, "icon") && isValidMatch(binName, entry))
        return themeIcons.iconFromName(field(entry, "icon"), "");
    }
  }
  const iconName = properties["application.icon-name"] || "";
  if (iconName && themeIcons.iconExists(iconName)) {
    const iconPath = themeIcons.iconFromName(iconName, "");
    if (iconPath && iconPath !== "")
      return iconPath;
  }
  const appId = properties["application.id"] || "";
  if (appId) {
    entry = themeIcons.findAppEntry(appId);
    if (entry && field(entry, "icon") && isValidMatch(appId, entry))
      return themeIcons.iconFromName(field(entry, "icon"), "");
  }
  const appNameValue = properties["application.name"] || "";
  if (appNameValue) {
    entry = themeIcons.findAppEntry(appNameValue.toLowerCase());
    if (entry && field(entry, "icon") && isValidMatch(appNameValue.toLowerCase(), entry))
      return themeIcons.iconFromName(field(entry, "icon"), "");
  }
  if (name) {
    nameParts = name.split(/[-_]/);
    if (nameParts.length > 0) {
      entry = themeIcons.findAppEntry(nameParts[0].toLowerCase());
      if (entry && field(entry, "icon") && isValidMatch(nameParts[0].toLowerCase(), entry))
        return themeIcons.iconFromName(field(entry, "icon"), "");
    }
  }
  return themeIcons.iconFromName("application-x-executable", "application-x-executable");
}

function devicesWithGroup(nodes, group, owner) {
  const result = [];
  for (let i = 0; i < arrayLength(nodes); i++)
    result.push({ "node": nodes[i], "group": group, "owner": owner });
  return result;
}

function setOutputVolume(deviceData, volume) {
  const owner = field(deviceData, "owner");
  if (owner)
    owner.localOutputVolume = volume;
}

function closePanel(item) {
  while (item) {
    if (typeof item.close === "function") {
      item.close();
      return;
    }
    item = item.parent;
  }
}
