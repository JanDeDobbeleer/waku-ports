# Makes Windows start this port at sign-in, through the shared launcher (install-startup.ps1 in the repo root).
[CmdletBinding(SupportsShouldProcess)]
param()
& (Join-Path $PSScriptRoot '..\..\install-startup.ps1') -Port noctalia -WhatIf:$WhatIfPreference
