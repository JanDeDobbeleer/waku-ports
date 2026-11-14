.pragma library

function getProperty(object, name) {
  return object === null || object === undefined ? undefined : object[name];
}

function setProperty(object, name, value) {
  object[name] = value;
}

function timerAction(object, timer, action) {
  object[timer][action]();
}

function lowerCaseAppId(appData) {
  return appData.appId?.toLowerCase();
}

function getValidToplevels(appData, manager) {
  if (!appData || !manager || !manager.toplevels)
    return [];
  var source = appData.toplevels && appData.toplevels.length > 0 ? appData.toplevels : (appData.toplevel ? [appData.toplevel] : []);
  var allToplevels = manager.toplevels.values || [];
  return source.filter(function (toplevel) {
    return toplevel && allToplevels.includes(toplevel);
  });
}