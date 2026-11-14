.pragma library

function field(object, key) { return object ? object[key] : undefined }
function windowContentItem(window) { return window ? window.contentItem : null }
function arrayLength(value) { return value ? value.length : 0 }
function arrayAt(value, index) { return value ? value[index] : undefined }
function arrayFrom(value) {
  if (!value || typeof value.length !== "number" || typeof value === "string") return []
  var output = []
  for (var i = 0; i < value.length; i++) output.push(value[i])
  return output
}
function normalizeOption(option) {
  if (option && typeof option === "object") {
    var value = field(option, "value")
    var label = field(option, "label")
    var description = field(option, "description")
    return { value: String(value), label: String(label !== undefined ? label : value), description: description ? String(description) : "" }
  }
  var text = String(option)
  return { value: text, label: text, description: "" }
}
function normalizeAll(values) {
  var output = []
  var source = arrayFrom(values)
  var seen = {}
  for (var i = 0; i < source.length; i++) {
    var option = normalizeOption(source[i])
    if (!option.value || seen[option.value]) continue
    seen[option.value] = true
    output.push(option)
  }
  return output
}
function valueSet(values) {
  var result = {}
  var source = arrayFrom(values)
  for (var i = 0; i < source.length; i++) result[String(source[i])] = true
  return result
}
function selectionLabel(values, options, i18n) {
  var selected = arrayFrom(values)
  if (!selected.length) return ""
  var labels = []
  var byValue = {}
  for (var i = 0; i < arrayLength(options); i++) {
    var option = options[i]
    byValue[field(option, "value")] = field(option, "label")
  }
  for (var j = 0; j < selected.length; j++) labels.push(byValue[String(selected[j])] || String(selected[j]))
  if (labels.length <= 3) return labels.join(", ")
  return i18n.tn("multiSelect.selectedCount", selected.length).arg(i18n.formatNumber(selected.length))
}
function filteredOptions(options, query) {
  var q = String(query || "").toLowerCase()
  if (!q) return options
  var output = []
  for (var i = 0; i < arrayLength(options); i++) {
    var option = options[i]
    if (String(field(option, "label")).toLowerCase().indexOf(q) !== -1
        || String(field(option, "description")).toLowerCase().indexOf(q) !== -1
        || String(field(option, "value")).toLowerCase().indexOf(q) !== -1) output.push(option)
  }
  return output
}
function parseCommandOutput(raw, invalidJson) {
  var text = String(raw || "").trim()
  if (!text) return [[], ""]
  if (text.charAt(0) === "[") {
    try { return [JSON.parse(text), ""] } catch (error) { return [[], invalidJson] }
  }
  var output = []
  var lines = text.split(/\r?\n/)
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i].trim()
    if (line) output.push(line)
  }
  return [output, ""]
}
