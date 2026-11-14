.pragma library
.import "Plural.js" as Plural
.import "Numbers.js" as Numbers

function localeField(locale, key, fallback) {
  var value = locale && locale[key]
  return value === undefined || value === null || value === "" ? fallback : value
}

function fileText(file) { return file.text() }
function clearFailure(paths, key) { delete paths[key] }

function translate(root, key, fallback) {
  var value = root.strings[key]
  if (value && typeof value === "object") value = value.other
  if (typeof value === "string" && value.length > 0) return value
  return fallback !== undefined ? fallback : key
}

function translatePlural(root, key, count, fallback) {
  var value = Plural.pick(root.languageStrings[key], root.language, count)
  if (typeof value !== "string" || value.length === 0) value = Plural.pick(root.englishStrings[key], "en", count)
  if (typeof value === "string" && value.length > 0) return value
  return fallback !== undefined ? fallback : key
}

function translateLayeredPlural(root, key, count, fallback) {
  var layers = [[root.languageStrings, root.language], [root.baseStrings, root.baseLanguage], [root.englishStrings, "en"]]
  for (var i = 0; i < layers.length; i++) {
    var value = Plural.pick(layers[i][0][key], layers[i][1], count)
    if (typeof value === "string" && value.length > 0) return value
  }
  return fallback !== undefined ? fallback : key
}

function formatNumber(root, value, decimals) {
  return Numbers.format(value, decimals, root.decimal, root.zeroDigit)
}

function translator(root) {
  return function(key, fallback) { return translate(root, key, fallback) }
}

function pluralTranslator(root) {
  return function(key, count, fallback) { return translatePlural(root, key, count, fallback) }
}

function layeredPluralTranslator(root) {
  return function(key, count, fallback) { return translateLayeredPlural(root, key, count, fallback) }
}

function numberFormatter(root) {
  return function(value, decimals) { return formatNumber(root, value, decimals) }
}
