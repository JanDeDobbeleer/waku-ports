# Makes Windows start this port at sign-in, through the shared launcher (D:\waku-ports\install-startup.ps1).
[CmdletBinding(SupportsShouldProcess)]
param()
& (Join-Path $PSScriptRoot '..\..\install-startup.ps1') -Port noctalia -WhatIf:$WhatIfPreference
