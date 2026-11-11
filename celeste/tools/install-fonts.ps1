[CmdletBinding()]
param([switch]$Force)
$installer = Join-Path $PSScriptRoot '..\..\tools\install-fonts.ps1'
& $installer -Font @('MaterialSymbolsRounded', 'GoogleSansFlex') -Force:$Force
