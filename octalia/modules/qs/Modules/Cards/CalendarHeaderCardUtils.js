.pragma library

function field(object, name) {
  return object ? object[name] : undefined;
}

function timezoneAbbreviation(data) {
  return field(field(data, "weather"), "timezone_abbreviation");
}
