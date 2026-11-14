pragma Singleton

import "FontServiceUtils.js" as FontServiceUtils

import QtQuick 6.10
import Quickshell
import qs.Commons

Singleton {
  id: root

  property ListModel availableFonts: ListModel {}
  property ListModel monospaceFonts: ListModel {}
  property bool fontsLoaded: false
  property bool isLoading: false

  function init() {
    if (fontsLoaded || isLoading)
      return;
    Logger.i("Font", "Service started");
    loadFontsViaFcList();
  }

  // The families Qt finds on Windows (fc-list does not exist). Qt has no query for monospace, so a name
  // pattern stands in.
  function isMonospace(family: var): bool {
    return FontServiceUtils.isMonospace(family);
  }

  function loadFontsViaFcList() {
    if (isLoading)
      return;
    isLoading = true;
    const all = Qt.fontFamilies();
    populateModels(all.join("\n"), all.filter(FontServiceUtils.isMonospace).join("\n"));
  }

  function populateModels(allFontsText: var, monoFontsText: var): void {
    var families, fi, fontName, fontObj, i, j, k, line, m, mi, monoFamilies, monoName, n, name;
    // Parse monospace fonts into a lookup set
    // fc-list returns comma-separated family names for fonts with multiple families
    var monoLookup = {};
    var monoLines = monoFontsText.split('\n');
    for (i = 0; i < monoLines.length; i++) {
      line = monoLines[i].trim();
      if (line) {
        monoFamilies = line.split(',');
        for (mi = 0; mi < monoFamilies.length; mi++) {
          monoName = monoFamilies[mi].trim();
          if (monoName)
            monoLookup[monoName] = true;
        }
      }
    }

    // Parse all fonts - split comma-separated family names
    var allLines = allFontsText.split('\n');
    var fontSet = {}; // Deduplicate font families

    for (j = 0; j < allLines.length; j++) {
      line = allLines[j].trim();
      if (line) {
        families = line.split(',');
        for (fi = 0; fi < families.length; fi++) {
          fontName = families[fi].trim();
          if (fontName && !fontSet[fontName]) {
            fontSet[fontName] = true;
          }
        }
      }
    }

    // Sort font names
    var sortedFonts = FontServiceUtils.sortFontNames(fontSet);

    // Build arrays for batch insert
    var allBatch = [];
    var monoBatch = [];

    for (k = 0; k < sortedFonts.length; k++) {
      name = sortedFonts[k];
      fontObj = {
        "key": name,
        "name": name
      };
      allBatch.push(fontObj);

      // Check if monospace
      if (monoLookup[name] || name.toLowerCase().includes("mono")) {
        monoBatch.push(fontObj);
      }
    }

    // Clear and populate models (single batch operation)
    FontServiceUtils.clearModel(availableFonts);
    FontServiceUtils.clearModel(monospaceFonts);

    FontServiceUtils.appendItem(availableFonts, {
                            "key": FontServiceUtils.applicationFontFamily(),
                            "name": I18n.tr("panels.indicator.system-default")
                          });
    FontServiceUtils.appendItem(monospaceFonts, {
                            "key": "monospace",
                            "name": I18n.tr("panels.indicator.system-default")
                          });

    for (m = 0; m < allBatch.length; m++)
      FontServiceUtils.appendItem(availableFonts, allBatch[m]);
    for (n = 0; n < monoBatch.length; n++)
      FontServiceUtils.appendItem(monospaceFonts, monoBatch[n]);

    fontsLoaded = true;
    isLoading = false;
    Logger.i("Font", "Loaded", FontServiceUtils.count(availableFonts), "fonts,", FontServiceUtils.count(monospaceFonts), "monospace");
  }

  // Temporary storage for process outputs
  property string _allFontsOutput: ""
  property string _monoFontsOutput: ""
  property bool _allFontsDone: false
  property bool _monoFontsDone: false

  function checkBothProcessesDone() {
    if (_allFontsDone && _monoFontsDone) {
      populateModels(_allFontsOutput, _monoFontsOutput);
      // Clear temp storage
      _allFontsOutput = "";
      _monoFontsOutput = "";
      _allFontsDone = false;
      _monoFontsDone = false;
    }
  }

  // Process to get all font families (runs in background)

  // Process to get monospace font families (runs in background, parallel)
}
