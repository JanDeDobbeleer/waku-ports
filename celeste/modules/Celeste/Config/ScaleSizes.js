.pragma library

// Names of the size tokens in TokenConfig.sizes that Tokens multiplies by `scale`. Generated from
// TokenConfig.qml; the angle (mediaProgressSweep) and the ratios (heightMult, ratio) are not sizes.

var spec = {
    bar: ["innerWidth", "windowPreviewSize", "trayMenuWidth", "batteryWidth", "networkWidth", "audioWidth", "kbLayoutWidth"],
    dashboard: ["tabIndicatorHeight", "tabIndicatorSpacing", "userWidth", "logoSize", "uptimeSize", "dateTimeWidth", "mediaWidth", "mediaProgressThickness", "resourceProgressThickness", "weatherWidth", "mediaCoverArtSize", "mediaTabWidth", "mediaTabHeight", "mediaSectionWidth", "perfHeroCardWidth", "perfUsageShapeSize", "perfStorageTextWidth", "perfNetworkCardWidth", "perfNetworkCardHeight", "perfBattWidth", "perfBattWidthSingle", "perfBattHeight", "perfPlaceholderWidth"],
    launcher: ["itemWidth", "itemHeight", "wallpaperWidth", "wallpaperHeight"],
    notifs: ["width", "image", "badge"],
    osd: ["sliderWidth", "sliderHeight"],
    session: ["button"],
    sidebar: ["width"],
    utilities: ["width", "toastWidth"],
    lock: ["centerWidth", "showWeatherDetailsHeight", "showForecastHeight", "forecastItemWidth", "largeLogoWidth", "largeFontWidth", "fetch4LinesHeight", "fetch3LinesHeight", "showColourBoxRowHeight"],
    winfo: ["detailsWidth"],
    nexus: ["minWidth", "minHeight", "maxNavWidth", "maxContentWidth", "popupWidth", "minPopupHeight", "maxPopupHeight", "networkShowEthDetailWidth", "networkShowVpnDetailWidth", "maxDialogWidth", "maxDialogHeight", "textFieldWidth", "smallTextFieldWidth"]
};

// Tokens copied unchanged.
var keep = {
    dashboard: ["mediaProgressSweep"],
    lock: ["heightMult", "ratio"],
    winfo: ["heightMult"],
    nexus: ["heightMult", "ratio"]
};

// One panel size token times `k`, rounded like scaleSizes.
function sized(src, g, name, k) {
    const v = src[g][name];
    return v === 0 ? 0 : Math.max(1, Math.round(v * k));
}

// One panel token copied unchanged.
function kept(src, g, name) {
    return src[g][name];
}

// A nested value of `obj` by dotted path, such as get(appearance, "font.scale").
function get(obj, path) {
    let v = obj;
    const parts = path.split(".");
    for (let i = 0; i < parts.length; i++)
        v = v[parts[i]];
    return v;
}

// A size token of a rounding/spacing/padding source times `k`, truncated to an int.
function truncScaled(source, name, k) {
    return Math.trunc(source[name] * k);
}

// The devicePixelRatio of the first screen, or 1 without one.
function primaryDpr() {
    return Qt.application.screens.length > 0 ? Qt.application.screens[0].devicePixelRatio : 1;
}
