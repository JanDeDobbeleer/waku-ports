.pragma library

function field(object, name) {
  return object ? object[name] : undefined;
}

function formatEntry(emoji, provider, service, launcher) {
  const title = field(emoji, "name");
  const keywords = field(emoji, "keywords") || [];
  let description = keywords.join(", ");
  const category = field(emoji, "category");
  if (category)
    description += " • Category: " + category;
  const emojiChar = field(emoji, "emoji");
  return {
    "name": title,
    "description": description,
    "icon": null,
    "isImage": false,
    "displayString": emojiChar,
    "autoPasteText": emojiChar,
    "provider": provider,
    "onAutoPaste": function () { service.recordUsage(emojiChar); },
    "onActivate": function () {
      service.copy(emojiChar);
      launcher.close();
    }
  };
}

function formatEntries(emojis, provider, service, launcher) {
  const entries = [];
  if (!emojis)
    return entries;
  for (let i = 0; i < emojis.length; i++)
    entries.push(formatEntry(emojis[i], provider, service, launcher));
  return entries;
}
