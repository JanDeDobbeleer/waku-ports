.pragma library

function field(object, name) {
  return object ? object[name] : undefined;
}

function hasBar(monitors, screenName) {
  return !monitors || monitors.length === 0 || monitors.includes(screenName);
}

function preferredHeight(cards, weatherEnabled, spacing, heights) {
  let height = 0;
  let count = 0;
  if (!cards)
    return spacing;
  for (let i = 0; i < cards.length; i++) {
    const card = cards[i];
    const id = field(card, "id");
    if (!field(card, "enabled") || (id === "weather-card" && !weatherEnabled))
      continue;
    count++;
    height += field(heights, id) || 0;
  }
  return height + (count + 1) * spacing;
}

function cardModels(cards, weatherEnabled, cardComponents) {
  const models = [];
  if (!cards)
    return models;
  for (let i = 0; i < cards.length; i++) {
    const card = cards[i];
    const id = field(card, "id");
    const definition = field(cardComponents, id);
    models.push({
      "active": !!field(card, "enabled") && (id !== "weather-card" || weatherEnabled),
      "height": field(definition, "height") || 0,
      "component": field(definition, "component")
    });
  }
  return models;
}

function ancestorField(object, objectName, propertyName) {
  let current = object;
  while (current) {
    if (field(current, "objectName") === objectName)
      return field(current, propertyName);
    current = field(current, "parent");
  }
  return undefined;
}
