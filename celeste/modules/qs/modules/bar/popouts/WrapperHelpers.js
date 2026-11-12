.pragma library

function activeWidth(children, fallback) {
    for (let i = 0; i < children.length; i++) {
        if (children[i].shouldBeActive)
            return children[i].implicitWidth;
    }
    return fallback;
}
function activeHeight(children, fallback) {
    for (let i = 0; i < children.length; i++) {
        if (children[i].shouldBeActive)
            return children[i].implicitHeight;
    }
    return fallback;
}
function closePassword(name, loaderItem) {
    if (name !== "wirelesspassword" || !loaderItem)
        return false;
    const children = loaderItem.children;
    for (let i = 0; i < children.length; i++) {
        if (children[i].name === "wirelesspassword" && children[i].item) {
            children[i].item.closeDialog();
            return true;
        }
    }
    return false;
}
