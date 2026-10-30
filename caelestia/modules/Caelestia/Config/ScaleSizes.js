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

// A plain object shaped like `src` with every named token times `k`, rounded to a whole pixel (at
// least 1 for a non-zero token). Reads from `src` inside a binding keep the binding live.
function scaleSizes(src, k) {
    const res = {};
    for (const g in spec) {
        const from = src[g];
        const to = {};
        for (const name of spec[g]) {
            const v = from[name];
            to[name] = v === 0 ? 0 : Math.max(1, Math.round(v * k));
        }
        for (const name of keep[g] ?? [])
            to[name] = from[name];
        res[g] = to;
    }
    return res;
}
