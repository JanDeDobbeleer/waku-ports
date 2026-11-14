.pragma library

function badgeCount(model) {
                      if (typeof model.badges === 'undefined' || model.badges === null)
                        return 0;
                      // Handle both arrays and ListModels
                      if (typeof model.badges.length !== 'undefined')
                        return model.badges.length;
                      if (typeof model.badges.count !== 'undefined')
                        return model.badges.count;
                      return 0;
}

function badgeData(model, index) {
                        if (typeof model.badges === 'undefined' || model.badges === null)
                          return null;
                        // Handle both arrays and ListModels
                        if (typeof model.badges.length !== 'undefined')
                          return model.badges[index];
                        if (typeof model.badges.get !== 'undefined')
                          return model.badges.get(index);
                        return null;
}

function badgeSize(badgeData, Style) {
                        if (!badgeData || !badgeData.size)
                          return Style.fontSizeXS;
                        if (badgeData.size === "xsmall")
                          return Style.fontSizeXXS;
                        else if (badgeData.size === "medium")
                          return Style.fontSizeM;
                        else
                          return Style.fontSizeXS;
}

function badgeIcon(badgeData) { return badgeData && badgeData.icon ? badgeData.icon : ""; }
function badgeColor(badgeData, defaultColor) { return badgeData && badgeData.color ? badgeData.color : defaultColor; }
function badgeVisible(badgeData) { return badgeData && badgeData.icon !== undefined && badgeData.icon !== ""; }
function modelName(model) { return model.name; }

function findIndexByKey(model, key) {
    var i;
    if (!model)
      return -1;
    for (i = 0; i < model.count; i++) {
      if (model.get(i).key === key) {
        return i;
      }
    }
    return -1;
}

function findIndexInActiveModel(model, key) {
    var i;
    if (!model || model.count === undefined)
      return -1;
    for (i = 0; i < model.count; i++) {
      if (model.get(i).key === key) {
        return i;
      }
    }
    return -1;
}

function modelCount(model) { return model.count; }
function modelKey(model, index) { return model.get(index).key; }
function modelItemName(model, index) { return model.get(index).name; }

function clearModel(model) {
  model.clear();
}

function getItem(model, index) {
  return model.get(index);
}

function appendItem(model, item) {
  model.append(item);
}

function closePopup(popup) {
  popup.close();
}

function focusItem(item) {
  item.forceActiveFocus();
}
