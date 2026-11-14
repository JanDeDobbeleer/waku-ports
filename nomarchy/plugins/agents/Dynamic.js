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

function buildKeyRows(addButtonShown, picking, addStage, addProviders, localAddRecipes, providers, blankSlate, starterPrompts, root) {
  var rows = []
  var hero = []
  if (addButtonShown) hero.push({ kind: "add", index: 0 })
  if (hero.length > 0) rows.push(hero)
  if (picking) {
    var choices = []
    for (var k = 0; k < value(addProviders, "length"); k++) choices.push({ kind: "choice", index: k })
    rows.push(choices)
  } else if (addStage === "local") {
    for (var r = 0; r < value(localAddRecipes, "length"); r++) rows.push([{ kind: "localAdd", index: r }])
  } else if (addStage === "") {
    var entry = 0
    for (var p = 0; p < value(providers, "length"); p++) {
      var provider = providers[p]
      var localModel = value(provider, "localModel")
      if (localModel) {
        var actions = call(root, "localActions", [localModel])
        rows.push(value(actions, "length") > 0
          ? actions.map(function(action) { return { kind: action === "toggle" ? "modelToggle" : "modelLaunch", index: p } })
          : [{ kind: "modelHeader", index: p }])
        continue
      }
      rows.push([{ kind: call(root, "lineStop", [p]), index: p }])
      var accounts = call(root, "providerAccounts", [provider])
      if (value(accounts, "length") < 2) {
        if (call(root, "needsSignIn", [provider])) rows.push([{ kind: "providerSignin", index: p }])
        continue
      }
      for (var a = 0; a < value(accounts, "length"); a++, entry++) {
        var row = []
        if (call(root, "needsSignIn", [accounts[a]])) row.push({ kind: "signin", index: entry })
        if (!value(accounts[a], "active")) {
          row.push({ kind: "autoswitch", index: entry })
          row.push({ kind: "account", index: entry })
        }
        if (row.length > 0) rows.push(row)
      }
    }
    if (!blankSlate) {
      var tiles = []
      for (var j = 0; j < value(starterPrompts, "length"); j++) tiles.push({ kind: "starter", index: j })
      rows.push(tiles)
    }
  }
  return rows
}

function pointAtCallback(root, index) {
  return function() { call(root, "pointAt", [call(root, "lineStop", [index]), index]) }
}
