# One-off: rewrites Services\System\SystemStatService.qml. Keeps the public properties, history, colours and
# formatting of the upstream file; replaces the /proc, sysfs and nvidia-smi readers with the engine's
# waku.services Cpu, Memory, Disks, Gpu and Network. Run once on the pristine upstream file.
$p = Join-Path $PSScriptRoot '..\modules\qs\Services\System\SystemStatService.qml'
$t = [IO.File]::ReadAllText($p) -replace "`r`n", "`n"
if ($t.Contains('waku.services')) { Write-Host 'already ported'; return }

$headEnd = $t.IndexOf("  // Internal state for CPU calculation")
$fmtStart = $t.IndexOf("  // -------------------------------------------------------`n  // Helper function to format network speeds")
$fmtEnd = $t.IndexOf("  // -------------------------------------------------------`n  // Function to start fetching and computing the cpu temperature")
if ($headEnd -lt 0 -or $fmtStart -lt 0 -or $fmtEnd -lt 0) { throw 'markers not found' }

$head = $t.Substring(0, $headEnd)
$fmt = $t.Substring($fmtStart, $fmtEnd - $fmtStart)

$head = $head.Replace("import QtQuick`nimport Quickshell`nimport Quickshell.Io`nimport qs.Commons", "import QtQuick`nimport Quickshell`nimport waku.services as S`nimport qs.Commons")
$head = $head.Replace("import Qt.labs.folderlistmodel`n`n", "")
$head = $head.Replace("import qs.compat`n", "")

$data = @'
  // ---------------------------------------------------------------------------------------------
  // Data: the engine's Cpu, Memory, Disks, Gpu and Network (waku.services) instead of /proc, sysfs,
  // df and nvidia-smi. The engine's sources sample only while something is bound to them, so the
  // bindings live in a Loader that is active while a component is registered.
  //
  // Windows has no load average (loadAvg1/5/15 stay 0), no ZFS ARC, and a CPU temperature that is a
  // proxy from the ACPI thermal zones. Disk maps are keyed by drive ("C:\"); "/" is the system drive,
  // so the default `diskPath` of the settings works.

  readonly property real _gib: 1073741824

  Loader {
    active: root.shouldRun
    sourceComponent: Component {
      Item {
        Binding {
          target: root
          property: "cpuUsage"
          value: S.Cpu.percent
        }
        Binding {
          target: root
          property: "coresUsage"
          value: (S.Cpu.perCore || []).map(v => Number(v))
        }
        Binding {
          target: root
          property: "cpuTemp"
          value: S.Cpu.temperatureAvailable ? S.Cpu.temperature : 0
        }
        Binding {
          target: root
          property: "nproc"
          value: S.Cpu.cores
        }
        Binding {
          target: root
          property: "cpuFreq"
          value: root.frequencyText(S.Cpu.frequency)
        }
        Binding {
          target: root
          property: "cpuGlobalMaxFreq"
          value: S.Cpu.maxFrequency > 0 ? root.toGhz(S.Cpu.maxFrequency) : 3.5
        }
        Binding {
          target: root
          property: "cpuFreqRatio"
          value: S.Cpu.maxFrequency > 0 ? Math.min(1, S.Cpu.frequency / S.Cpu.maxFrequency) : 0
        }
        Binding {
          target: root
          property: "memGb"
          value: S.Memory.used / root._gib
        }
        Binding {
          target: root
          property: "memTotalGb"
          value: S.Memory.total / root._gib
        }
        Binding {
          target: root
          property: "memPercent"
          value: S.Memory.percent
        }
        Binding {
          target: root
          property: "swapGb"
          value: S.Memory.swapUsed / root._gib
        }
        Binding {
          target: root
          property: "swapTotalGb"
          value: S.Memory.swapTotal / root._gib
        }
        Binding {
          target: root
          property: "swapPercent"
          value: S.Memory.swapPercent
        }
        Binding {
          target: root
          property: "rxSpeed"
          value: S.Network.rxBytesPerSecond
        }
        Binding {
          target: root
          property: "txSpeed"
          value: S.Network.txBytesPerSecond
        }
        Binding {
          target: root
          property: "gpuAvailable"
          value: S.Gpu.available
        }
        Binding {
          target: root
          property: "gpuTemp"
          value: S.Gpu.temperatureAvailable ? S.Gpu.temperature : 0
        }
        Connections {
          target: S.Disks
          function onUpdated() {
            root.readDisks();
          }
        }
        Component.onCompleted: root.readDisks()
      }
    }
  }

  // MHz (or GHz, if the engine ever reports that) to GHz.
  function toGhz(freq) {
    return freq > 100 ? freq / 1000 : freq;
  }

  function frequencyText(freq) {
    return freq > 0 ? toGhz(freq).toFixed(1) + "GHz" : "0.0GHz";
  }

  function readDisks() {
    const percents = {};
    const avail = {};
    const used = {};
    const free = {};
    const size = {};
    const disks = S.Disks.disks || [];
    const put = (key, d) => {
      percents[key] = d.percent;
      avail[key] = 100 - d.percent;
      used[key] = d.used / _gib;
      free[key] = d.free / _gib;
      size[key] = d.total / _gib;
    };
    for (const d of disks)
      put(d.mount, d);
    const primary = S.Disks.primaryDisk;
    if (primary && primary.mount !== undefined)
      put("/", primary);
    diskPercents = percents;
    diskAvailPercents = avail;
    diskUsedGb = used;
    diskAvailableGb = free;
    diskSizeGb = size;
    pushDiskHistory();
  }

  // The history arrays advance at the upstream intervals while something is registered.
  Timer {
    interval: root.cpuUsageIntervalMs
    repeat: true
    running: root.shouldRun
    onTriggered: {
      root.pushCpuHistory();
      root.pushCpuTempHistory();
    }
  }
  Timer {
    interval: root.memIntervalMs
    repeat: true
    running: root.shouldRun
    onTriggered: root.pushMemHistory()
  }
  Timer {
    interval: root.networkIntervalMs
    repeat: true
    running: root.shouldRun
    onTriggered: root.pushNetworkHistory()
  }
  Timer {
    interval: root.gpuIntervalMs
    repeat: true
    running: root.shouldRun
    onTriggered: root.pushGpuHistory()
  }

'@

$out = $head + $data + $fmt.TrimEnd() + "`n}`n"
[IO.File]::WriteAllText($p, $out, (New-Object Text.UTF8Encoding $false))
Write-Host "ported: $($out.Split("`n").Count) lines (was $($t.Split("`n").Count))"
