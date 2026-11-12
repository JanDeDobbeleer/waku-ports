.pragma library

function field(object, name) {
  return object[name];
}

function optionalField(object, name) {
  return object?.[name];
}

function gcd(a, b) {
  while (b !== 0) {
    var temp = b;
    b = a % b;
    a = temp;
  }
  return a;
}

function pointCoordinate(item, point, coordinate) {
  return item.points[point][coordinate];
}

function currentWeatherField(weather, name) {
  return weather.current_weather[name];
}

function hasDailyWeather(weather, name) {
  return !!weather.daily && weather.daily[name].length !== 0;
}

function dailyWeatherValue(weather, name) {
  return weather.daily[name][0];
}

function widgetsForScreen(monitorWidgets, screenName) {
  for (var i = 0; i < monitorWidgets.length; i++) {
    if (monitorWidgets[i].name === screenName)
      return monitorWidgets[i].widgets || [];
  }
  return [];
}

function copyWidgetMetadata(widget, metadata) {
  if (metadata)
    Object.keys(metadata).forEach(function (key) { widget[key] = metadata[key]; });
}

function writeField(object, name, value) {
  object[name] = value;
}

function withoutRegion(regions, region) {
  return regions.filter(function (r) { return r !== region; });
}
