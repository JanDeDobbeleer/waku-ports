.pragma library

function updateMonitors(monitors, name, checked) {
  const next = (monitors || []).slice();
  if (checked) {
    if (next.indexOf(name) === -1)
      next.push(name);
    return next;
  }
  const filtered = [];
  for (let i = 0; i < next.length; i++) {
    if (next[i] !== name)
      filtered.push(next[i]);
  }
  return filtered;
}
