.pragma library

function filter(allIcons, query) {
  if (query === "") return allIcons;
  const q = query.toLowerCase();
  return allIcons.filter(name => name.toLowerCase().includes(q));
}
