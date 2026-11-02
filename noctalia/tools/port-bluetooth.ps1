# One-off: BluetoothService pairs through the engine's BluetoothDevice (pair, cancelPair) instead of
# bluetoothctl and bluetooth-pair.py. Run after the two Process blocks were removed.
$p = Join-Path $PSScriptRoot '..\modules\qs\Services\Networking\BluetoothService.qml'
$t = [IO.File]::ReadAllText($p) -replace "`r`n", "`n"
function Cut($text, $from, $to, $replacement) {
  $i = $text.IndexOf($from); if ($i -lt 0) { throw "missing: $from" }
  $j = $text.IndexOf($to, $i); if ($j -lt 0) { throw "missing end: $to" }
  $text.Substring(0, $i) + $replacement + $text.Substring($j)
}
# the resume poll: no bluetoothctl, so nothing to poll
$t = Cut $t "  Timer {`n    id: ctlPollTimer" "  // Adapter power (enable/disable) via bluetoothctl" ""
$t = $t.Replace("      ctlPollTimer.restart();`n", "")
# pairing
$t = Cut $t "  function submitPin(pin) {" "  // Helper to run bluetoothctl and scripts" @"
  // Windows pairs without a PIN prompt of ours, so there is nothing to submit.
  function submitPin(pin) {
    root.pinRequired = false;
  }

  function cancelPairing() {
    const list = adapter && adapter.devices ? (adapter.devices.values || []) : [];
    for (const d of list) {
      if (typeof d.cancelPair === "function")
        d.cancelPair();
    }
    root.pinRequired = false;
  }

  // Pairing goes through the engine's BluetoothDevice.pair(); the name is upstream's.
  function pairWithBluetoothctl(device) {
    if (!device || typeof device.pair !== "function")
      return;
    root.pinRequired = false;
    root._discoveryWasRunning = root.scanningActive;
    if (root.scanningActive)
      root.setScanActive(false);
    device.pair();
  }


"@
[IO.File]::WriteAllText($p, $t, (New-Object Text.UTF8Encoding $false))
Write-Host "bluetooth patched"
