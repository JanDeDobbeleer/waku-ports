.pragma library

// JS port of upstream's FontBuilder value type. Every call returns a new builder, so a style's
// shared builder is never changed. build() returns a QML font (Qt.font with variableAxes, which
// needs waku's --font-engine=directwrite to take effect).

function _clone(s) {
    return {
        family: s.family,
        pointSize: s.pointSize,
        weight: s.weight,
        italic: s.italic,
        letterSpacing: s.letterSpacing,
        capitalization: s.capitalization,
        axes: Object.assign({}, s.axes)
    };
}

function _toFont(s) {
    const spec = {
        family: s.family,
        pointSize: s.pointSize,
        weight: s.weight,
        italic: s.italic,
        variableAxes: Object.assign({}, s.axes)
    };
    if (s.letterSpacing !== undefined)
        spec.letterSpacing = s.letterSpacing;
    if (s.capitalization !== undefined)
        spec.capitalization = s.capitalization;
    return Qt.font(spec);
}

function _builder(state) {
    const upd = fn => {
        const c = _clone(state);
        fn(c);
        return _builder(c);
    };
    const self = {
        family: v => upd(c => {
            c.family = v;
        }),
        size: v => upd(c => {
            const n = v <= 0 ? 1 : Math.trunc(v);
            c.pointSize = n;
            c.axes.opsz = n;
        }),
        weight: v => upd(c => {
            c.weight = v;
            c.axes.wght = v;
        }),
        italic: (on = true) => upd(c => {
            c.italic = on;
        }),
        // QML fonts have no stretch; the call is accepted and ignored.
        stretch: v => self,
        // Percentage spacing has no QML equivalent; only absolute (pixel) spacing applies.
        letterSpacing: (spacing, absolute = true) => absolute ? upd(c => {
            c.letterSpacing = spacing;
        }) : self,
        capitalisation: v => upd(c => {
            c.capitalization = v;
        }),
        vaxis: (tag, v) => upd(c => {
            c.axes[tag] = v;
        }),
        vaxes: map => upd(c => {
            for (const k in map)
                c.axes[k] = Number(map[k]);
        }),
        fill: v => self.vaxis("FILL", v),
        grade: v => self.vaxis("GRAD", v),
        width: v => self.vaxis("wdth", v),
        scale: f => self.size(Math.trunc(state.pointSize * f)),
        build: () => _toFont(state)
    };
    return self;
}

// Builder from plain values (the family, point size, weight and so on).
function make(family, pointSize, weight, italic, axes) {
    return _builder({
        family: family,
        pointSize: pointSize,
        weight: weight,
        italic: italic,
        letterSpacing: undefined,
        capitalization: undefined,
        axes: Object.assign({}, axes)
    });
}

// Builder from one FontConfig node (family, size, weight, italic, vaxes), like upstream's
// FontStyleBase::buildFont: the size is scaled and capped at 1, the opsz and wght axes follow the
// size and weight, then the configured axes apply on top.
function fromConfig(cfg, fallbackFamily, scale) {
    const scaled = Math.round(cfg.size * scale);
    const size = scaled > 0 ? scaled : 1;
    const axes = {
        opsz: size,
        wght: cfg.weight
    };
    const v = cfg.vaxes;
    if (v)
        for (const k in v)
            axes[k] = Number(v[k]);
    return make(cfg.family ? cfg.family : fallbackFamily, size, cfg.weight, cfg.italic, axes);
}

function fontFromConfig(cfg, fallbackFamily, scale) {
    return fromConfig(cfg, fallbackFamily, scale).build();
}

// Applies the options of a call like `Tokens.font.body.styled("small", {weight: Font.Bold})` to a
// builder. Options: size, scale (a factor or a list of factors, applied one after the other), weight, italic, width, fill, grade, capitalisation,
// letterSpacing and vaxis ([tag, value]).
function _apply(b, ops) {
    let r = b;
    if (ops.size !== undefined)
        r = r.size(ops.size);
    if (ops.scale !== undefined)
        for (const f of [].concat(ops.scale))
            r = r.scale(f);
    if (ops.weight !== undefined)
        r = r.weight(ops.weight);
    if (ops.italic !== undefined)
        r = r.italic(ops.italic);
    if (ops.vaxes !== undefined)
        r = r.vaxes(ops.vaxes);
    if (ops.width !== undefined)
        r = r.width(ops.width);
    if (ops.fill !== undefined)
        r = r.fill(ops.fill);
    if (ops.grade !== undefined)
        r = r.grade(ops.grade);
    if (ops.capitalisation !== undefined)
        r = r.capitalisation(ops.capitalisation);
    if (ops.letterSpacing !== undefined)
        r = r.letterSpacing(ops.letterSpacing);
    if (ops.vaxis !== undefined)
        r = r.vaxis(ops.vaxis[0], ops.vaxis[1]);
    return r;
}

// The font of one size ("small", "medium", "large", "extraLarge") of a TokenFontStyle with the
// options applied.
function styled(style, name, ops) {
    const cfg = style.cfg;
    const c = name === "extraLarge" ? (cfg.extraLarge ?? cfg.large) : cfg[name];
    return _apply(fromConfig(c, cfg.family, style.scale), ops).build();
}

// The same for a plain builder from make(), like the clock font.
function builtFrom(builder, ops) {
    return _apply(builder, ops).build();
}

// The font of one size of a font style config ("large", "medium", "small", "extraLarge").
function sizeFont(cfg, name, scale) {
    const c = name === "extraLarge" ? (cfg.extraLarge ?? cfg.large) : cfg[name];
    return fromConfig(c, cfg.family, scale).build();
}
