pragma Singleton
import QtQuick
import Quickshell
import waku.services as S
import qs.Commons
import qs.Services.UI

Singleton {
  id: root

  // Component registration - only poll when something needs system stat data
  function registerComponent(componentId) {
    root._registered[componentId] = true;
    root._registered = Object.assign({}, root._registered);
    Logger.d("SystemStat", "Component registered:", componentId, "- total:", root._registeredCount);
  }

  function unregisterComponent(componentId) {
    delete root._registered[componentId];
    root._registered = Object.assign({}, root._registered);
    Logger.d("SystemStat", "Component unregistered:", componentId, "- total:", root._registeredCount);
  }

  property var _registered: ({})
  readonly property int _registeredCount: Object.keys(_registered).length
  readonly property bool _lockScreenActive: PanelService.lockScreen?.active ?? false
  readonly property bool shouldRun: _registeredCount > 0 && !_lockScreenActive

  // Polling intervals (hardcoded to sensible values per stat type)
  readonly property int cpuUsageIntervalMs: 1000
  readonly property int cpuFreqIntervalMs: 3000
  readonly property int memIntervalMs: 5000
  readonly property int networkIntervalMs: 3000
  readonly property int loadAvgIntervalMs: 10000
  readonly property int diskIntervalMs: 30000
  readonly property int gpuIntervalMs: 5000

  // Public values
  property real cpuUsage: 0
  property list<real> coresUsage: []
  property real cpuTemp: 0
  property string cpuFreq: "0.0GHz"
  property real cpuFreqRatio: 0
  property real cpuGlobalMaxFreq: 3.5
  property real gpuTemp: 0
  property bool gpuAvailable: false
  property string gpuType: "" // "amd", "intel", "nvidia"
  property real memGb: 0
  property real memPercent: 0
  property real memTotalGb: 0
  property real swapGb: 0
  property real swapPercent: 0
  property real swapTotalGb: 0
  property var diskPercents: ({})
  property var diskAvailPercents: ({}) // available disk space in percent
  property var diskUsedGb: ({}) // Used space in GB per mount point
  property var diskAvailableGb: ({}) // available space in GB per mount point
  property var diskSizeGb: ({}) // Total size in GB per mount point
  property real rxSpeed: 0
  property real txSpeed: 0
  property real zfsArcSizeKb: 0 // ZFS ARC cache size in KB
  property real zfsArcCminKb: 0 // ZFS ARC minimum (non-reclaimable) size in KB
  property real loadAvg1: 0
  property real loadAvg5: 0
  property real loadAvg15: 0
  property int nproc: 0 // Number of cpu cores

  // History arrays (2 minutes of data, length computed from polling interval)
  // Pre-filled with zeros so the graph scrolls smoothly from the start
  readonly property int historyDurationMs: (1 * 60 * 1000) // 1 minute

  // Computed history lengths based on polling intervals
  readonly property int cpuHistoryLength: Math.ceil(historyDurationMs / cpuUsageIntervalMs)
  readonly property int gpuHistoryLength: Math.ceil(historyDurationMs / gpuIntervalMs)
  readonly property int memHistoryLength: Math.ceil(historyDurationMs / memIntervalMs)
  readonly property int diskHistoryLength: Math.max(10, Math.ceil(historyDurationMs / diskIntervalMs))
  readonly property int networkHistoryLength: Math.ceil(historyDurationMs / networkIntervalMs)

  property var cpuHistory: new Array(cpuHistoryLength).fill(0)
  property var cpuTempHistory: new Array(cpuHistoryLength).fill(40)  // Reasonable default temp
  property var gpuTempHistory: new Array(gpuHistoryLength).fill(40)  // Reasonable default temp
  property var memHistory: new Array(memHistoryLength).fill(0)
  property var diskHistories: ({}) // Keyed by mount path, initialized on first update
  property var rxSpeedHistory: new Array(networkHistoryLength).fill(0)
  property var txSpeedHistory: new Array(networkHistoryLength).fill(0)

  // Historical min/max tracking (since shell started) for consistent graph scaling
  // Temperature defaults create a valid 30-80°C range that expands as real data comes in
  property real cpuTempHistoryMin: 30
  property real cpuTempHistoryMax: 80
  property real gpuTempHistoryMin: 30
  property real gpuTempHistoryMax: 80
  // Network uses autoscaling from current history window
  // Disk is always 0-100%

  // History management - called from update functions, not change handlers
  // (change handlers don't fire when value stays the same)
  function pushCpuHistory() {
    let h = cpuHistory.slice();
    h.push(cpuUsage);
    if (h.length > cpuHistoryLength)
      h.shift();
    cpuHistory = h;
  }

  function pushCpuTempHistory() {
    if (cpuTemp > 0) {
      if (cpuTemp < cpuTempHistoryMin)
        cpuTempHistoryMin = cpuTemp;
      if (cpuTemp > cpuTempHistoryMax)
        cpuTempHistoryMax = cpuTemp;
    }
    let h = cpuTempHistory.slice();
    h.push(cpuTemp);
    if (h.length > cpuHistoryLength)
      h.shift();
    cpuTempHistory = h;
  }

  function pushGpuHistory() {
    if (gpuTemp > 0) {
      if (gpuTemp < gpuTempHistoryMin)
        gpuTempHistoryMin = gpuTemp;
      if (gpuTemp > gpuTempHistoryMax)
        gpuTempHistoryMax = gpuTemp;
    }
    let h = gpuTempHistory.slice();
    h.push(gpuTemp);
    if (h.length > gpuHistoryLength)
      h.shift();
    gpuTempHistory = h;
  }

  function pushMemHistory() {
    let h = memHistory.slice();
    h.push(memPercent);
    if (h.length > memHistoryLength)
      h.shift();
    memHistory = h;
  }

  function pushDiskHistory() {
    let newHistories = {};
    for (let path in diskPercents) {
      // Pre-fill with zeros if this is a new path
      let h = diskHistories[path] ? diskHistories[path].slice() : new Array(diskHistoryLength).fill(0);
      h.push(diskPercents[path]);
      if (h.length > diskHistoryLength)
        h.shift();
      newHistories[path] = h;
    }
    diskHistories = newHistories;
  }

  function pushNetworkHistory() {
    let rxH = rxSpeedHistory.slice();
    rxH.push(rxSpeed);
    if (rxH.length > networkHistoryLength)
      rxH.shift();
    rxSpeedHistory = rxH;

    let txH = txSpeedHistory.slice();
    txH.push(txSpeed);
    if (txH.length > networkHistoryLength)
      txH.shift();
    txSpeedHistory = txH;
  }

  // Network max speed tracking (autoscales from current history window)
  // Minimum floor of 1 MB/s so graph doesn't fluctuate at low speeds
  readonly property real rxMaxSpeed: {
    const max = Math.max(...rxSpeedHistory);
    return Math.max(max, 1000000); // 1 MB/s floor
  }
  readonly property real txMaxSpeed: {
    const max = Math.max(...txSpeedHistory);
    return Math.max(max, 512000); // 512 KB/s floor
  }

  // Ready-to-use ratios based on current maximums (0..1 range)
  readonly property real rxRatio: rxMaxSpeed > 0 ? Math.min(1, rxSpeed / rxMaxSpeed) : 0
  readonly property real txRatio: txMaxSpeed > 0 ? Math.min(1, txSpeed / txMaxSpeed) : 0

  // Color resolution (respects useCustomColors setting)
  readonly property color warningColor: Settings.data.systemMonitor.useCustomColors ? (Settings.data.systemMonitor.warningColor || Color.mTertiary) : Color.mTertiary
  readonly property color criticalColor: Settings.data.systemMonitor.useCustomColors ? (Settings.data.systemMonitor.criticalColor || Color.mError) : Color.mError

  // Threshold values from settings
  readonly property int cpuWarningThreshold: Settings.data.systemMonitor.cpuWarningThreshold
  readonly property int cpuCriticalThreshold: Settings.data.systemMonitor.cpuCriticalThreshold
  readonly property int tempWarningThreshold: Settings.data.systemMonitor.tempWarningThreshold
  readonly property int tempCriticalThreshold: Settings.data.systemMonitor.tempCriticalThreshold
  readonly property int gpuWarningThreshold: Settings.data.systemMonitor.gpuWarningThreshold
  readonly property int gpuCriticalThreshold: Settings.data.systemMonitor.gpuCriticalThreshold
  readonly property int memWarningThreshold: Settings.data.systemMonitor.memWarningThreshold
  readonly property int memCriticalThreshold: Settings.data.systemMonitor.memCriticalThreshold
  readonly property int swapWarningThreshold: Settings.data.systemMonitor.swapWarningThreshold
  readonly property int swapCriticalThreshold: Settings.data.systemMonitor.swapCriticalThreshold
  readonly property int diskWarningThreshold: Settings.data.systemMonitor.diskWarningThreshold
  readonly property int diskCriticalThreshold: Settings.data.systemMonitor.diskCriticalThreshold
  readonly property int diskAvailWarningThreshold: Settings.data.systemMonitor.diskAvailWarningThreshold
  readonly property int diskAvailCriticalThreshold: Settings.data.systemMonitor.diskAvailCriticalThreshold

  // Computed warning/critical states (uses >= inclusive comparison)
  readonly property bool cpuWarning: cpuUsage >= cpuWarningThreshold
  readonly property bool cpuCritical: cpuUsage >= cpuCriticalThreshold
  readonly property bool tempWarning: cpuTemp >= tempWarningThreshold
  readonly property bool tempCritical: cpuTemp >= tempCriticalThreshold
  readonly property bool gpuWarning: gpuAvailable && gpuTemp >= gpuWarningThreshold
  readonly property bool gpuCritical: gpuAvailable && gpuTemp >= gpuCriticalThreshold
  readonly property bool memWarning: memPercent >= memWarningThreshold
  readonly property bool memCritical: memPercent >= memCriticalThreshold
  readonly property bool swapWarning: swapPercent >= swapWarningThreshold
  readonly property bool swapCritical: swapPercent >= swapCriticalThreshold

  // Helper functions for disk (disk path is dynamic)
  function isDiskWarning(diskPath, available = false) {
    return available ? (diskAvailPercents[diskPath] || 0) <= diskAvailWarningThreshold : (diskPercents[diskPath] || 0) >= diskWarningThreshold;
  }

  function isDiskCritical(diskPath, available = false) {
    return available ? (diskAvailPercents[diskPath] || 0) <= diskAvailCriticalThreshold : (diskPercents[diskPath] || 0) >= diskCriticalThreshold;
  }

  // Ready-to-use stat colors (for gauges, panels, icons)
  readonly property color cpuColor: cpuCritical ? criticalColor : (cpuWarning ? warningColor : Color.mPrimary)
  readonly property color tempColor: tempCritical ? criticalColor : (tempWarning ? warningColor : Color.mPrimary)
  readonly property color gpuColor: gpuCritical ? criticalColor : (gpuWarning ? warningColor : Color.mPrimary)
  readonly property color memColor: memCritical ? criticalColor : (memWarning ? warningColor : Color.mPrimary)
  readonly property color swapColor: swapCritical ? criticalColor : (swapWarning ? warningColor : Color.mPrimary)

  function getCoreUsageColor(usage) {
    if (usage >= cpuCriticalThreshold)
      return criticalColor;
    if (usage >= cpuWarningThreshold)
      return warningColor;
    return Color.mPrimary;
  }

  function getDiskColor(diskPath, available = false) {
    return isDiskCritical(diskPath, available) ? criticalColor : (isDiskWarning(diskPath, available) ? warningColor : Color.mPrimary);
  }

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
        // Cpu, Memory, Gpu and Disks are types, not singletons: one instance each, alive while a
        // component is registered, so the engine samples only then.
        S.Cpu {
          id: cpuSource
        }
        S.Memory {
          id: memSource
        }
        S.Gpu {
          id: gpuSource
        }
        S.Disks {
          id: diskSource
        }
        Binding {
          target: root
          property: "cpuUsage"
          value: cpuSource.percent
        }
        Binding {
          target: root
          property: "coresUsage"
          value: (cpuSource.perCore || []).map(v => Number(v))
        }
        Binding {
          target: root
          property: "cpuTemp"
          value: cpuSource.temperatureAvailable ? cpuSource.temperature : 0
        }
        Binding {
          target: root
          property: "nproc"
          value: cpuSource.cores
        }
        Binding {
          target: root
          property: "cpuFreq"
          value: root.frequencyText(cpuSource.frequency)
        }
        Binding {
          target: root
          property: "cpuGlobalMaxFreq"
          value: cpuSource.maxFrequency > 0 ? root.toGhz(cpuSource.maxFrequency) : 3.5
        }
        Binding {
          target: root
          property: "cpuFreqRatio"
          value: cpuSource.maxFrequency > 0 ? Math.min(1, cpuSource.frequency / cpuSource.maxFrequency) : 0
        }
        Binding {
          target: root
          property: "memGb"
          value: memSource.used / root._gib
        }
        Binding {
          target: root
          property: "memTotalGb"
          value: memSource.total / root._gib
        }
        Binding {
          target: root
          property: "memPercent"
          value: memSource.percent
        }
        Binding {
          target: root
          property: "swapGb"
          value: memSource.swapUsed / root._gib
        }
        Binding {
          target: root
          property: "swapTotalGb"
          value: memSource.swapTotal / root._gib
        }
        Binding {
          target: root
          property: "swapPercent"
          value: memSource.swapPercent
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
          value: gpuSource.available
        }
        Binding {
          target: root
          property: "gpuTemp"
          value: gpuSource.temperatureAvailable ? gpuSource.temperature : 0
        }
        Connections {
          target: diskSource
          function onUpdated() {
            root.readDisks();
          }
        }
        Component.onCompleted: {
          root._diskSource = diskSource;
          root.readDisks();
        }
        Component.onDestruction: root._diskSource = null
      }
    }
  }

  property var _diskSource: null

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
    const disks = root._diskSource ? (root._diskSource.disks || []) : [];
    const put = (key, d) => {
      percents[key] = d.percent;
      avail[key] = 100 - d.percent;
      used[key] = d.used / _gib;
      free[key] = d.free / _gib;
      size[key] = d.total / _gib;
    };
    for (const d of disks)
      put(d.mount, d);
    const primary = root._diskSource ? root._diskSource.primaryDisk : null;
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
  // -------------------------------------------------------
  // Helper function to format network speeds
  function formatSpeed(bytesPerSecond) {
    const units = ["KB", "MB", "GB"];
    let value = bytesPerSecond / 1000;
    let unitIndex = 0;

    while (value >= 1000 && unitIndex < units.length - 1) {
      value /= 1000;
      unitIndex++;
    }

    const unit = units[unitIndex];
    const shortUnit = unit[0];
    const numStr = value < 10 ? value.toFixed(1) : Math.round(value).toString();

    return (numStr + unit).length > 5 ? numStr + shortUnit : numStr + unit;
  }

  // -------------------------------------------------------
  // Compact speed formatter for vertical bar display
  function formatCompactSpeed(bytesPerSecond) {
    if (!bytesPerSecond || bytesPerSecond <= 0)
      return "0";
    const units = ["", "K", "M", "G"];
    let value = bytesPerSecond;
    let unitIndex = 0;
    while (value >= 1000 && unitIndex < units.length - 1) {
      value = value / 1000.0;
      unitIndex++;
    }
    // Promote at ~100 of current unit (e.g., 100k -> ~0.1M shown as 0.1M or 0M if rounded)
    if (unitIndex < units.length - 1 && value >= 100) {
      value = value / 1000.0;
      unitIndex++;
    }
    const display = Math.round(value).toString();
    return display + units[unitIndex];
  }

  // -------------------------------------------------------
  // Smart formatter for memory values (GB) - max 4 chars
  // Uses decimal for < 10GB, integer otherwise
  function formatGigabytes(memGb) {
    const value = parseFloat(memGb);
    if (isNaN(value))
      return "0G";

    if (value < 10)
      return value.toFixed(1) + "G"; // "0.0G" to "9.9G"
    return Math.round(value) + "G"; // "10G" to "999G"
  }

  // -------------------------------------------------------
  // Formatting gigabytes with optional padding
  function formatGigabytesDisplay(memGb, maxGb = null) {
    const value = formatGigabytes(memGb === null ? 0 : memGb);
    if (maxGb !== null) {
      const padding = Math.max(4, formatGigabytes(maxGb).length);
      return value.padStart(padding, " ");
    }
    return value;
  }

  // -------------------------------------------------------
  // Formatting percentage with optional padding
  function formatPercentageDisplay(value, padding = false) {
    return `${Math.round(value === null ? 0 : value)}%`.padStart(padding ? 4 : 0, " ");
  }

  // -------------------------------------------------------
  // Formatting disk usage
  function formatDiskDisplay(diskPath, {
                             percent = false,
                             available = false,
                             padding = false
} = {}) {
    if (percent) {
      const raw = available ? root.diskAvailPercents[diskPath] : root.diskPercents[diskPath];
      return formatPercentageDisplay(raw, padding);
    } else {
      const rawGb = available ? root.diskAvailableGb[diskPath] : root.diskUsedGb[diskPath];
      const maxGb = padding ? root.diskSizeGb[diskPath] : null;
      return formatGigabytesDisplay(rawGb, maxGb);
    }
  }

  // -------------------------------------------------------
  // Formatting ram usage
  function formatRamDisplay({
                            swap = false,
                            percent = false,
                            padding = false
} = {}) {
    if (percent) {
      const raw = swap ? swapPercent : memPercent;
      return formatPercentageDisplay(raw, padding);
    } else {
      const rawGb = swap ? swapGb : memGb;
      const maxGb = padding ? (swap ? swapTotalGb : memTotalGb) : null;
      return formatGigabytesDisplay(rawGb, maxGb);
    }
  }
}
