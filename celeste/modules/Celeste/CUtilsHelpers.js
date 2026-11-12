.pragma library

function saveItem(root, target, path, arg3, arg4, arg5) {
    let onSaved;
    let onFailed;
    if (typeof arg3 === "function") {
        onSaved = arg3;
        onFailed = arg4;
    } else {
        onSaved = arg4;
        onFailed = arg5;
    }
    if (!target) {
        console.warn("CUtils.saveItem: a target is required");
        return;
    }
    const file = root.toLocalFile(path);
    if (!file) {
        console.warn("CUtils.saveItem:", path, "is not a local file");
        return;
    }
    const success = target.grabToImage(function (result) {
        if (result.saveToFile(file)) {
            if (onSaved)
                onSaved(file);
        } else {
            console.warn("CUtils.saveItem: failed to save", file);
            if (onFailed)
                onFailed(file);
        }
    });
    if (!success)
        console.warn("CUtils.saveItem: failed to grab", target);
}

function copyFile(root, source, target, overwrite) {
    const src = root.toLocalFile(source);
    const dst = root.toLocalFile(target);
    if (!src || !dst)
        return false;
    const shouldOverwrite = overwrite === undefined ? true : overwrite;
    runCommand(root, root.proc, ["cmd.exe", "/c", "copy", shouldOverwrite ? "/Y" : "/-Y", src.replace(/\//g, "\\"), dst.replace(/\//g, "\\")]);
    return true;
}

function deleteFile(root, path) {
    const file = root.toLocalFile(path);
    if (!file)
        return false;
    runCommand(root, root.proc, ["cmd.exe", "/c", "del", "/F", "/Q", file.replace(/\//g, "\\")]);
    return true;
}

function findChild(item, name) {
    return find(item, function (child) { return child.objectName === name; }, null);
}

function findChildren(item, name) {
    const result = [];
    find(item, function (child) { return child.objectName === name; }, result);
    return result;
}

function findChildrenMatching(item, pattern) {
    const expression = new RegExp(pattern);
    const result = [];
    find(item, function (child) { return expression.test(child.objectName); }, result);
    return result;
}

function find(item, matches, result) {
    if (!item)
        return result ? result : null;
    const children = item.children;
    for (let i = 0; i < children.length; i++) {
        const child = children[i];
        if (matches(child)) {
            if (!result)
                return child;
            result.push(child);
        }
        const found = find(child, matches, result);
        if (!result && found)
            return found;
    }
    return result ? result : null;
}

function runCommand(root, component, command) {
    const process = component.createObject(root, { command: command });
    process.running = true;
}
