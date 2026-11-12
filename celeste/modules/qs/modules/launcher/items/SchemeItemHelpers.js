.pragma library

function select(model, list) { if (model) model.onClicked(list); }
function colour(model, property) {
    return model && model.colours && model.colours[property] ? model.colours[property] : "transparent";
}
function flavour(model) { return model && model.flavour ? model.flavour : ""; }
function name(model) { return model && model.name ? model.name : ""; }
function isCurrent(model, currentScheme) { return model && (name(model) + " " + flavour(model)) === currentScheme; }
