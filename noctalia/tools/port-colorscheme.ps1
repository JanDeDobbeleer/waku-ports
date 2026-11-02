# One-off: ColorSchemeService lists the scheme folders with FolderListModel instead of `find`, and no
# longer calls the GTK python script.
$p = Join-Path $PSScriptRoot '..\modules\qs\Services\Theming\ColorSchemeService.qml'
$t = [IO.File]::ReadAllText($p) -replace "`r`n", "`n"
if ($t.Contains('bundledSchemes')) { Write-Host 'already ported'; return }
function Replace-Once($t, $old, $new) { if (-not $t.Contains($old)) { throw "not found: $old" }; $i = $t.IndexOf($old); $t.Remove($i, $old.Length).Insert($i, $new) }

# forward slashes everywhere: getBasename splits on "/"
$t = Replace-Once $t 'property string schemesDirectory: Quickshell.shellDir + "/Assets/ColorScheme"' 'property string schemesDirectory: String(Quickshell.shellDir).replace(/\/g, "/") + "/Assets/ColorScheme"'
$t = Replace-Once $t 'property string downloadedSchemesDirectory: Settings.configDir + "colorschemes"' 'property string downloadedSchemesDirectory: String(Settings.configDir).replace(/\/g, "/") + "colorschemes"'
# no GTK refresh on Windows
$t = Replace-Once $t "    const mode = Settings.data.colorSchemes.darkMode ? `"dark`" : `"light`";`n    Quickshell.execDetached([`"python3`", gtkRefreshScript, `"--appearance-only`", mode]);`n" ""
$t = Replace-Once $t "  readonly property string gtkRefreshScript: Quickshell.shellDir + `"/Scripts/python/src/theming/gtk-refresh.py`"`n" ""
# scan
$t = Replace-Once $t "    findProcess.command = [`"find`", `"-L`", schemesDirectory, downloadedSchemesDirectory, `"-mindepth`", `"2`", `"-name`", `"*.json`", `"-type`", `"f`"];`n    findProcess.running = true;" "    collectSchemes();"
$i = $t.IndexOf("  Process {`n    id: findProcess"); if ($i -lt 0) { throw 'findProcess not found' }
$j = $t.IndexOf("  // Internal loader to read a scheme file", $i)
$new = @'
  // The scheme folders (<dir>/<Name>/<Name>.json), listed by Qt instead of `find`. Both models watch
  // their folder, so a downloaded scheme shows up without another scan.
  FolderListModel {
    id: bundledSchemes
    folder: "file:///" + root.schemesDirectory
    showFiles: false
    showDirs: true
    showDotAndDotDot: false
    onStatusChanged: root.collectSchemes()
    onCountChanged: root.collectSchemes()
  }

  FolderListModel {
    id: downloadedSchemes
    folder: "file:///" + root.downloadedSchemesDirectory
    showFiles: false
    showDirs: true
    showDotAndDotDot: false
    onStatusChanged: root.collectSchemes()
    onCountChanged: root.collectSchemes()
  }

  function collectSchemes() {
    if (!scanning || bundledSchemes.status !== FolderListModel.Ready || downloadedSchemes.status === FolderListModel.Loading)
      return;
    var files = [];
    const sources = [[bundledSchemes, schemesDirectory], [downloadedSchemes, downloadedSchemesDirectory]];
    for (const [model, dir] of sources) {
      for (let k = 0; k < model.count; k++) {
        const name = model.get(k, "fileName");
        files.push(dir + "/" + name + "/" + name + ".json");
      }
    }
    files.sort(function (a, b) {
      return getBasename(a).toLowerCase().localeCompare(getBasename(b).toLowerCase());
    });
    schemes = files;
    scanning = false;
    Logger.d("ColorScheme", "Listed", schemes.length, "schemes");
    // Normalize stored scheme to basename and re-apply if necessary
    var stored = Settings.data.colorSchemes.predefinedScheme;
    if (stored) {
      var basename = getBasename(stored);
      if (basename !== stored) {
        Settings.data.colorSchemes.predefinedScheme = basename;
      }
      if (!Settings.data.colorSchemes.useWallpaperColors) {
        applyScheme(basename);
      }
    }
  }

'@
$t = $t.Substring(0, $i) + $new + $t.Substring($j)
[IO.File]::WriteAllText($p, $t, (New-Object Text.UTF8Encoding $false))
Write-Host 'colorscheme patched'
