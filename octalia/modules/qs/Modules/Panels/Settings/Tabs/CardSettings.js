.pragma library

function saveCards(cardsModel, settings, key) {
  const toSave = [];
  for (let i = 0; i < cardsModel.length; i++) {
    toSave.push({ id: cardsModel[i].id, enabled: cardsModel[i].enabled });
  }
  settings[key] = toSave;
}

function initializeCalendarCards(root, defaults, savedCards, weatherEnabled) {
  let card;
  root.cardsModel = [];
  for (let i = 0; i < savedCards.length; i++) {
    const settingCard = savedCards[i];
    for (let j = 0; j < defaults.length; j++) {
      if (settingCard.id === defaults[j].id) {
        card = defaults[j];
        card.enabled = settingCard.enabled;
        if (card.id === "weather-card" && !weatherEnabled) card.enabled = false;
        root.cardsModel.push(card);
      }
    }
  }
  for (let i = 0; i < defaults.length; i++) {
    let found = false;
    for (let j = 0; j < root.cardsModel.length; j++) {
      if (root.cardsModel[j].id === defaults[i].id) { found = true; break; }
    }
    if (!found) {
      card = defaults[i];
      if (card.id === "weather-card" && !weatherEnabled) card.enabled = false;
      root.cardsModel.push(card);
    }
  }
  root.saveCards();
}

function setWeatherEnabled(root, enabled) {
  const newModel = root.cardsModel.slice();
  for (let i = 0; i < newModel.length; i++) {
    if (newModel[i].id === "weather-card") {
      newModel[i] = Object.assign({}, newModel[i], { enabled: enabled });
      root.cardsModel = newModel;
      root.saveCards();
      break;
    }
  }
}
