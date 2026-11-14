.pragma library

function enabledTabs(tabs) {
    const result = [];
    for (let i = 0; i < tabs.length; i++) {
        if (tabs[i].enabled)
            result.push(tabs[i]);
    }
    return result;
}
function itemWidth(item) { return item ? item.implicitWidth : 0; }
function itemHeight(item) { return item ? item.implicitHeight : 0; }
function component(tab) { return tab.component; }
function contentXBinding(qt, view) {
    return qt.binding(function() { return view.currentItem ? view.currentItem.x : 0; });
}
