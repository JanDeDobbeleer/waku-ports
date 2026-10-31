# Helper of Hypr.qml for komorebi's cached work area. Two modes, nothing else:
#
#   -Query   Read only. Prints one JSON line: every monitor's handle, name, DPI, rectangle and work
#            area in physical pixels (left, top, right, bottom), and the handle of komorebi's hidden
#            window (0 when komorebi is not running).
#   -Notify  Sends WM_SETTINGCHANGE with SPI_SETWORKAREA to komorebi's hidden window only (class and
#            title "komorebi-hidden"), the message Explorer broadcasts when the work area changes.
#            komorebi then re-reads each monitor's work area and re-tiles the focused workspace of a
#            monitor whose work area differs from its cache; a monitor that matches is left alone.
#            No broadcast: no other window gets the message.
#
# komorebi v0.1.41: komorebi/src/monitor_reconciliator/hidden.rs (WM_SETTINGCHANGE ->
# MonitorNotification::WorkAreaChanged) and monitor_reconciliator/mod.rs (the WorkAreaChanged arm).
param([switch]$Query, [switch]$Notify)
$ErrorActionPreference = 'Stop'

Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;
public static class KomorebiWorkArea {
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
  [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
  public struct MONITORINFOEX {
    public int cbSize; public RECT rcMonitor; public RECT rcWork; public uint dwFlags;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string szDevice;
  }
  public delegate bool MonitorEnumProc(IntPtr h, IntPtr hdc, ref RECT r, IntPtr d);
  [DllImport("user32.dll")] static extern bool EnumDisplayMonitors(IntPtr hdc, IntPtr clip, MonitorEnumProc cb, IntPtr d);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern bool GetMonitorInfo(IntPtr h, ref MONITORINFOEX mi);
  [DllImport("user32.dll")] static extern IntPtr SetThreadDpiAwarenessContext(IntPtr ctx);
  [DllImport("shcore.dll")] static extern int GetDpiForMonitor(IntPtr h, int type, out uint x, out uint y);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern IntPtr FindWindow(string cls, string title);
  [DllImport("user32.dll")] static extern IntPtr SendMessageTimeout(IntPtr hwnd, uint msg, UIntPtr wp, IntPtr lp, uint flags, uint timeout, out UIntPtr result);

  static string Rect(RECT r) { return string.Format("[{0},{1},{2},{3}]", r.L, r.T, r.R, r.B); }

  public static long Hidden() { return FindWindow("komorebi-hidden", "komorebi-hidden").ToInt64(); }

  public static string Query() {
    // Per-monitor aware, so the rectangles are physical pixels like komorebi's.
    SetThreadDpiAwarenessContext(new IntPtr(-4));
    var parts = new List<string>();
    EnumDisplayMonitors(IntPtr.Zero, IntPtr.Zero, (IntPtr h, IntPtr hdc, ref RECT r, IntPtr d) => {
      var mi = new MONITORINFOEX();
      mi.cbSize = Marshal.SizeOf(typeof(MONITORINFOEX));
      if (!GetMonitorInfo(h, ref mi)) return true;
      uint dx = 0, dy = 0;
      GetDpiForMonitor(h, 0, out dx, out dy);
      string name = (mi.szDevice ?? "").Replace("\\\\.\\", "");
      parts.Add(string.Format("{{\"id\":{0},\"name\":\"{1}\",\"dpi\":{2},\"monitor\":{3},\"work\":{4}}}",
        h.ToInt64(), name, dx, Rect(mi.rcMonitor), Rect(mi.rcWork)));
      return true;
    }, IntPtr.Zero);
    return string.Format("{{\"monitors\":[{0}],\"hidden\":{1}}}", string.Join(",", parts), Hidden());
  }

  public static string Notify() {
    IntPtr hwnd = FindWindow("komorebi-hidden", "komorebi-hidden");
    if (hwnd == IntPtr.Zero) return "no komorebi window";
    const uint WM_SETTINGCHANGE = 0x001A, SPI_SETWORKAREA = 0x002F, SMTO_ABORTIFHUNG = 0x0002;
    UIntPtr res;
    IntPtr ok = SendMessageTimeout(hwnd, WM_SETTINGCHANGE, new UIntPtr(SPI_SETWORKAREA), IntPtr.Zero,
                                   SMTO_ABORTIFHUNG, 2000, out res);
    return ok == IntPtr.Zero ? "send failed " + hwnd.ToInt64() : "sent " + hwnd.ToInt64();
  }
}
'@

try {
  if ($Query) { [KomorebiWorkArea]::Query() }
  elseif ($Notify) { [KomorebiWorkArea]::Notify() }
  else { 'usage: -Query | -Notify'; exit 2 }
} catch {
  "error: $($_.Exception.Message)"
  exit 1
}
