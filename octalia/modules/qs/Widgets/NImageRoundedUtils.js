.pragma library

function status(image) {
  return image.status;
}

function width(image) {
  return image?.sourceSize.width ?? 0;
}

function height(image) {
  return image?.sourceSize.height ?? 0;
}
