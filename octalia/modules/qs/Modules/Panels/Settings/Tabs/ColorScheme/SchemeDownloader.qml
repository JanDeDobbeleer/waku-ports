import QtQuick 6.10
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell.Io
import qs.Commons
import qs.Services.Theming
import qs.Services.UI
import qs.Widgets
import qs.compat

Popup {
  id: root

  property var availableSchemes: []
  property bool fetching: false
  property bool downloading: false
  property bool hasInitialData: false // Track if we've loaded data at least once
  property string downloadError: ""
  property string downloadingScheme: ""
  property string pendingApplyScheme: "" // Scheme name to apply after reload
  property string lastStderrOutput: "" // Store stderr from download process
  property real lastApiFetchTime: 0 // Track when we last fetched from API to prevent rapid calls
  property int minApiFetchInterval: 60 // Minimum seconds between API fetches (1 minute)

  // Cache for remote scheme colors
  property var schemeColorsCache: ({})
  property int cacheVersion: 0

  // Cache for available schemes list (uses ShellState singleton)
  property int schemesCacheUpdateFrequency: 2 * 60 * 60 // 2 hours in seconds

  // Cache for repo branch info (to reduce API calls during downloads)
  property string cachedBranch: "main"
  property string cachedBranchSha: ""

  width: Math.max(500, contentColumn.implicitWidth + Style.margin2XL)
  height: Math.min(800, contentColumn.implicitHeight + Style.margin2XL)
  padding: Style.marginXL
  modal: true
  closePolicy: Popup.NoAutoClose
  dim: false
  anchors.centerIn: parent

  // Helper function to get color from cached scheme data
  function getSchemeColor(schemeName, colorKey) {
    var entry, variant;
    var _ = cacheVersion; // Create dependency

    if (schemeColorsCache[schemeName]) {
      entry = schemeColorsCache[schemeName];
      variant = entry;

      // Check if scheme has dark/light variants
      if (entry.dark || entry.light) {
        variant = Settings.data.colorSchemes.darkMode ? (entry.dark || entry.light) : (entry.light || entry.dark);
      }

      if (variant && variant[colorKey]) {
        return variant[colorKey];
      }
    }

    // Return visible defaults while loading
    var defaults = {
      "mSurface": Color.mSurfaceVariant,
      "mPrimary": Color.mPrimary,
      "mSecondary": Color.mSecondary,
      "mTertiary": Color.mTertiary,
      "mError": Color.mError,
      "mOnSurface": Color.mOnSurfaceVariant
    };
    return defaults[colorKey] || Color.mOnSurfaceVariant;
  }

  // Colors are now provided directly in the registry, no need to fetch individual files
  function fetchSchemeColors(scheme) {
    return;
  }

  background: Rectangle {
    color: Color.mSurface
    radius: Style.radiusL
    border.color: Color.mPrimary
    border.width: Style.borderM
  }

  function loadSchemesFromCache() {
    var cachedScheme, i;
    try {
      const now = Time.timestamp;
      const cacheData = ShellState.getColorSchemesList();
      const cachedSchemes = cacheData.schemes || [];
      const cachedTimestamp = cacheData.timestamp || 0;

      // Check if cache is expired or missing
      if (!cachedTimestamp || (now >= cachedTimestamp + schemesCacheUpdateFrequency)) {
        // Migration is now handled in Settings.qml

        // Only fetch from API if we haven't fetched recently (prevent rapid repeated calls)
        const timeSinceLastFetch = now - lastApiFetchTime;
        if (timeSinceLastFetch >= minApiFetchInterval) {
          Logger.d("ColorSchemeDownload", "Cache expired or missing, fetching new schemes");
          fetchAvailableSchemesFromAPI();
          return;
        } else {
          // Use cached data even if expired, to avoid rate limits
          Logger.d("ColorSchemeDownload", "Cache expired but recent API call detected, using cached data");
          if (cachedSchemes.length > 0) {
            availableSchemes = cachedSchemes;
            hasInitialData = true;
            fetching = false;
            return;
          }
        }
      }

      const ageMinutes = Math.round((now - cachedTimestamp) / 60);
      Logger.d("ColorSchemeDownload", "Loading cached schemes from ShellState (age:", ageMinutes, "minutes)");

      if (cachedSchemes.length > 0) {
        availableSchemes = cachedSchemes;
        // Restore color cache from cached schemes
        for (i = 0; i < cachedSchemes.length; i++) {
          cachedScheme = cachedSchemes[i];
          if (cachedScheme.dark || cachedScheme.light) {
            schemeColorsCache[cachedScheme.name] = {
              "dark": cachedScheme.dark || null,
              "light": cachedScheme.light || null
            };
          }
        }
        hasInitialData = true;
        cacheVersion++;
        fetching = false;
      } else {
        // Cache is empty, only fetch if we haven't fetched recently
        const timeSinceLastFetch = now - lastApiFetchTime;
        if (timeSinceLastFetch >= minApiFetchInterval) {
          fetchAvailableSchemesFromAPI();
        } else {
          Logger.d("ColorSchemeDownload", "Cache empty but recent API call detected, skipping fetch");
          fetching = false;
        }
      }
    } catch (error) {
      Logger.e("ColorSchemeDownload", "Failed to load schemes from cache:", error);
      fetching = false;
    }
  }

  function saveSchemesToCache() {
    try {
      ShellState.setColorSchemesList({
                                       schemes: availableSchemes,
                                       timestamp: Time.timestamp
                                     });
      Logger.d("ColorSchemeDownload", "Schemes list saved to ShellState");
    } catch (error) {
      Logger.e("ColorSchemeDownload", "Failed to save schemes to cache:", error);
    }
  }

  function fetchAvailableSchemes() {
    if (fetching) {
      return;
    }

    // Try to load from ShellState cache first
    if (typeof ShellState !== 'undefined' && ShellState.isLoaded) {
      loadSchemesFromCache();
    } else {
      // ShellState not ready, fetch directly from API
      fetchAvailableSchemesFromAPI();
    }
  }

  function fetchAvailableSchemesFromAPI() {
    if (fetching) {
      return;
    }

    // Check if we've fetched recently to prevent rapid repeated calls
    const now = Time.timestamp;
    const timeSinceLastFetch = now - lastApiFetchTime;
    if (timeSinceLastFetch < minApiFetchInterval) {
      Logger.d("ColorSchemeDownload", "Skipping API fetch - too soon since last fetch (", Math.round(timeSinceLastFetch), "s ago)");
      return;
    }

    fetching = true;
    lastApiFetchTime = now;
    // Don't clear availableSchemes immediately to prevent flicker - keep showing old list while fetching
    // availableSchemes = [];
    downloadError = "";

    // Fetch registry.json
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function () {
      var cachedScheme, i, j, registry, schemes, theme;
      if (xhr.readyState === XMLHttpRequest.DONE) {
        fetching = false;
        if (xhr.status === 200) {
          try {
            registry = JSON.parse(xhr.responseText);
            if (registry && registry.themes && Array.isArray(registry.themes)) {
              schemes = [];
              // Process themes
              for (i = 0; i < registry.themes.length; i++) {
                theme = registry.themes[i];
                schemes.push({
                               "name": theme.name,
                               "path": theme.path,
                               "dark": theme.dark || null,
                               "light": theme.light || null
                             });
                schemeColorsCache[theme.name] = {
                  "dark": theme.dark || null,
                  "light": theme.light || null
                };
              }
              availableSchemes = schemes;
              hasInitialData = true;
              cacheVersion++;
              Logger.d("ColorSchemeDownload", "Fetched", schemes.length, "available schemes from registry.json");
              // Save to cache
              saveSchemesToCache();
            } else {
              downloadError = I18n.tr("panels.color-scheme.download-error-invalid-response");
              Logger.e("ColorSchemeDownload", downloadError);
            }
          } catch (e) {
            downloadError = I18n.trArgs("panels.color-scheme.download-error-parse-failed", {
                                      "error": e.toString()
                                    });
            Logger.e("ColorSchemeDownload", downloadError);
          }
        } else if (xhr.status === 403) {
          // Rate limit hit - try to use cache if available
          downloadError = I18n.tr("panels.color-scheme.download-error-rate-limit");
          Logger.w("ColorSchemeDownload", downloadError);
          if (typeof ShellState !== 'undefined' && ShellState.isLoaded) {
            const cacheData = ShellState.getColorSchemesList();
            const cachedSchemes = cacheData.schemes || [];
            if (cachedSchemes.length > 0) {
              availableSchemes = cachedSchemes;
              // Restore color cache from cached schemes
              for (j = 0; j < cachedSchemes.length; j++) {
                cachedScheme = cachedSchemes[j];
                if (cachedScheme.dark || cachedScheme.light) {
                  schemeColorsCache[cachedScheme.name] = {
                    "dark": cachedScheme.dark || null,
                    "light": cachedScheme.light || null
                  };
                }
              }
              hasInitialData = true;
              cacheVersion++;
              Logger.i("ColorSchemeDownload", "Using cached schemes due to rate limit");
            }
          }
        } else {
          downloadError = I18n.trArgs("panels.color-scheme.download-error-api-error", {
                                    "status": xhr.status
                                  });
          Logger.e("ColorSchemeDownload", downloadError);
        }
      }
    };

    xhr.open("GET", "https://raw.githubusercontent.com/noctalia-dev/noctalia-colorschemes/main/registry.json");
    xhr.send();
  }

  function downloadScheme(scheme) {
    var xhr;
    if (downloading) {
      return;
    }

    downloading = true;
    downloadingScheme = scheme.name;
    downloadError = "";

    Logger.i("ColorSchemeDownload", "Downloading scheme:", scheme.name);

    // Use cached branch/SHA if available, otherwise fetch
    if (cachedBranchSha) {
      // Use cached SHA directly
      getSchemeTreeWithSha(scheme, cachedBranch, cachedBranchSha);
    } else if (cachedBranch) {
      // We have branch name, just need SHA
      getSchemeTree(scheme, cachedBranch);
    } else {
      // Need to fetch branch info first
      xhr = new XMLHttpRequest();
      xhr.onreadystatechange = function () {
        var defaultBranch, repoInfo;
        if (xhr.readyState === XMLHttpRequest.DONE) {
          if (xhr.status === 200) {
            try {
              repoInfo = JSON.parse(xhr.responseText);
              defaultBranch = repoInfo.default_branch || "main";
              cachedBranch = defaultBranch;
              // Now get the tree for the scheme directory
              getSchemeTree(scheme, defaultBranch);
            } catch (e) {
              // Fallback: try to get files directly
              getSchemeFilesDirect(scheme);
            }
          } else {
            // Fallback: try to get files directly
            getSchemeFilesDirect(scheme);
          }
        }
      };
      xhr.open("GET", "https://api.github.com/repos/noctalia-dev/noctalia-colorschemes");
      xhr.send();
    }
  }

  function getSchemeTree(scheme, branch) {
    // First get the SHA of the branch
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function () {
      var refResponse, sha;
      if (xhr.readyState === XMLHttpRequest.DONE) {
        if (xhr.status === 200) {
          try {
            refResponse = JSON.parse(xhr.responseText);
            sha = refResponse.object ? refResponse.object.sha : null;
            if (sha) {
              // Cache the SHA for future downloads
              cachedBranchSha = sha;
              // Now get the tree
              getSchemeTreeWithSha(scheme, branch, sha);
            } else {
              // Fallback to direct method
              getSchemeFilesDirect(scheme);
            }
          } catch (e) {
            // Fallback to direct method
            getSchemeFilesDirect(scheme);
          }
        } else {
          // Fallback to direct method
          getSchemeFilesDirect(scheme);
        }
      }
    };
    xhr.open("GET", "https://api.github.com/repos/noctalia-dev/noctalia-colorschemes/git/refs/heads/" + branch);
    xhr.send();
  }

  function getSchemeTreeWithSha(scheme, branch, sha) {
    // Use git trees API to get all files recursively
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function () {
      var files, i, item, response;
      if (xhr.readyState === XMLHttpRequest.DONE) {
        if (xhr.status === 200) {
          try {
            response = JSON.parse(xhr.responseText);
            if (response.tree && Array.isArray(response.tree)) {
              // Filter files that belong to this scheme
              files = [];
              for (i = 0; i < response.tree.length; i++) {
                item = response.tree[i];
                if (item.type === "blob" && item.path.startsWith(scheme.path + "/")) {
                  files.push({
                               "path": item.path,
                               "url": "https://raw.githubusercontent.com/noctalia-dev/noctalia-colorschemes/" + branch + "/" + item.path,
                               "name": item.path.split("/").pop()
                             });
                }
              }
              downloadSchemeFiles(scheme.name, files);
            } else {
              // Fallback to direct method
              getSchemeFilesDirect(scheme);
            }
          } catch (e) {
            downloadError = I18n.trArgs("panels.color-scheme.download-error-parse-failed", {
                                      "error": e.toString()
                                    });
            downloading = false;
            downloadingScheme = "";
            Logger.e("ColorSchemeDownload", downloadError);
          }
        } else {
          // Fallback to direct method
          getSchemeFilesDirect(scheme);
        }
      }
    };
    xhr.open("GET", "https://api.github.com/repos/noctalia-dev/noctalia-colorschemes/git/trees/" + sha + "?recursive=1");
    xhr.send();
  }

  function getSchemeFilesDirect(scheme) {
    // Fallback: get files directly using contents API (non-recursive, but works)
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function () {
      var response;
      if (xhr.readyState === XMLHttpRequest.DONE) {
        if (xhr.status === 200) {
          try {
            response = JSON.parse(xhr.responseText);
            if (Array.isArray(response)) {
              // Recursively get all files
              getAllFilesRecursive(scheme, response, []);
            } else {
              downloadError = I18n.tr("panels.color-scheme.download-error-invalid-response");
              downloading = false;
              downloadingScheme = "";
              Logger.e("ColorSchemeDownload", downloadError);
            }
          } catch (e) {
            downloadError = I18n.trArgs("panels.color-scheme.download-error-parse-failed", {
                                      "error": e.toString()
                                    });
            downloading = false;
            downloadingScheme = "";
            Logger.e("ColorSchemeDownload", downloadError);
          }
        } else {
          downloadError = I18n.trArgs("panels.color-scheme.download-error-api-error", {
                                    "status": xhr.status
                                  });
          downloading = false;
          downloadingScheme = "";
          Logger.e("ColorSchemeDownload", downloadError);
        }
      }
    };
    xhr.open("GET", "https://api.github.com/repos/noctalia-dev/noctalia-colorschemes/contents/" + scheme.path);
    xhr.send();
  }

  function getAllFilesRecursive(scheme, items, allFiles, callback) {
    var i, item, xhr;
    if (!callback) {
      callback = function () {
        downloadSchemeFiles(scheme.name, allFiles);
      };
    }

    if (items.length === 0) {
      callback();
      return;
    }

    var pending = 0;
    var completed = 0;

    function checkComplete() {
      completed++;
      if (completed === items.length && pending === 0) {
        callback();
      }
    }

    for (i = 0; i < items.length; i++) {
      item = items[i];
      if (item.type === "file") {
        allFiles.push({
                        "path": item.path,
                        "url": item.download_url,
                        "name": item.name
                      });
        checkComplete();
      } else if (item.type === "dir") {
        pending++;
        xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function (dirItem) {
          return function () {
            var dirResponse;
            if (xhr.readyState === XMLHttpRequest.DONE) {
              pending--;
              if (xhr.status === 200) {
                try {
                  dirResponse = JSON.parse(xhr.responseText);
                  if (Array.isArray(dirResponse)) {
                    getAllFilesRecursive(scheme, dirResponse, allFiles, function () {
                      checkComplete();
                    });
                  } else {
                    checkComplete();
                  }
                } catch (e) {
                  Logger.e("ColorSchemeDownload", "Failed to parse directory response:", e);
                  checkComplete();
                }
              } else {
                checkComplete();
              }
            }
          };
        }(item);
        xhr.open("GET", item.url);
        xhr.send();
      } else {
        checkComplete();
      }
    }
  }

  FileView {
    id: schemeWriter
    blockWrites: true
    atomicWrites: false
    printErrors: true
  }

  // Fetches every file over HTTP and writes it with FileView (no sh/curl on Windows). FileView
  // creates the parent folders.
  function downloadSchemeFiles(schemeName, files) {
    var file, filePath, i, rawUrl, relativePath;
    if (files.length === 0) {
      downloadError = I18n.tr("panels.color-scheme.download-error-no-files");
      downloading = false;
      downloadingScheme = "";
      Logger.e("ColorSchemeDownload", downloadError);
      return;
    }

    var targetDir = ColorSchemeService.downloadedSchemesDirectory + "/" + schemeName;
    var queue = [];
    for (i = 0; i < files.length; i++) {
      file = files[i];
      filePath = file.path;
      relativePath = filePath;
      if (filePath.startsWith(schemeName + "/")) {
        relativePath = filePath.substring(schemeName.length + 1);
      } else if (filePath.startsWith("/" + schemeName + "/")) {
        relativePath = filePath.substring(schemeName.length + 2);
      }
      rawUrl = file.url || file.download_url;
      if (rawUrl)
        queue.push({
                     "url": encodeURI(rawUrl),
                     "localPath": targetDir + "/" + relativePath
                   });
    }

    Logger.d("ColorSchemeDownload", "Downloading", queue.length, "files for scheme", schemeName);

    var failed = "";
    function finish() {
      if (failed === "") {
        Logger.i("ColorSchemeDownload", "Scheme downloaded successfully:", schemeName);
        ToastService.showNotice(I18n.tr("panels.color-scheme.download-success-title"), I18n.trArgs("panels.color-scheme.download-success-description", {
                                                                                                 "scheme": schemeName
                                                                                               }), "settings-color-scheme");
        pendingApplyScheme = schemeName;
        ColorSchemeService.loadColorSchemes();
      } else {
        downloadError = I18n.trArgs("panels.color-scheme.download-error-download-failed", {
                                  "code": 1
                                }) + "\n" + failed;
        Logger.e("ColorSchemeDownload", downloadError);
        ToastService.showError(I18n.tr("panels.color-scheme.download-error-title"), I18n.trArgs("panels.color-scheme.download-error-description", {
                                                                                              "scheme": schemeName
                                                                                            }) + "\n" + failed);
        Os.rm(targetDir, true);
      }
      downloading = false;
      downloadingScheme = "";
    }

    function next() {
      if (queue.length === 0 || failed !== "") {
        finish();
        return;
      }
      var item = queue.shift();
      var xhr = new XMLHttpRequest();
      xhr.onreadystatechange = function () {
        if (xhr.readyState !== XMLHttpRequest.DONE)
          return;
        if (xhr.status === 200) {
          schemeWriter.path = "";
          schemeWriter.path = item.localPath;
          schemeWriter.setText(xhr.responseText);
        } else {
          failed = "HTTP " + xhr.status + " " + item.url;
        }
        next();
      };
      xhr.open("GET", item.url);
      xhr.send();
    }
    next();
  }

  function isSchemeInstalled(schemeName) {
    var i, path;
    // Check if scheme already exists in ColorSchemeService
    for (i = 0; i < ColorSchemeService.schemes.length; i++) {
      path = ColorSchemeService.schemes[i];
      if (path.indexOf("/" + schemeName + "/") !== -1 || path.indexOf("/" + schemeName + ".json") !== -1) {
        return true;
      }
    }
    return false;
  }

  function isSchemeDownloaded(schemeName) {
    var i, path;
    // Check if scheme is in the downloaded directory (not preinstalled)
    for (i = 0; i < ColorSchemeService.schemes.length; i++) {
      path = ColorSchemeService.schemes[i];
      if ((path.indexOf("/" + schemeName + "/") !== -1 || path.indexOf("/" + schemeName + ".json") !== -1) && path.indexOf(ColorSchemeService.downloadedSchemesDirectory) !== -1) {
        return true;
      }
    }
    return false;
  }

  function deleteScheme(schemeName) {
    if (downloading) {
      return;
    }

    Logger.i("ColorSchemeDownload", "Deleting scheme:", schemeName);

    var currentScheme = Settings.data.colorSchemes.predefinedScheme || "";
    var deletedSchemeDisplayName = ColorSchemeService.getBasename(schemeName);
    var needsReset = (currentScheme === deletedSchemeDisplayName);

    // Only downloaded schemes can be deleted, not preinstalled ones
    Os.rm(ColorSchemeService.downloadedSchemesDirectory + "/" + schemeName, true);

    ToastService.showNotice(I18n.tr("panels.color-scheme.delete-success-title"), I18n.trArgs("panels.color-scheme.delete-success-description", {
                                                                                           "scheme": schemeName
                                                                                         }), "settings-color-scheme");
    if (needsReset) {
      Settings.data.colorSchemes.predefinedScheme = "Octalia (default)";
      ColorSchemeService.setPredefinedScheme("Octalia (default)");
    }
    // rm runs detached; rescan once it has had time to finish
    reloadAfterDeleteTimer.restart();
  }

  Timer {
    id: reloadAfterDeleteTimer
    interval: 600
    onTriggered: ColorSchemeService.loadColorSchemes()
  }

  Connections {
    target: ColorSchemeService
    function onScanningChanged() {
      var schemeToApply;
      // When scanning completes and we have a pending scheme, apply it
      if (!ColorSchemeService.scanning && pendingApplyScheme !== "") {
        schemeToApply = pendingApplyScheme;
        pendingApplyScheme = ""; // Clear pending before applying

        // Wait a tiny bit to ensure schemes array is updated
        applyTimer.schemeName = schemeToApply;
        applyTimer.restart();
      }
    }
  }

  Timer {
    id: applyTimer
    property string schemeName: ""
    interval: 100 // Small delay to ensure schemes array is populated
    onTriggered: {
      if (schemeName !== "") {
        Logger.i("ColorSchemeDownload", "Auto-applying downloaded scheme:", schemeName);
        // Use setPredefinedScheme which will apply and set it as the current scheme
        ColorSchemeService.setPredefinedScheme(schemeName);
        schemeName = "";
      }
    }
  }

  onOpened: {
    fetchAvailableSchemes();
  }

  function preFetchSchemeColors() {
    if (availableSchemes.length > 0 && visible) {
      Qt.callLater(function () {
        // Just trigger a cache version update to ensure UI refreshes
        cacheVersion++;
      });
    }
  }

  onAvailableSchemesChanged: preFetchSchemeColors()
  onVisibleChanged: {
    preFetchSchemeColors();

    // Load schemes from ShellState when popup becomes visible
    if (visible) {
      if (typeof ShellState !== 'undefined' && ShellState.isLoaded) {
        loadSchemesFromCache();
      }
    }
  }

  Connections {
    target: typeof ShellState !== 'undefined' ? ShellState : null
    function onIsLoadedChanged() {
      if (root.visible && ShellState.isLoaded) {
        loadSchemesFromCache();
      }
    }
  }

  contentItem: ColumnLayout {
    id: contentColumn
    width: parent.width
    spacing: Style.marginL

    // Header
    RowLayout {
      Layout.fillWidth: true

      NText {
        text: I18n.tr("panels.color-scheme.download-title")
        pointSize: Style.fontSizeL
        font.weight: Style.fontWeightBold
        color: Color.mPrimary
        Layout.fillWidth: true
      }

      NIconButton {
        icon: "refresh"
        enabled: !fetching && !downloading
        onClicked: {
          // Force refresh by clearing cache timestamp and fetching directly from API
          if (typeof ShellState !== 'undefined' && ShellState.isLoaded) {
            ShellState.setColorSchemesList({
                                             schemes: [],
                                             timestamp: 0
                                           });
          }
          // Fetch directly from API to avoid cache check delay
          fetchAvailableSchemesFromAPI();
        }
      }

      NIconButton {
        icon: "close"
        onClicked: root.close()
      }
    }

    // Separator
    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 1
      color: Color.mOutline
    }

    // Error message
    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: errorText.implicitHeight + Style.marginM
      visible: downloadError !== ""
      color: Color.mError
      radius: Style.radiusS

      NText {
        id: errorText
        anchors.fill: parent
        anchors.margins: Style.marginM
        text: downloadError
        pointSize: Style.fontSizeS
        color: Color.mOnError
        wrapMode: Text.WordWrap
      }
    }

    // Loading indicator - only show on initial load, not during refresh
    RowLayout {
      Layout.fillWidth: true
      visible: fetching && !hasInitialData
      spacing: Style.marginM

      NBusyIndicator {
        Layout.preferredWidth: 20
        Layout.preferredHeight: 20
      }

      NText {
        text: I18n.tr("panels.color-scheme.download-fetching")
        pointSize: Style.fontSizeM
        color: Color.mOnSurfaceVariant
      }
    }

    // Schemes list - keep visible during refresh to prevent flicker
    NScrollView {
      id: schemesScrollView
      Layout.fillWidth: true
      Layout.preferredHeight: 400
      visible: hasInitialData && availableSchemes.length > 0
      verticalPolicy: ScrollBar.AsNeeded
      horizontalPolicy: ScrollBar.AlwaysOff
      gradientColor: Color.mSurface

      ColumnLayout {
        width: schemesScrollView.availableWidth
        spacing: Style.marginS

        Repeater {
          model: availableSchemes

          Rectangle {
            id: schemeItem
            Layout.fillWidth: true
            Layout.preferredHeight: 50 * Style.uiScaleRatio
            radius: Style.radiusS
            property string schemeName: modelData.name
            color: root.getSchemeColor(schemeName, "mSurface")
            border.width: Style.borderL
            border.color: hoverHandler.hovered ? root.getSchemeColor(schemeName, "mPrimary") : Color.mOutline

            HoverHandler {
              id: hoverHandler
            }

            Behavior on color {
              ColorAnimation {
                duration: Style.animationFast
                easing.type: Easing.InOutCubic
              }
            }

            Behavior on border.color {
              ColorAnimation {
                duration: Style.animationFast
                easing.type: Easing.InOutCubic
              }
            }

            Component.onCompleted: {
              if (root.visible && !root.schemeColorsCache[schemeName]) {
                root.fetchSchemeColors(modelData);
              }
            }

            RowLayout {
              id: schemeRow
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              anchors.leftMargin: Style.marginL
              anchors.rightMargin: Style.marginL
              spacing: Style.marginS

              property string schemeName: modelData.name
              property int diameter: 16 * Style.uiScaleRatio
              property var colorKeys: ["mPrimary", "mSecondary", "mTertiary", "mError"]

              NText {
                text: schemeRow.schemeName
                pointSize: Style.fontSizeS
                color: Color.mOnSurface
                Layout.fillWidth: true
                elide: Text.ElideRight
                Layout.alignment: Qt.AlignVCenter
              }

              // Color swatches
              Repeater {
                model: schemeRow.colorKeys
                Rectangle {
                  width: schemeRow.diameter
                  height: schemeRow.diameter
                  radius: schemeRow.diameter * 0.5
                  color: root.getSchemeColor(schemeRow.schemeName, modelData)
                  Layout.alignment: Qt.AlignVCenter

                  Behavior on color {
                    ColorAnimation {
                      duration: Style.animationFast
                      easing.type: Easing.InOutCubic
                    }
                  }
                }
              }

              // Download/Delete button
              NIconButton {
                property bool isDownloading: downloading && downloadingScheme === schemeRow.schemeName
                property bool isInstalled: root.isSchemeInstalled(schemeRow.schemeName)
                property bool isDownloaded: root.isSchemeDownloaded(schemeRow.schemeName)

                icon: isDownloading ? "" : (isDownloaded ? "trash" : "download")
                enabled: !downloading
                Layout.alignment: Qt.AlignVCenter
                visible: !isInstalled || isDownloaded // Show button only if not installed (can download) or if downloaded (can delete)
                onClicked: isDownloaded ? root.deleteScheme(schemeRow.schemeName) : root.downloadScheme(modelData)

                NBusyIndicator {
                  anchors.centerIn: parent
                  width: 16 * Style.uiScaleRatio
                  height: 16 * Style.uiScaleRatio
                  visible: parent.isDownloading
                }
              }
            }
          }
        }
      }
    }

    // Empty state
    ColumnLayout {
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignHCenter
      spacing: Style.marginM
      visible: !fetching && availableSchemes.length === 0 && downloadError === ""

      NIcon {
        icon: "package"
        pointSize: 48
        color: Color.mOnSurfaceVariant
        Layout.alignment: Qt.AlignHCenter
      }

      NText {
        text: I18n.tr("panels.color-scheme.download-empty")
        pointSize: Style.fontSizeM
        color: Color.mOnSurfaceVariant
        Layout.alignment: Qt.AlignHCenter
      }
    }
  }
}
