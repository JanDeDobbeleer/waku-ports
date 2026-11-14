.pragma library

function selector(item) { return item.name + " " + item.flavour; }

function coloursOf(scheme) {
    const result = {};
    const source = scheme && scheme.colors ? scheme.colors : {};
    result.surface = source.surface || "transparent";
    result.primary = source.primary || "transparent";
    result.outline = source.outline || "transparent";
    return result;
}

function build(seeds, current, colorScheme, flavour, isLight) {
    const flat = [{
        name: "dynamic",
        flavour: "wallpaper",
        colours: {
            surface: current.m3surface,
            primary: current.m3primary,
            outline: current.m3outline
        }
    }];
    const flavours = Object.keys(seeds);
    for (let i = 0; i < flavours.length; i++) {
        const name = flavours[i];
        const seed = seeds[name];
        flat.push({
            name: "material",
            flavour: name,
            seed: seed,
            colours: coloursOf(colorScheme.fromColor(seed, flavour, isLight))
        });
    }
    return flat;
}

function name(model) { return model && model.name ? model.name : ""; }
function flavour(model) { return model && model.flavour ? model.flavour : ""; }
function colours(model) { return model && model.colours ? model.colours : {}; }
function select(name, flavour, colours, toaster, translation, toastType) {
    colours.scheme = name;
    colours.seed = name === "dynamic" ? "wallpaper" : flavour;
    colours.regenerate(false);
    toaster.toast(translation.tr("Colour scheme changed"), name + " " + flavour, "palette", toastType, 2500);
}

function clicked(list, name, flavour, colours, toaster, translation, toastType) {
    list.screenState.launcher = false;
    select(name, flavour, colours, toaster, translation, toastType);
}
