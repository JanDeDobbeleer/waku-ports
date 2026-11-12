pragma Singleton

import "I18nUtils.js" as I18nUtils

import QtQuick 6.10
import Quickshell
import Quickshell.Io
import qs.Commons

Singleton {
  id: root

  property bool isLoaded: false
  property string langCode: ""
  property var locale: Qt.locale()
  property string systemDetectedLangCode: ""
  property string fullLocaleCode: "" // Preserves regional locale variants
  property string _detectedLanguageCode: "en"
  property string _detectedFullLocale: "en"
  property var translations: ({})
  property var fallbackTranslations: ({})

  // Static list of available translations — update when adding/removing translation files
  property var availableLanguages: ["en", "en-GB", "cs", "de", "es", "fr", "hu", "it", "ja", "ko-KR", "ku", "nl", "nn-HN", "nn-NO", "pl", "pt", "ru", "sv", "tr", "uk-UA", "vi", "zh-CN", "zh-TW"]

  // Default date format per language (used by lock screen, etc.)
  readonly property var dateFormats: ({
                                        "cs": "dddd d. MMMM",
                                        "de": "dddd, d. MMMM",
                                        "en": "dddd, MMMM d",
                                        "es": "dddd, d 'de' MMMM",
                                        "fr": "dddd d MMMM",
                                        "hu": "MMMM d., dddd",
                                        "it": "dddd d MMMM",
                                        "ja": "yyyy年M月d日 dddd",
                                        "ko": "yyyy년 M월 d일 dddd",
                                        "ku": "dddd, dê MMMM",
                                        "nl": "dddd d MMMM",
                                        "nn": "dddd d. MMMM",
                                        "pl": "dddd, d MMMM",
                                        "pt": "dddd, d 'de' MMMM",
                                        "ro": "dddd, d MMMM",
                                        "ru": "dddd, d MMMM",
                                        "sv": "dddd d MMMM",
                                        "tr": "dddd, d MMMM",
                                        "uk": "dddd, d MMMM",
                                        "vi": "dddd, d 'tháng' M",
                                        "zh": "yyyy年M月d日 dddd"
                                      })

  // Signals for reactive updates
  signal languageChanged(string newLanguage)
  signal translationsLoaded

  // FileView to load translation files
  property FileView translationFile: FileView {
    id: fileView
    printErrors: false
    watchChanges: true
    onFileChanged: reload()
    onLoaded: I18nUtils.translationLoaded(root, fileView, Logger, fallbackFileView, Quickshell)

    onLoadFailed: function (error) {
      var shortCode;
      if (root.langCode === "en") {
        Logger.e("I18n", `Failed to load English translation file: ${error}`);
        // English also failed - still emit signal to unblock startup
        root.isLoaded = true;
        root.translationsLoaded();
        return;
      }

      // Qt.callLater is needed because FileView doesn't re-trigger when path
      // is changed inside its own onLoadFailed handler
      var strippedCode = root.stripScript(root.langCode);
      if (strippedCode !== root.langCode) {
        Logger.d("I18n", `Translation file for "${root.langCode}" not found, trying "${strippedCode}"`);
        root.langCode = strippedCode;
        Qt.callLater(root.loadTranslations);
      } else {
        // Try language-only code (e.g. "zh-CN" → "zh")
        shortCode = root.langCode.substring(0, 2);
        if (shortCode !== root.langCode) {
          Logger.d("I18n", `Translation file for "${root.langCode}" not found, trying "${shortCode}"`);
          root.langCode = shortCode;
          Qt.callLater(root.loadTranslations);
        } else {
          Logger.w("I18n", `Translation file for "${root.langCode}" not found, falling back to English`);
          root.langCode = "en";
          root.fullLocaleCode = "en";
          root.locale = Qt.locale("en");
          Qt.callLater(root.loadTranslations);
        }
      }
    }
  }

  // FileView to load fallback translation files
  property FileView fallbackTranslationFile: FileView {
    id: fallbackFileView
    watchChanges: true
    onFileChanged: reload()
    onLoaded: I18nUtils.fallbackLoaded(root, fallbackFileView, Logger)

    onLoadFailed: function (error) {
      Logger.e("I18n", `Failed to load fallback translation file: ${error}`);
    }
  }

  // Correct language when settings finish loading from disk (or user changes it)
  Connections {
    target: Settings.data.general
    function onLanguageChanged() {
      var userLang = Settings.data.general.language;
      if (userLang !== "" && userLang !== root.langCode && root.availableLanguages.includes(userLang)) {
        Logger.i("I18n", `Applying user language preference: "${userLang}"`);
        root.setLanguage(userLang);
      } else if (userLang === "" && root.systemDetectedLangCode !== "" && root.systemDetectedLangCode !== root.langCode) {
        Logger.i("I18n", `Language reset to default, reverting to system language: "${root.systemDetectedLangCode}"`);
        root.setLanguage(root.systemDetectedLangCode);
      }
    }
  }

  Component.onCompleted: {
    Logger.i("I18n", "Service started");

    root.determineFastLanguage();
    langCode = _detectedLanguageCode;
    fullLocaleCode = _detectedFullLocale;
    locale = Qt.locale(fullLocaleCode);
    systemDetectedLangCode = langCode;
    Logger.i("I18n", `Loading "${langCode}" (locale: "${fullLocaleCode}")`);
    loadTranslations();
  }

  // Strip 4-letter script subtag from a BCP 47 tag (e.g. "fr-Latn-FR" → "fr-FR")
  function stripScript(tag: string): string {
    var i;
    var parts = tag.split("-");
    var result = [];
    for (i = 0; i < parts.length; i++) {
      if (parts[i].length === 4 && /^[A-Za-z]{4}$/.test(parts[i])) {
        continue;
      }
      result.push(parts[i]);
    }
    return result.join("-");
  }

  // Determine the best language match against availableLanguages
  function determineFastLanguage(): void {
    var fullLang, i, short_, stripped;
    // User preference from Settings (defaults to "" if not yet loaded from disk)
    var userLang = Settings.data.general.language;
    if (userLang !== "" && availableLanguages.includes(userLang)) {
      _detectedLanguageCode = userLang;
      _detectedFullLocale = userLang;
      return;
    }

    // Match system locale against available translations
    for (i = 0; i < Qt.locale().uiLanguages.length; i++) {
      fullLang = Qt.locale().uiLanguages[i];

      // Exact match (e.g. "zh-CN")
      if (availableLanguages.includes(fullLang)) {
        _detectedLanguageCode = fullLang;
        _detectedFullLocale = fullLang;
        return;
      }

      // Script-stripped match (e.g. "zh-Hans-CN" → "zh-CN")
      stripped = stripScript(fullLang);
      if (stripped !== fullLang && availableLanguages.includes(stripped)) {
        _detectedLanguageCode = stripped;
        _detectedFullLocale = fullLang;
        return;
      }

      // Language-only match (e.g. "fr-FR" → "fr")
      short_ = fullLang.substring(0, 2);
      if (availableLanguages.includes(short_)) {
        _detectedLanguageCode = short_;
        _detectedFullLocale = fullLang;
        return;
      }
    }

    _detectedLanguageCode = "en";
    _detectedFullLocale = "en";
  }

  function dateFormat(): string {
    var lang = langCode.split("-")[0];
    return dateFormats[lang] || "dddd, d MMMM";
  }

  // -------------------------------------------
  function setLanguage(newLangCode: string): void {
    setLanguageForLocale(newLangCode, newLangCode);
  }

  function setLanguageForLocale(newLangCode: string, fullLocale: string): void {
    if (newLangCode !== langCode && availableLanguages.includes(newLangCode)) {
      langCode = newLangCode;
      fullLocaleCode = fullLocale;
      locale = Qt.locale(fullLocale);
      Logger.i("I18n", `Language set to "${langCode}" with locale "${fullLocale}"`);
      languageChanged(langCode);
      loadTranslations();
    } else if (!availableLanguages.includes(newLangCode)) {
      Logger.w("I18n", `Language "${newLangCode}" is not available`);
    }
  }

  // -------------------------------------------
  function loadTranslations(): void {
    if (langCode === "")
      return;
    const filePath = `${Quickshell.shellDir}/Assets/Translations/${langCode}.json`;
    fileView.path = filePath;
    isLoaded = false;
  }

  // -------------------------------------------
  // Check if a translation exists
  function hasTranslation(key: string): bool {
    var i;
    if (!isLoaded)
      return false;

    const keys = key.split(".");
    var value = translations;

    for (i = 0; i < keys.length; i++) {
      if (value && typeof value === "object" && keys[i] in value) {
        value = value[keys[i]];
      } else {
        return false;
      }
    }

    return typeof value === "string";
  }

  // -------------------------------------------
  // Get all translation keys (useful for debugging)
  function getAllKeys(obj: var, prefix: var): var {
    return I18nUtils.getAllKeys(obj, prefix, root);
  }

  // -------------------------------------------
  // Reload translations (useful for development)
  function reload(): void {
    Logger.d("I18n", "Reloading translations");
    loadTranslations();
  }

  // -------------------------------------------
  // Main translation function
  function tr(key: string): string {
    return I18nUtils.tr(key, undefined, root, Logger);
  }

  function trArgs(key: string, interpolations: var): string {
    return I18nUtils.tr(key, interpolations, root, Logger);
  }

  // -------------------------------------------
  // Plural translation function
  function trp(key: string, count: var): string {
    return I18nUtils.trp(key, count, undefined, root);
  }

  function trpArgs(key: string, count: var, interpolations: var): string {
    return I18nUtils.trp(key, count, interpolations, root);
  }
}
