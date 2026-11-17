.pragma library

function icon(names, layoutName) {
  var info = names[layoutName]
  return info ? String(info.icon) : "\ue871"
}

function title(names, layoutName) {
  var info = names[layoutName] || { title: layoutName }
  return String(info.title)
}
