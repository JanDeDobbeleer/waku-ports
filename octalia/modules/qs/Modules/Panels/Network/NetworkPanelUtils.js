.pragma library

function field(record, name) {
  return record ? record[name] : undefined;
}

function arrayLength(value) {
  return value ? value.length : 0;
}

function isWindowVisible(window) {
  return !!window && window.visible;
}

function textField(record, name, fallback) {
  var value = field(record, name);
  return value ? value : fallback;
}

function hasTextField(record, name) {
  return (field(record, name) || "").length > 0;
}

function interfaceName(record, activeIf, fallback) {
  var name = field(record, "ifname");
  return name && name.length > 0 ? name : (activeIf || fallback);
}

function hasInterfaceName(record, activeIf) {
  return hasTextField(record, "ifname") || (activeIf || "").length > 0;
}

function versionFieldText(record, version, ipv4Name, ipv6Name, fallback) {
  if (version === 4)
    return textField(record, ipv4Name, fallback);
  var addresses = field(record, ipv6Name) || [];
  return addresses.join(", ") || fallback;
}

function hasVersionField(record, version, ipv4Name, ipv6Name) {
  if (version === 4)
    return hasTextField(record, ipv4Name);
  return (field(record, ipv6Name) || []).length > 0;
}

function versionListText(record, version, ipv4Name, ipv6Name, fallback) {
  var addresses = field(record, version === 4 ? ipv4Name : ipv6Name) || [];
  return addresses.join(", ") || fallback;
}

function hasVersionList(record, version, ipv4Name, ipv6Name) {
  return (field(record, version === 4 ? ipv4Name : ipv6Name) || []).length > 0;
}
