.pragma library

function updateFirstLast(tabRow) {
  if (!tabRow || !tabRow.children) return;
  const kids = tabRow.children;
  const len = kids.length;
  let firstVisible = -1;
  let lastVisible = -1;
  for (let i = 0; i < len; i++) {
    const child = kids[i];
    if (child.visible && "isFirst" in child) {
      if (firstVisible === -1) firstVisible = i;
      lastVisible = i;
    }
  }
  for (let i = 0; i < len; i++) {
    const child = kids[i];
    if ("isFirst" in child) child.isFirst = (i === firstVisible);
    if ("isLast" in child) child.isLast = (i === lastVisible);
  }
}
