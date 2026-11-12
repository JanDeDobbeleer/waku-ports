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
