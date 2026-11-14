.pragma library

function update(root, data) {
  try { root.state = JSON.parse(data) } catch (e) {}
}
