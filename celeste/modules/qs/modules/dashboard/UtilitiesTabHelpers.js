.pragma library

function groupItems(actions, group) { return actions.inGroup(group.id); }
function hasItems(items) { return items.length > 0; }
function label(item) { return item.label; }
function icon(item) { return item.icon; }
function launch(actions, item) { actions.launch(item.id); }
