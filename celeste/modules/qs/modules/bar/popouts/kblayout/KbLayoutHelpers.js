.pragma library

function buildXmlMap(model, xml, tr, layouts, fetchActive) {
    const map = {};
    const expression = /<name>\s*([^<]+?)\s*<\/name>[\s\S]*?<description>\s*([^<]+?)\s*<\/description>/g;
    let match;
    while ((match = expression.exec(xml)) !== null) {
        const code = (match[1] || "").trim();
        const description = (match[2] || "").trim();
        if (code && description)
            map[code] = short(description, tr);
    }
    if (Object.keys(map).length === 0)
        return;
    model._xkbMap = map;
    if (layouts.count === 0)
        return;
    const temporary = [];
    for (let i = 0; i < layouts.count; i++) {
        const item = layouts.get(i);
        temporary.push({
            layoutIndex: item.layoutIndex,
            token: item.token,
            label: pretty(map, item.token, tr)
        });
    }
    layouts.clear();
    for (let i = 0; i < temporary.length; i++)
        layouts.append(temporary[i]);
    fetchActive.running = true;
}

function short(description, tr) {
    const match = description.match(/^(.*)\((.*)\)$/);
    if (!match)
        return description;
    const language = match[1].trim();
    const region = match[2].trim();
    const code = (region.split(/[,\s-]/)[0] || region).slice(0, 2).toUpperCase();
    return tr.trCtx("%1 (%2)", "keyboard layout language and code").arg(language).arg(code);
}

function setLayouts(model, raw, layouts, tr) {
    const parts = raw.split(",").map(function (part) { return part.trim(); }).filter(Boolean);
    layouts.clear();
    const seen = {};
    let index = 0;
    for (let i = 0; i < parts.length; i++) {
        const token = parts[i];
        if (seen[token])
            continue;
        seen[token] = true;
        layouts.append({
            layoutIndex: index,
            token: token,
            label: pretty(model._xkbMap, token, tr)
        });
        index++;
    }
}

function rebuildVisible(model, visible, layouts, config, toaster, tr) {
    visible.clear();
    for (let i = 0; i < layouts.count; i++) {
        const item = layouts.get(i);
        if (item.layoutIndex !== model.activeIndex)
            visible.append(item);
    }
    if (config.utilities.toasts.kbLimit && layouts.count > 4)
        toaster.toast(tr.tr("Keyboard layout limit"), tr.tr("XKB supports only 4 layouts at a time"), "warning", 0, 5000);
}

function pretty(xkbMap, token, tr) {
    const code = token.replace(/\(.*\)$/, "").trim();
    const name = xkbMap[code] || code;
    return tr.trCtx("%1 - %2", "keyboard layout code and name").arg(code.toUpperCase()).arg(name);
}

function readLayoutOption(text, model, fetchActive, fetchDevices) {
    try {
        const option = JSON.parse(text);
        const raw = (option.str || option.value || "").toString().trim();
        if (raw.length) {
            model._setLayouts(raw);
            fetchActive.running = true;
            return;
        }
    } catch (error) {
    }
    fetchDevices.running = true;
}

function readDeviceLayouts(text, model, fetchActive) {
    try {
        const devices = JSON.parse(text);
        const keyboards = devices.keyboards || [];
        let keyboard = keyboards.length ? keyboards[0] : null;
        for (let i = 0; i < keyboards.length; i++) {
            if (keyboards[i].main) {
                keyboard = keyboards[i];
                break;
            }
        }
        const raw = (keyboard && keyboard.layout || "").trim();
        if (raw.length)
            model._setLayouts(raw);
    } catch (error) {
    }
    fetchActive.running = true;
}

function readActiveLayout(text, model, layouts) {
    try {
        const devices = JSON.parse(text);
        const keyboards = devices.keyboards || [];
        let keyboard = keyboards.length ? keyboards[0] : null;
        for (let i = 0; i < keyboards.length; i++) {
            if (keyboards[i].main) {
                keyboard = keyboards[i];
                break;
            }
        }
        const index = keyboard ? keyboard.active_layout_index : -1;
        model.activeIndex = index >= 0 ? index : -1;
        model.activeLabel = index >= 0 && index < layouts.count ? layouts.get(index).label : "";
    } catch (error) {
        model.activeIndex = -1;
        model.activeLabel = "";
    }
    model._rebuildVisible();
}

function count(model) { return model.count; }
