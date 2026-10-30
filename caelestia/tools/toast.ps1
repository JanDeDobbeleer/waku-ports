# Raises harmless local Windows toasts for testing the notification list and the sidebar.
# Each toast says "wabar port test". Uses the documented WinRT ToastNotificationManager with the
# PowerShell AUMID, so no app registration is needed. The wabar notification listener needs
# notification access (Settings > Privacy > Notifications); without it the feed stays empty.
param([int]$Count = 2, [string]$Aumid = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe')
# pwsh 7 (.NET 9) has no WinRT projection, so the toast code runs in Windows PowerShell 5.1.
$inner = {
  param($Count, $Aumid)
  $ErrorActionPreference = 'Stop'
  [void][Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
  [void][Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]
  $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($Aumid)
  for ($i = 1; $i -le $Count; $i++) {
    $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
    $xml.LoadXml("<toast><visual><binding template='ToastGeneric'><text>wabar port test $i</text><text>Harmless test toast $i from tools\toast.ps1</text></binding></visual></toast>")
    $notifier.Show([Windows.UI.Notifications.ToastNotification]::new($xml))
    Write-Host "toast $i shown"
    Start-Sleep -Milliseconds 700
  }
}
$enc = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes("& {$inner} $Count '$Aumid'"))
& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -OutputFormat Text -EncodedCommand $enc 2>$null | Where-Object { $_ -notmatch '^(#<|<Objs)' }
