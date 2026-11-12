pragma Singleton

import "WallhavenServiceUtils.js" as WallhavenServiceUtils

import QtQuick 6.10
import Quickshell
import qs.Commons

Singleton {
  id: root

  // State
  property bool fetching: false
  property bool initialSearchScheduled: false
  property var currentResults: []
  property var currentMeta: ({})
  property string lastError: ""
  property string currentQuery: ""
  property int currentPage: 1
  property int lastPage: 1

  // Search parameters
  property string categories: "111" // general,anime,people (all enabled by default)
  property string purity: "100" // sfw
  property string sorting: "relevance" // date_added, relevance, random, views, favorites, toplist
  property string order: "desc" // desc, asc
  property string topRange: "1M" // 1d, 3d, 1w, 1M, 3M, 6M, 1y
  property string seed: "" // For random sorting
  property string minResolution: "" // e.g., "1920x1080"
  property string resolutions: "" // e.g., "1920x1080,1920x1200"
  property string ratios: "" // e.g., "16x9,16x10"
  property string colors: "" // Color hex codes
  // API Key Priority: Environment Variable > Local Settings
  readonly property string envApiKey: Quickshell.env("OCTALIA_WALLHAVEN_API_KEY") || ""
  readonly property string apiKey: envApiKey !== "" ? envApiKey : (Settings.data.wallpaper.wallhavenApiKey || "")
  readonly property bool apiKeyManagedByEnv: envApiKey !== ""

  // Signals
  signal searchCompleted(var results, var meta)
  signal searchFailed(string error)
  signal wallpaperDownloaded(string wallpaperId, string localPath)

  // Base API URL
  readonly property string apiBaseUrl: "https://wallhaven.cc/api/v1"

  // -------------------------------------------------
  function search(query: var, page: var): void {
    if (fetching) {
      return;
    }

    // Reset initial search flag once we start a search
    if (initialSearchScheduled) {
      initialSearchScheduled = false;
    }

    fetching = true;
    lastError = "";
    currentQuery = query || "";
    currentPage = page || 1;

    var url = apiBaseUrl + "/search";
    var params = [];

    if (currentQuery) {
      params.push("q=" + encodeURIComponent(currentQuery));
    }

    params.push("categories=" + categories);
    // Safety: Force SFW if no purity selected to prevent API error
    var safePurity = (purity === "000") ? "100" : purity;
    params.push("purity=" + safePurity);
    params.push("sorting=" + sorting);
    params.push("order=" + order);

    if (sorting === "toplist") {
      params.push("topRange=" + topRange);
    }

    if (sorting === "random" && seed) {
      params.push("seed=" + seed);
    }

    if (minResolution) {
      params.push("atleast=" + minResolution);
    }

    if (resolutions) {
      params.push("resolutions=" + resolutions);
    }

    if (ratios) {
      params.push("ratios=" + ratios);
    }

    if (colors) {
      params.push("colors=" + colors);
    }

    if (apiKey) {
      params.push("apikey=" + apiKey);
    }

    params.push("page=" + currentPage);

    url += "?" + params.join("&");

    Logger.d("Wallhaven", "Searching:", url);

    var xhr = new XMLHttpRequest();
    WallhavenServiceUtils.attachSearchHandler(root, xhr, Logger, XMLHttpRequest.DONE);

    xhr.open("GET", url);
    xhr.send();
  }

  // -------------------------------------------------
  function getWallpaperUrl(wallpaper: var): var {
    return WallhavenServiceUtils.getWallpaperUrl(wallpaper);
  }

  // -------------------------------------------------
  function getThumbnailUrl(wallpaper: var, size: var): var {
    return WallhavenServiceUtils.getThumbnailUrl(wallpaper, size);
  }

  // -------------------------------------------------
  function downloadWallpaper(wallpaper: var, callback: var): void {
    WallhavenServiceUtils.downloadWallpaper(root, Settings, Logger, wallpaper, callback);
  }

  function createDownloadProcess(source: var, name: var): QtObject {
    return Qt.createQmlObject(source, root, name);
  }

  // -------------------------------------------------
  function reset() {
    currentResults = [];
    currentMeta = {};
    currentQuery = "";
    currentPage = 1;
    lastPage = 1;
    seed = "";
    lastError = "";
  }

  // -------------------------------------------------
  function nextPage() {
    if (currentPage < lastPage && !fetching) {
      search(currentQuery, currentPage + 1);
    }
  }

  // -------------------------------------------------
  function previousPage() {
    if (currentPage > 1 && !fetching) {
      search(currentQuery, currentPage - 1);
    }
  }
}
