.pragma library

function value(object, key) {
  return object == null ? undefined : object[key]
}

function localAddRecipes(localRecipes, localModel) {
  var models = localModel && localModel.models ? localModel.models : {}
  var recipes = (localRecipes || []).filter(function(recipe) {
    return recipe && recipe.available && !models[recipe.id]
  })
  recipes.sort(function(a, b) { return (b.best ? 1 : 0) - (a.best ? 1 : 0) })
  return recipes
}

function parseRecord(raw) {
  try {
    var parsed = JSON.parse(String(raw || ""))
    return { ok: true, record: parsed && typeof parsed === "object" ? parsed : null }
  } catch (e) {
    return { ok: false, record: null }
  }
}

function call(receiver, method, args) {
  var callback = value(receiver, method)
  return typeof callback === "function" ? callback.apply(receiver, args || []) : undefined
}

function setValue(receiver, name, valueToSet) {
  if (receiver) receiver[name] = valueToSet
}
