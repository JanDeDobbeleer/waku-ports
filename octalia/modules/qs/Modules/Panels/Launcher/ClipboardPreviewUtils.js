.pragma library

function field(object, name) {
  return object ? object[name] : undefined;
}

function loadContent(panel, service) {
  const item = field(panel, "currentItem");
  const clipboardId = field(item, "clipboardId");
  if (!clipboardId)
    return;
  if (field(panel, "isImageContent")) {
    const imageData = service.getImageData(clipboardId) || "";
    panel.imageDataUrl = imageData;
    panel.loadingFullContent = !imageData;
    const mime = field(item, "mime");
    if (!imageData && mime)
      service.decodeToDataUrl(clipboardId, mime, null);
    return;
  }
  const cached = service.getContent(clipboardId);
  if (cached) {
    panel.fullContent = cached;
    panel.loadingFullContent = false;
    return;
  }
  panel.fullContent = field(item, "preview") || "";
  panel.loadingFullContent = true;
  service.decode(clipboardId, function (content) {
    if (!field(panel, "currentItem") || field(field(panel, "currentItem"), "clipboardId") !== clipboardId)
      return;
    const trimmed = content ? content.trim() : "";
    if (trimmed !== "")
      panel.fullContent = trimmed;
    panel.loadingFullContent = false;
  });
}

function refreshCachedText(panel, service) {
  const item = field(panel, "currentItem");
  const clipboardId = field(item, "clipboardId");
  if (!clipboardId || field(panel, "isImageContent") || !field(panel, "loadingFullContent"))
    return;
  const cached = service.getContent(clipboardId);
  if (cached) {
    panel.fullContent = cached;
    panel.loadingFullContent = false;
  }
}

function shouldUpdateImage(panel) {
  return !!field(field(panel, "currentItem"), "isImage") && field(panel, "imageDataUrl") === "";
}

function updateImage(panel, service) {
  const clipboardId = field(field(panel, "currentItem"), "clipboardId");
  if (!clipboardId)
    return;
  const imageData = service.getImageData(clipboardId) || "";
  if (imageData !== field(panel, "imageDataUrl")) {
    panel.imageDataUrl = imageData;
    if (imageData)
      panel.loadingFullContent = false;
  }
}

function imageFormat(mime) {
  const format = (mime || "image").split("/")[1];
  return format ? format.toUpperCase() : "Image";
}

function contentStats(content) {
  const chars = content.length;
  const words = content.split(/\s+/).filter(function (word) { return word.length > 0; }).length;
  const lines = content.split("\n").length;
  return chars + " chars, " + words + " words, " + lines + " lines";
}

function formatImageMeta(meta) {
  return `${meta.fmt} • ${meta.w}×${meta.h} • ${meta.size}`;
}
