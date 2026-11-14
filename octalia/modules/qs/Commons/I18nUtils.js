.pragma library

function getAllKeys(obj, prefix, root) {
    var key;
    if (typeof obj === "undefined")
      obj = root.translations;
    if (typeof prefix === "undefined")
      prefix = "";

    var keys = [];
    for (key in (obj || {})) {
      const value = obj[key];
      const fullKey = prefix ? `${prefix}.${key}` : key;
      if (typeof value === "object" && value !== null) {
        keys = keys.concat(getAllKeys(value, fullKey, root));
      } else if (typeof value === "string") {
        keys.push(fullKey);
      }
    }
    return keys;
}

function tr(key, interpolations, root, Logger) {
    var placeholder;
    var i;
    if (typeof interpolations === "undefined")
      interpolations = {};

    if (!root.isLoaded) {
      //Logger.d("I18n", "Translations not loaded yet")
      return key;
    }

    // Navigate nested keys (e.g., "menu.file.open")
    const keys = key.split(".");

    // Look-up translation in the active language
    var value = root.translations;
    var notFound = false;
    for (i = 0; i < keys.length; i++) {
      if (value && typeof value === "object" && keys[i] in value) {
        value = value[keys[i]];
      } else {
        Logger.d("I18n", `Translation key "${key}" not found at part "${keys[i]}"`);
        Logger.d("I18n", `Available keys: ${Object.keys(value || {}).join(", ")}`);
        notFound = true;
        break;
      }
    }

    // Fallback to english if not found
    if (notFound && root.availableLanguages.includes("en") && root.langCode !== "en") {
      value = root.fallbackTranslations;
      for (i = 0; i < keys.length; i++) {
        if (value && typeof value === "object" && keys[i] in value) {
          value = value[keys[i]];
        } else {
          // Indicate this key does not even exists in the english fallback
          return `!!${key}!!`;
        }
      }
    } else if (notFound) {
      // No fallback available
      return `!!${key}!!`;
    }

    if (typeof value !== "string") {
      Logger.d("I18n", `Translation key "${key}" is not a string`);
      return key;
    }

    // Handle interpolations (e.g., "Hello {name}!")
    var result = value;
    for (placeholder in interpolations) {
      const regex = new RegExp(`\\{${placeholder}\\}`, 'g');
      result = result.replace(regex, interpolations[placeholder]);
    }

    return result;
}

function trp(key, count, interpolations, root) {
    var prop;
    if (typeof interpolations === "undefined") {
      interpolations = {};
    }

    // Use key for singular, key-plural for plural
    const realKey = count === 1 ? key : `${key}-plural`;

    // Merge interpolations with count
    var finalInterpolations = {
      "count": count
    };
    for (prop in interpolations) {
      finalInterpolations[prop] = interpolations[prop];
    }

    return root.trArgs(realKey, finalInterpolations);
}

function translationLoaded(root, fileView, Logger, fallbackFileView, Quickshell) {
      var data;
      try {
        data = JSON.parse(fileView.text());
        root.translations = data;
        Logger.i("I18n", `Loaded translations for "${root.langCode}"`);

        root.isLoaded = true;
        root.translationsLoaded();

        // Load English fallback for non-English languages (only after main file succeeds)
        if (root.langCode !== "en") {
          fallbackFileView.path = `${Quickshell.shellDir}/Assets/Translations/en.json`;
        }
      } catch (e) {
        Logger.e("I18n", `Failed to parse translation file: ${e}`);
        root.setLanguage("en");
      }
}

function fallbackLoaded(root, fallbackFileView, Logger) {
      var data;
      try {
        data = JSON.parse(fallbackFileView.text());
        root.fallbackTranslations = data;
        Logger.d("I18n", `Loaded english fallback translations`);
      } catch (e) {
        Logger.e("I18n", `Failed to parse fallback translation file: ${e}`);
      }
}
