# One-off: points CompositorService at the wabar backend and removes the Wayland backends.
$dir = Join-Path $PSScriptRoot '..\modules\qs\Services\Compositor'
$p = Join-Path $dir 'CompositorService.qml'
$t = [IO.File]::ReadAllText($p)
$t = [regex]::Replace($t, '(?s)  function detectCompositor\(\) \{.*?\n  \}\n\n  Loader \{', "  function detectCompositor() {`n    isHyprland = false;`n    isNiri = false;`n    isSway = false;`n    isMango = false;`n    isLabwc = false;`n    isExtWorkspace = false;`n    backendLoader.sourceComponent = wabarComponent;`n  }`n`n  Loader {")
$t = [regex]::Replace($t, '(?s)  // Hyprland backend component\n  Component \{.*?(?=  function setupBackendConnections)', "  // wabar backend component`n  Component {`n    id: wabarComponent`n    WabarService {`n      id: wabarBackend`n    }`n  }`n`n")
[IO.File]::WriteAllText($p, $t, (New-Object Text.UTF8Encoding $false))
foreach ($f in 'HyprlandService', 'NiriService', 'SwayService', 'MangoService', 'LabwcService', 'ExtWorkspaceService') {
  $x = Join-Path $dir "$f.qml"
  if (Test-Path -LiteralPath $x) { Remove-Item -LiteralPath $x }
}
Select-String -Path $p -Pattern 'wabarComponent|hyprlandComponent' | ForEach-Object { "$($_.LineNumber): $($_.Line.Trim())" }
