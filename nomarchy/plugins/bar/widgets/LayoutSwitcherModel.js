.pragma library

function label(names, layoutName) {
  var info = names[layoutName] || { label: layoutName }
  return String(info.label)
}

function title(names, layoutName) {
  var info = names[layoutName] || { title: layoutName }
  return String(info.title)
}
