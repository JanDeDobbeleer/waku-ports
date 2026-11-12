.pragma library

function extractLayoutCode(layoutString, root, I18n) {
    if (!layoutString)
      return I18n.tr("common.unknown");

    const str = layoutString.toLowerCase();

    // If it's already a short code (2-3 chars), return uppercase
    if (/^[a-z]{2,3}(\+.*)?$/.test(str)) {
      return str.split('+')[0].toUpperCase();
    }

    // Check for layout variants first - these are more meaningful than country codes
    // when distinguishing between multiple layouts of the same language
    for (const [pattern, display] of Object.entries(root.variantMap)) {
      if (str.includes(pattern)) {
        return display;
      }
    }

    // Extract short code from parentheses like "English (US)"
    const shortCodeMatch = str.match(/\(([a-z]{2,3})\)/i);
    if (shortCodeMatch) {
      return shortCodeMatch[1].toUpperCase();
    }

    // Check for language/country names in the language map
    // First, try to match at the start of the string (the primary language)
    for (const [lang, code] of Object.entries(root.languageMap)) {
      if (str.startsWith(lang)) {
        return code.toUpperCase();
      }
    }
    // Then try word boundary matching anywhere in the string
    for (const [lang, code] of Object.entries(root.languageMap)) {
      const regex = new RegExp(`\\b${lang}\\b`);
      if (regex.test(str)) {
        return code.toUpperCase();
      }
    }

    // If nothing matches, try first 2-3 characters if they look like a code
    const codeMatch = str.match(/^([a-z]{2,3})/);
    return codeMatch ? codeMatch[1].toUpperCase() : I18n.tr("common.unknown");
}
