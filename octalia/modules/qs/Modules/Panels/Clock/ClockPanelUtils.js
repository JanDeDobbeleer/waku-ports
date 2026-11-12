.pragma library

function field(object, name) {
  return object ? object[name] : undefined;
}

function cardEnabled(card, weatherEnabled) {
  const id = field(card, "id");
  return !!field(card, "enabled") && (id !== "weather-card" || weatherEnabled);
}

function sourceForCard(card) {
  switch (field(card, "id")) {
  case "calendar-header-card":
    return "../../Cards/CalendarHeaderCard.qml";
  case "calendar-month-card":
    return "../../Cards/CalendarMonthCard.qml";
  case "weather-card":
    return "../../Cards/WeatherCard.qml";
  default:
    return "";
  }
}

function configureItem(card, item) {
  if (item && field(card, "id") === "weather-card") {
    item.forecastDays = 5;
    item.showLocation = false;
  }
}
