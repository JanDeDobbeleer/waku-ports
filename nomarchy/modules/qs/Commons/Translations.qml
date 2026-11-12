import QtQuick
import Quickshell.Io
import "Catalog.js" as Catalog
import "I18nUtils.js" as I18nUtils

// Strings for a plugin that ships its own catalogs, following the language
// picked under Setup > Language the same way the shell's I18n does. Point it
// at a directory of flat JSON catalogs, one per registry code (en.json,
// da.json, pt-BR.json, ...):
//
//   Commons.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }
//   Text { text: strings.t("panel.title") }
//   Text { text: strings.tn("panel.items", count).arg(Commons.I18n.formatNumber(count)) }
//
// A catalog value is a string, or an object of plural forms keyed by CLDR
// category ({"one": "%1 item", "other": "%1 items"}) for strings that count.
//
// A string missing from the current language falls back to its base
// language (pt-BR to pt), then to en.json, then to the key itself, so a
// plugin can ship English alone and gain languages one file at a time.
// Switching language re-renders bindings that call t() without a restart.
QtObject {
  id: root

  // A filesystem path or file:// URL (Qt.resolvedUrl("i18n") from the plugin).
  property var directory: ""

  readonly property string language: I18n.language
  readonly property string baseLanguage: language.split("-")[0]
  readonly property string directoryPath: String(directory).replace(/^file:\/\//, "").replace(/\/+$/, "")

  // Read through FileView so blockLoading applies to the first lookup, and
  // keep the maps bound to the watched files for subsequent updates.
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
  readonly property var englishStrings: readCatalog(root.rev, I18nUtils.fileText(englishFile))
  readonly property var baseStrings: readCatalog(root.rev, I18nUtils.fileText(baseFile))
  readonly property var languageStrings: readCatalog(root.rev, I18nUtils.fileText(languageFile))
  readonly property var strings: {
    var merged = ({})
    var layers = [root.englishStrings, root.baseStrings, root.languageStrings]
    for (let i = 0; i < layers.length; i++)
      for (let key in layers[i])
        if (typeof layers[i][key] === "string" || (layers[i][key] && typeof layers[i][key] === "object")) merged[key] = layers[i][key]
    return merged
  }

  // Model callbacks can supply an optional fallback through these helpers.
  function translator(): var { return I18nUtils.translator(root) }
  function pluralTranslator(): var { return I18nUtils.layeredPluralTranslator(root) }

  function t(key: var): string {
    return I18nUtils.translate(root, key, undefined)
  }

  function tn(key: var, count: var): string {
    return I18nUtils.translateLayeredPlural(root, key, count, undefined)
  }

  function parseCatalog(raw: var): var { return Catalog.parse(raw) }
  function readCatalog(revision: int, raw: var): var { return Catalog.parse(raw) }

  function catalogPath(code: string): string {
    return root.directoryPath !== "" ? root.directoryPath + "/" + code + ".json" : ""
  }

  property FileView englishFile: FileView {
    path: root.catalogPath("en")
    watchChanges: true
    printErrors: false
    blockLoading: true
    onFileChanged: reload()
    onLoaded: root.fileLoaded("englishFile")
    onLoadFailed: root.fileFailed("englishFile", String(root.englishFile.path))
  }

  // Only read for a regional code; for "da" the language file covers it.
  property FileView baseFile: FileView {
    path: root.baseLanguage !== root.language && root.baseLanguage !== "en" ? root.catalogPath(root.baseLanguage) : ""
    watchChanges: true
    printErrors: false
    blockLoading: true
    onFileChanged: reload()
    onLoaded: root.fileLoaded("baseFile")
    onLoadFailed: root.fileFailed("baseFile", String(root.baseFile.path))
  }

  property FileView languageFile: FileView {
    path: root.language !== "en" ? root.catalogPath(root.language) : ""
    watchChanges: true
    printErrors: false
    blockLoading: true
    onFileChanged: reload()
    onLoaded: root.fileLoaded("languageFile")
    onLoadFailed: root.fileFailed("languageFile", String(root.languageFile.path))
  }
}
