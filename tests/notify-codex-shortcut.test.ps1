Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$libraryPath = Join-Path $PSScriptRoot '..\scripts\lib\notify-codex-lib.ps1'
if (-not (Test-Path $libraryPath)) {
  throw "Missing library: $libraryPath"
}

. $libraryPath

function Assert-Equal {
  param(
    [Parameter(Mandatory)] $Actual,
    [Parameter(Mandatory)] $Expected,
    [Parameter(Mandatory)] [string] $Message
  )

  if ($Actual -ne $Expected) {
    throw "$Message`nExpected: $Expected`nActual:   $Actual"
  }
}

$tempDir = Join-Path $env:TEMP ('codex-toast-shortcut-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempDir | Out-Null

try {
  $shortcutPath = Join-Path $tempDir 'Codex Test Toast.lnk'
  $appId = 'ArtemaO.CodexNotifier.Test'
  $targetPath = Join-Path $PSHOME 'powershell.exe'

  Ensure-CodexToastShortcut `
    -ShortcutPath $shortcutPath `
    -AppId $appId `
    -TargetPath $targetPath `
    -Arguments '-NoProfile' `
    -Description 'Codex test shortcut'

  if (-not (Test-Path $shortcutPath)) {
    throw "Shortcut was not created: $shortcutPath"
  }

  $actualAppId = Get-CodexShortcutAppId -ShortcutPath $shortcutPath
  Assert-Equal $actualAppId $appId 'Shortcut AppUserModelID mismatch'

  $registration = Get-CodexToastRegistration
  if ([string]::IsNullOrWhiteSpace($registration.AppId)) {
    throw 'Registration AppId should not be empty.'
  }
  if ([string]::IsNullOrWhiteSpace($registration.ShortcutPath)) {
    throw 'Registration shortcut path should not be empty.'
  }

  Write-Host 'PASS tests/notify-codex-shortcut.test.ps1'
}
finally {
  if (Test-Path $tempDir) {
    Remove-Item -LiteralPath $tempDir -Recurse -Force
  }
}
