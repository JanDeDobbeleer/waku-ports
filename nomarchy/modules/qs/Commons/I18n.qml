pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "Catalog.js" as Catalog
import "I18nUtils.js" as I18nUtils

// Display-language strings for the shell. The selected code lives in
// ~/.config/nomarchy/language (nomarchy-language owns it); a missing file
// means English. Strings come from default/i18n/<code>/shell.json layered
// over the English catalog, so a missing translation falls back to English
// per string. Use as I18n.t("common.search"), with .arg(...) for %1 holes,
// and I18n.tn(key, count).arg(I18n.formatNumber(count)) for an
// entry with plural forms.
// Use formatNumberWithDecimals(value, decimals) when a fixed precision is needed.
// The language file is watched, so switching language under Setup
// re-renders the shell without a restart.
QtObject {
  id: root

  readonly property string nomarchyPath: (Quickshell.env("NOMARCHY_PATH") || "").replace(/\\/g, "/")
  readonly property string configHome: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")).replace(/\\/g, "/")

  // Windows port: the engine does not re-run a binding when a FileView finishes loading, so every
  // read below also depends on `rev`, which each FileView bumps when it loads or changes, and on the
  // FileView's path, which binds after these do on creation.
  property int rev: 0
  // Reading text() on a missing file retries the load and fails again. Bumping rev on every failure
  // would re-run the bindings that read it, forever, so a failure only counts once per path.
  property var failedPaths: ({})
  function bump(): void { root.rev++ }
  function fileLoaded(key: string): void {
    I18nUtils.clearFailure(root.failedPaths, key)
    Qt.callLater(root.bump)
  }
  function fileFailed(key: string, path: string): void {
    if (root.failedPaths[key] === path) return
    root.failedPaths[key] = path
    Qt.callLater(root.bump)
  }
  readonly property string language: readLanguage(root.rev, languageFile.path, I18nUtils.fileText(languageFile))
  readonly property var localeSettings: readCatalog(root.rev, registryFile.path, I18nUtils.fileText(registryFile))[root.language] || ({})
  readonly property string formatLocale: I18nUtils.localeField(root.localeSettings, "formatLocale", "en-US")
  // From the registry: how numbers are written and which way text runs.
  readonly property string decimal: I18nUtils.localeField(root.localeSettings, "decimal", ".")
  readonly property string zeroDigit: I18nUtils.localeField(root.localeSettings, "zeroDigit", "0")
  readonly property bool rightToLeft: I18nUtils.localeField(root.localeSettings, "direction", "") === "rtl"

  // Reading text() makes blockLoading take effect on the first lookup.
  // These bindings also rebuild the maps when a watched catalog changes.
  readonly property var englishStrings: readCatalog(root.rev, englishCatalogFile.path, I18nUtils.fileText(englishCatalogFile))
  readonly property var languageStrings: readCatalog(root.rev, languageCatalogFile.path, I18nUtils.fileText(languageCatalogFile))
  readonly property var strings: {
    var merged = ({})
    for (let k in root.englishStrings) merged[k] = root.englishStrings[k]
    for (let k2 in root.languageStrings) merged[k2] = root.languageStrings[k2]
    return merged
  }

  // Model callbacks preserve optional fallback and decimal arguments through these helpers.
  function translator(): var { return I18nUtils.translator(root) }
  function pluralTranslator(): var { return I18nUtils.pluralTranslator(root) }
  function numberFormatter(): var { return I18nUtils.numberFormatter(root) }

  function t(key: var): string {
    return I18nUtils.translate(root, key, undefined)
  }

  function tn(key: var, count: var): string {
    return I18nUtils.translatePlural(root, key, count, undefined)
  }

  function formatNumber(value: var): string {
    return I18nUtils.formatNumber(root, value, undefined)
  }

  function formatNumberWithDecimals(value: var, decimals: var): string {
    return I18nUtils.formatNumber(root, value, decimals)
  }

  function parseCatalog(raw: var): var { return Catalog.parse(raw) }
  function readCatalog(revision: int, path: var, raw: var): var { return Catalog.parse(raw) }
  function readLanguage(revision: int, path: var, raw: var): string { return languageCode(raw) }

  function languageCode(raw: var): string {
    var code = String(raw || "").trim()
    if (!/^[a-z]{2,3}(-[A-Za-z]{2})?$/.test(code)) code = "en"
    return code
  }

  // The catalogs are small local files, read synchronously so the first
  // binding to call t() already gets the string rather than the raw key.
  property FileView languageFile: FileView {
    // NOMARCHY_LANGUAGE_FILE overrides the location, as it does for
    // nomarchy-i18n, so tests can pin a language whatever the machine uses.
    path: Quickshell.env("NOMARCHY_LANGUAGE_FILE") || (root.configHome + "/nomarchy/language")
    watchChanges: true
    printErrors: false
    blockLoading: true
    onFileChanged: reload()
    onLoaded: root.fileLoaded("languageFile")
    onLoadFailed: root.fileFailed("languageFile", String(root.languageFile.path))
  }

  property FileView englishCatalogFile: FileView {
    path: root.nomarchyPath + "/default/i18n/en/shell.json"
    watchChanges: true
    printErrors: false
    blockLoading: true
    onFileChanged: reload()
    onLoaded: root.fileLoaded("englishCatalogFile")
    onLoadFailed: root.fileFailed("englishCatalogFile", String(root.englishCatalogFile.path))
  }

  property FileView languageCatalogFile: FileView {
    path: root.nomarchyPath + "/default/i18n/" + root.language + "/shell.json"
    watchChanges: true
    printErrors: false
    blockLoading: true
    onFileChanged: reload()
    onLoaded: root.fileLoaded("languageCatalogFile")
    onLoadFailed: root.fileFailed("languageCatalogFile", String(root.languageCatalogFile.path))
  }

  property FileView registryFile: FileView {
    path: root.nomarchyPath + "/default/i18n/locales.json"
    watchChanges: true
    printErrors: false
    blockLoading: true
    onFileChanged: reload()
    onLoaded: root.fileLoaded("registryFile")
    onLoadFailed: root.fileFailed("registryFile", String(root.registryFile.path))
  }
}
