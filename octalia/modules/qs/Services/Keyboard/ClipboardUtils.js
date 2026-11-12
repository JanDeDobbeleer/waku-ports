.pragma library

function decode(id, cb, root, decodeProc) {
    if (!root.cliphistAvailable) {
      if (cb)
        cb("");
      return;
    }

    // Check cache first
    const cached = root.contentCache[id];
    if (cached) {
      if (cb)
        cb(cached);
      return;
    }

    // Fall back to cliphist decode
    if (decodeProc.running) {
      decodeProc.running = false;
    }
    root._decodeRequestId++;
    decodeProc.requestId = root._decodeRequestId;
    root._decodeCallback = function (content) {
      // Cache the result if successful
      if (content && content.trim()) {
        root.contentCache[id] = content;
      }
      if (cb)
        cb(content);
    };
    const idStr = String(id);
    decodeProc.command = ["cliphist", "decode", idStr];
    decodeProc.running = true;
}

function decodeToDataUrl(id, mime, cb, root, decodeB64Proc) {
    if (!root.cliphistAvailable) {
      if (cb)
        cb("");
      return;
    }
    // If cached, return immediately
    if (root.imageDataById[id]) {
      if (cb)
        cb(root.imageDataById[id]);
      return;
    }
    // Queue request; ensures single process handles sequentially
    root._b64Queue.push({
                          "id": id,
                          "mime": mime || "image/*",
                          "cb": cb
                        });
    if (!decodeB64Proc.running && root._b64CurrentCb === null) {
      root._startNextB64();
    }
}

function _startNextB64(root, decodeB64Proc) {
    if (root._b64Queue.length === 0 || !root.cliphistAvailable)
      return;
    const job = root._b64Queue.shift();
    root._b64CurrentCb = job.cb;
    root._b64CurrentMime = job.mime;
    root._b64CurrentId = job.id;
    decodeB64Proc.command = ["sh", "-c", `cliphist decode ${job.id} | base64 -w 0`];
    decodeB64Proc.running = true;
}

function deleteById(id, root, deleteProc) {
    if (!root.cliphistAvailable) {
      return;
    }
    if (deleteProc.running) {
      return;
    }
    const idStr = String(id).trim();
    // Remove from caches
    delete root.contentCache[idStr];
    delete root.imageDataById[idStr];
    const orderIdx = root._imageDataInsertOrder.indexOf(idStr);
    if (orderIdx !== -1)
      root._imageDataInsertOrder.splice(orderIdx, 1);
    deleteProc.command = ["sh", "-c", `echo ${idStr} | cliphist delete`];
    deleteProc.running = true;
}

function parseImageMeta(preview) {
    const re = /\[\[\s*binary data\s+([\d\.]+\s*(?:KiB|MiB|GiB|B))\s+(\w+)\s+(\d+)x(\d+)\s*\]\]/i;
    const match = (preview || "").match(re);
    if (!match)
      return null;
    return {
      "size": match[1],
      "fmt": (match[2] || "").toUpperCase(),
      "w": Number(match[3]),
      "h": Number(match[4])
    };
}
