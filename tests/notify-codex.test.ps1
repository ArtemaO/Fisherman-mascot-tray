Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Decode-Utf8Base64 {
  param(
    [Parameter(Mandatory)] [string] $Value
  )

  [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Value))
}

$replyMessage = Decode-Utf8Base64 '0J3Rg9C20LXQvSDQvtGC0LLQtdGCLiDQmtC70Y7QtdGCLCDQv9C+0LTRgdC10LrQsNC5IQ=='
$confirmationMessage = Decode-Utf8Base64 '0J3Rg9C20L3QviDQv9C+0LTRgtCy0LXRgNC20LTQtdC90LjQtS4g0JrQu9GO0LXRgiwg0L/QvtC00YHQtdC60LDQuSE='
$finishedMessage = Decode-Utf8Base64 '0JfQsNC00LDRh9CwINC30LDQstC10YDRiNC10L3QsC4g0JrQu9GO0LXRgiwg0L/QvtC00YHQtdC60LDQuSE='

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

$reply = Get-CodexNotificationContent -Kind 'needs-reply'
Assert-Equal $reply.Title 'Codex' 'Reply title mismatch'
Assert-Equal $reply.Message $replyMessage 'Reply message mismatch'
Assert-Equal $reply.AppId 'PowerShell' 'Reply AppId mismatch'

$confirmation = Get-CodexNotificationContent -Kind 'needs-confirmation'
Assert-Equal $confirmation.Message $confirmationMessage 'Confirmation message mismatch'

$finished = Get-CodexNotificationContent -Kind 'finished'
Assert-Equal $finished.Message $finishedMessage 'Finished message mismatch'

$xml = New-CodexToastXml -Content $reply -IncludeSound
$xmlString = $xml.GetXml()
if ($xmlString -notmatch [regex]::Escape($replyMessage)) {
  throw "Toast XML does not contain reply message.`n$xmlString"
}
if ($xmlString -notmatch 'ms-winsoundevent:Notification.Default') {
  throw "Toast XML does not contain default notification sound.`n$xmlString"
}

$invalidFailed = $false
try {
  Get-CodexNotificationContent -Kind 'invalid-kind' -ErrorAction Stop | Out-Null
} catch {
  $invalidFailed = $true
}

if (-not $invalidFailed) {
  throw 'Invalid kind should fail.'
}

Write-Host 'PASS tests/notify-codex.test.ps1'
