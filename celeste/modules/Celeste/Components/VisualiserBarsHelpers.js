.pragma library

function barWidth(root) {
    const count = root.values.length;
    return Math.max(1, (root.width - root.spacing * (count - 1)) / Math.max(1, count));
}
