# One-off: CompositorService session actions go through the engine's ControlCenter (lock, sleep,
# hibernate, signOut, restart, shutdown) instead of systemctl/loginctl.
$dir = Join-Path $PSScriptRoot '..\modules\qs\Services\Compositor'
$p = Join-Path $dir 'CompositorService.qml'
$t = [IO.File]::ReadAllText($p) -replace "`r`n", "`n"
if ($t.Contains('windowsSession')) { Write-Host 'already ported'; return }
function Rep($t, $old, $new) { if (-not $t.Contains($old)) { throw "not found: $old" }; $i = $t.IndexOf($old); $t.Remove($i, $old.Length).Insert($i, $new) }

$t = Rep $t "import Quickshell`nimport Quickshell.Io`n" "import Quickshell`nimport Quickshell.Io`nimport waku.services as S`n"
$t = Rep $t 'Quickshell.execDetached(["sh", "-c", customCommand]);' 'Quickshell.execDetached(["cmd", "/c", customCommand]);'
$t = Rep $t "  // Session management`n" @'
  // Session management, through the engine's ControlCenter: lock, sleep, hibernate, signOut, restart and
  // shutdown. The engine asks for a second request of the same id before it runs a dangerous one;
  // Noctalia's session menu has its own confirmation, so the request is repeated here.
  function windowsSession(id) {
    if (!S.ControlCenter.requestAction(id))
      S.ControlCenter.requestAction(id);
  }

  // Session management
'@
$t = Rep $t "    if (backend && backend.logout) {`n      backend.logout();`n    } else {`n      Logger.w(`"Compositor`", `"No backend available for logout`");`n    }" "    windowsSession(`"signOut`");"
$t = Rep $t 'Quickshell.execDetached(["sh", "-c", "systemctl poweroff || loginctl poweroff"]);' 'root.windowsSession("shutdown");'
$t = Rep $t 'Quickshell.execDetached(["sh", "-c", "systemctl reboot || loginctl reboot"]);' 'root.windowsSession("restart");'
$t = Rep $t 'Quickshell.execDetached(["sh", "-c", "systemctl soft-reboot"]);' 'root.windowsSession("restart");'
$t = Rep $t 'Quickshell.execDetached(["sh", "-c", "systemctl reboot --firmware-setup || loginctl reboot --firmware-setup"]);' 'Quickshell.execDetached(["shutdown", "/r", "/fw", "/t", "0"]);'
$t = Rep $t 'Quickshell.execDetached(["sh", "-c", "systemctl suspend || loginctl suspend"]);' 'windowsSession("sleep");'
$t = Rep $t 'Quickshell.execDetached(["sh", "-c", "systemctl hibernate || loginctl hibernate"]);' 'windowsSession("hibernate");'
$t = Rep $t "    if (PanelService && PanelService.lockScreen) {`n      PanelService.lockScreen.active = true;`n    }" "    windowsSession(`"lock`");"
[IO.File]::WriteAllText($p, $t, (New-Object Text.UTF8Encoding $false))
Write-Host 'session actions patched'
