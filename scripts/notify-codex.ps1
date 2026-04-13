[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [ValidateSet('needs-reply', 'needs-confirmation', 'finished')]
  [string] $Kind,

  [switch] $NoSound,

  [switch] $Preview
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$libraryPath = Join-Path $PSScriptRoot 'lib\notify-codex-lib.ps1'
. $libraryPath

if ($Preview) {
  Get-CodexNotificationContent -Kind $Kind
  exit 0
}

Show-CodexToast -Kind $Kind -NoSound:$NoSound | Out-Null
