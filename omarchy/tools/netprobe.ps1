# One network probe for the Network panel, printed as key=value lines:
#   gateway=<ip>             the IPv4 gateway of the first adapter that is up and has one
#   router_ping_ms=<ms|-1>   one ping to it (-1: no reply)
#   internet_ping_ms=<ms|-1> one ping to 1.1.1.1 (-1: no reply)
# The panel calls it every few seconds while it is open and counts the -1s as packet loss.
# Plain .NET calls only: the NetTCPIP cmdlets take seconds to load.
$ErrorActionPreference = 'SilentlyContinue'
$gateway = $null
foreach ($nic in [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces()) {
  if ($nic.OperationalStatus -ne 'Up' -or $nic.NetworkInterfaceType -in 'Loopback', 'Tunnel') { continue }
  $g = $nic.GetIPProperties().GatewayAddresses | Where-Object { $_.Address.AddressFamily -eq 'InterNetwork' -and $_.Address.ToString() -ne '0.0.0.0' } | Select-Object -First 1
  if ($g) { $gateway = $g.Address.ToString(); break }
}
function Start-Probe([string]$Ip) { (New-Object System.Net.NetworkInformation.Ping).SendPingAsync($Ip, 1000) }
function Read-Probe($Task) {
  try { $r = $Task.GetAwaiter().GetResult(); if ($r.Status -eq 'Success') { [int]$r.RoundtripTime } else { -1 } } catch { -1 }
}
$router = if ($gateway) { Start-Probe $gateway }
$internet = Start-Probe '1.1.1.1'
if ($gateway) { Write-Output "gateway=$gateway"; Write-Output "router_ping_ms=$(Read-Probe $router)" }
Write-Output "internet_ping_ms=$(Read-Probe $internet)"
