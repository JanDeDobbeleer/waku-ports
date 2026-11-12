.pragma library

// qmlcachegen cannot compile reads from plain objects, for...of or destructuring, so the
// scheme handling lives here.

// Copies a name -> colour map (ColorScheme.colors, or the `colours` of a scheme.json with hex
// strings) onto a palette, adding the `m3` prefix.
function applyColours(colours, target) {
    for (const [name, colour] of Object.entries(colours)) {
        const propName = name.startsWith("term") ? name : `m3${name}`;
        if (target.hasOwnProperty(propName))
            target[propName] = colour;
    }
}

function applyScheme(scheme, target) {
    if (!scheme || !scheme.valid)
        return;
    applyColours(scheme.colors, target);
}

function isDark(scheme) {
    return scheme.dark;
}

// Loads a scheme.json as the `celeste scheme` CLI writes it.
function load(data, isPreview, root, colours) {
    const scheme = JSON.parse(data);

    if (!isPreview) {
        root.scheme = scheme.name;
        root.flavour = scheme.flavour;
        root.currentLight = scheme.mode === "light";
    } else {
        root.previewLight = scheme.mode === "light";
    }

    const mapped = {};
    for (const [name, colour] of Object.entries(scheme.colours))
        mapped[name] = `#${colour}`;
    applyColours(mapped, colours);
}
