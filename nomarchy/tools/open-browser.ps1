$ErrorActionPreference = 'Stop'

Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class BrowserAssociation {
  [DllImport("shlwapi.dll", CharSet = CharSet.Unicode)]
  public static extern int AssocQueryString(uint flags, uint str, string association,
    string extra, StringBuilder output, ref uint length);
}
'@

$length = [uint32]0
[void][BrowserAssociation]::AssocQueryString(0, 2, 'https', $null, $null, [ref]$length)
if ($length -eq 0) { throw 'No default browser is registered for HTTPS.' }
$path = New-Object System.Text.StringBuilder ([int]$length)
if ([BrowserAssociation]::AssocQueryString(0, 2, 'https', $null, $path, [ref]$length) -ne 0) {
  throw 'Could not resolve the default browser.'
}
Start-Process -FilePath $path.ToString() -ArgumentList 'about:blank'
