.pragma library

function translate(i18n, key) { return i18n.t(key) }
function translatePlural(i18n, key, count) { return i18n.tn(key, count) }
function formatNumber(i18n, value) { return i18n.formatNumber(value) }
function value(i18n, key) { return i18n[key] }
