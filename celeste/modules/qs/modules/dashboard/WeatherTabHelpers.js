.pragma library

function date(forecast) { return forecast.date; }
function icon(forecast) { return forecast.icon; }
function formatTemp(weather, forecast, minimum) {
    return weather.formatTemp(minimum ? forecast.minTempC : forecast.maxTempC, true);
}
