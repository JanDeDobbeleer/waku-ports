.pragma library

function field(object, name) {
  return object ? object[name] : undefined;
}

function arrayLength(value) {
  return value && typeof value.length === "number" ? value.length : 0;
}

function arrayAt(value, index) {
  return value ? value[index] : undefined;
}

function imageLines(process) {
  const output = field(field(process, "stdout"), "text");
  if (typeof output !== "string")
    return [];
  const lines = output.split("\n");
  const images = [];
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
    if (line !== "")
      images.push(line);
  }
  return images;
}

function scrollHorizontally(flick, event) {
  if (!flick)
    return;
  const pixel = field(event, "pixelDelta");
  const angle = field(event, "angleDelta");
  const delta = pixel.x !== 0 || pixel.y !== 0 ? (pixel.y !== 0 ? pixel.y : pixel.x) : (angle.y !== 0 ? angle.y : angle.x);
  const maxX = Math.max(0, field(flick, "contentWidth") - field(flick, "width"));
  const contentX = field(flick, "contentX");
  const newX = Math.max(0, Math.min(maxX, contentX - delta));
  flick.contentX = newX;
  event.accepted = true;
}
