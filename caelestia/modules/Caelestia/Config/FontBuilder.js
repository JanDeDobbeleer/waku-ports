.pragma library

// JS port of upstream's FontBuilder value type. Every call returns a new builder, so a style's
// shared builder is never changed. build() returns a QML font (Qt.font with variableAxes, which
// needs wabar's --font-engine=directwrite to take effect).

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
    const scaled = Math.trunc(cfg.size * scale);
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
