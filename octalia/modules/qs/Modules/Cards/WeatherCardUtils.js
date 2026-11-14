.pragma library

function field(object, name) {
  return object ? object[name] : undefined;
}

function weatherData(service) {
  return field(field(service, "data"), "weather");
}

function currentWeatherValue(weather, name) {
  return field(field(weather, "current_weather"), name);
}

function forecastLength(weather) {
  const daily = field(weather, "daily");
  const times = field(daily, "time");
  return times && typeof times.length === "number" ? times.length : 0;
}

function forecastValue(weather, index, name) {
  const values = field(field(weather, "daily"), name);
  return values && index >= 0 && index < values.length ? values[index] : undefined;
}

function weatherSymbol(service, code) {
  return service.weatherSymbolFromCode(code);
}
