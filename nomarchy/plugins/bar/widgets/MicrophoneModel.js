.pragma library

function length(values) { return Array.from(values || []).length }

function translate(i18n, key) { return i18n.t(key) }
