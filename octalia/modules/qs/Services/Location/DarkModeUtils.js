.pragma library

function collectWeatherChanges(weather) {
    var i;
    const changes = [];

    if (Date.now() < Date.parse(weather.daily.sunrise[0])) {
      // The sun has not risen yet
      changes.push({
                     "time": Date.now() - 1,
                     "darkMode": true
                   });
    }

    for (i = 0; i < weather.daily.sunrise.length; i++) {
      changes.push({
                     "time": Date.parse(weather.daily.sunrise[i]),
                     "darkMode": false
                   });
      changes.push({
                     "time": Date.parse(weather.daily.sunset[i]),
                     "darkMode": true
                   });
    }

    return changes;
}

function applyCurrentMode(changes, Settings, Logger) {
    var i;
    const now = Date.now();
    Logger.i("DarkModeService", `Applying mode at ${new Date(now).toLocaleString()} (${now})`);

    // changes.findLast(change => change.time < now) // not available in QML...
    let lastChange = null;
    for (i = 0; i < changes.length; i++) {
      Logger.d("DarkModeService", `Checking change: time=${changes[i].time} (${new Date(changes[i].time).toLocaleString()}), darkMode=${changes[i].darkMode}`);
      if (changes[i].time < now) {
        lastChange = changes[i];
      }
    }

    if (lastChange) {
      Logger.i("DarkModeService", `Selected change: time=${lastChange.time}, darkMode=${lastChange.darkMode}`);
      Settings.data.colorSchemes.darkMode = lastChange.darkMode;
      Logger.d("DarkModeService", `Reset: darkmode=${lastChange.darkMode}`);
    } else {
      Logger.w("DarkModeService", "No suitable change found for current time!");
    }
}

function scheduleNextMode(changes, root, Logger, timer) {
    const now = Date.now();
    let nextChange = null;
    for (let i = 0; i < changes.length; i++) {
      if (changes[i].time > now) {
        nextChange = changes[i];
        break;
      }
    }
    if (nextChange) {
      root.nextDarkModeState = nextChange.darkMode;
      timer.interval = nextChange.time - now;
      timer.restart();
      Logger.d("DarkModeService", `Scheduled: darkmode=${nextChange.darkMode} in ${timer.interval} ms`);
    }
}

function collectManualChanges(root, Settings) {
    const sunriseTime = root.parseTime(Settings.data.colorSchemes.manualSunrise);
    const sunsetTime = root.parseTime(Settings.data.colorSchemes.manualSunset);

    const now = new Date();
    const year = now.getFullYear();
    const month = now.getMonth();
    const day = now.getDate();

    const yesterdaysSunset = new Date(year, month, day - 1, sunsetTime.hour, sunsetTime.minute);
    const todaysSunrise = new Date(year, month, day, sunriseTime.hour, sunriseTime.minute);
    const todaysSunset = new Date(year, month, day, sunsetTime.hour, sunsetTime.minute);
    const tomorrowsSunrise = new Date(year, month, day + 1, sunriseTime.hour, sunriseTime.minute);

    return [
          {
            "time": yesterdaysSunset.getTime(),
            "darkMode": true
          },
          {
            "time": todaysSunrise.getTime(),
            "darkMode": false
          },
          {
            "time": todaysSunset.getTime(),
            "darkMode": true
          },
          {
            "time": tomorrowsSunrise.getTime(),
            "darkMode": false
          }
        ];
}

function weather(data) {
  return data.weather;
}
