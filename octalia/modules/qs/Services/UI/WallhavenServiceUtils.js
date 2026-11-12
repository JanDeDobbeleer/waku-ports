.pragma library

function attachSearchHandler(root, xhr, Logger, doneState) {
  xhr.onreadystatechange = function () {
      var errorMsg, response;
      if (xhr.readyState === doneState) {
        root.fetching = false;
        if (xhr.status === 200) {
          try {
            response = JSON.parse(xhr.responseText);
            if (response.data && Array.isArray(response.data)) {
              root.currentResults = response.data;
              root.currentMeta = response.meta || {};
              root.lastPage = root.currentMeta.last_page || 1;

              // Store seed for random sorting
              if (root.currentMeta.seed) {
                root.seed = root.currentMeta.seed;
              }

              Logger.d("Wallhaven", "Search completed:", root.currentResults.length, "results, page", root.currentPage, "of", root.lastPage);
              root.searchCompleted(root.currentResults, root.currentMeta);
            } else {
              errorMsg = "Invalid API response";
              root.lastError = errorMsg;
              Logger.e("Wallhaven", errorMsg);
              root.searchFailed(errorMsg);
            }
          } catch (e) {
            errorMsg = "Failed to parse API response: " + e.toString();
            root.lastError = errorMsg;
            Logger.e("Wallhaven", errorMsg);
            root.searchFailed(errorMsg);
          }
        } else if (xhr.status === 429) {
          errorMsg = "Rate limit exceeded (45 requests/minute)";
          root.lastError = errorMsg;
          Logger.w("Wallhaven", errorMsg);
          root.searchFailed(errorMsg);
        } else if (xhr.status === 401) {
          errorMsg = "Invalid API Key. Please check your settings.";
          root.lastError = errorMsg;
          Logger.e("Wallhaven", errorMsg);
          root.searchFailed(errorMsg);
        } else {
          errorMsg = "API error: " + xhr.status;
          root.lastError = errorMsg;
          Logger.e("Wallhaven", "Search failed:", errorMsg);
          root.searchFailed(errorMsg);
        }
      }
  };
}

function getWallpaperUrl(wallpaper) {
    var idPrefix;
    // Use the 'path' field which contains the full resolution image URL
    if (wallpaper.path) {
      return wallpaper.path;
    }
    // Fallback to constructing URL from ID
    if (wallpaper.id) {
      idPrefix = wallpaper.id.substring(0, 2);
      return "https://w.wallhaven.cc/full/" + idPrefix + "/wallhaven-" + wallpaper.id + ".jpg";
    }
    return "";
}

function getThumbnailUrl(wallpaper, size) {
    var idPrefix, sizeMap, sizePath;
    // size: "small", "large", "original"
    if (wallpaper.thumbs && wallpaper.thumbs[size]) {
      return wallpaper.thumbs[size];
    }
    // Fallback
    if (wallpaper.id) {
      idPrefix = wallpaper.id.substring(0, 2);
      sizeMap = {
        "small": "small",
        "large": "lg",
        "original": "orig"
      };
      sizePath = sizeMap[size] || "lg";
      return "https://th.wallhaven.cc/" + sizePath + "/" + idPrefix + "/" + wallpaper.id + ".jpg";
    }
    return "";
}

function downloadWallpaper(root, Settings, Logger, wallpaper, callback) {
    var url = root.getWallpaperUrl(wallpaper);
    if (!url) {
      Logger.e("Wallhaven", "No URL available for wallpaper", wallpaper.id);
      if (callback)
        callback(false, "");
      return;
    }

    var wallpaperId = wallpaper.id;

    // Get the user's wallpaper directory
    var wallpaperDir = Settings.preprocessPath(Settings.data.wallpaper.directory);
    if (!wallpaperDir || wallpaperDir === "") {
      wallpaperDir = Settings.defaultWallpapersDirectory;
    }

    // Ensure directory ends with /
    if (!wallpaperDir.endsWith("/")) {
      wallpaperDir += "/";
    }

    var localPath = wallpaperDir + "wallhaven_" + wallpaperId + ".jpg";

    Logger.d("Wallhaven", "Downloading wallpaper", wallpaperId, "to", localPath);

    // Use curl or wget to download the file, ensuring directory exists first
    var downloadProcess = root.createDownloadProcess(`
                                             import QtQuick
                                             import Quickshell.Io
                                             Process {
                                             id: downloadProcess
                                             command: ["sh", "-c", "mkdir -p '` + wallpaperDir + `' && (curl -L -s -o '` + localPath + `' '` + url + `' || wget -q -O '` + localPath + `' '` + url + `')"]
                                             }
                                             `, "DownloadProcess_" + wallpaperId);

    downloadProcess.exited.connect(function (exitCode) {
      if (exitCode === 0) {
        Logger.i("Wallhaven", "Wallpaper downloaded:", localPath);
        root.wallpaperDownloaded(wallpaperId, localPath);
        if (callback)
          callback(true, localPath);
      } else {
        Logger.e("Wallhaven", "Failed to download wallpaper, exit code:", exitCode);
        if (callback)
          callback(false, "");
      }
      downloadProcess.destroy();
    });

    downloadProcess.running = true;
}
