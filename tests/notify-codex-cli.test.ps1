Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Decode-Utf8Base64 {
  param(
    [Parameter(Mandatory)] [string] $Value
  )

  [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Value))
}

$replyMessage = Decode-Utf8Base64 '0J3Rg9C20LXQvSDQvtGC0LLQtdGCLiDQmtC70Y7QtdGCLCDQv9C+0LTRgdC10LrQsNC5IQ=='
$finishedMessage = Decode-Utf8Base64 '0JfQsNC00LDRh9CwINC30LDQstC10YDRiNC10L3QsC4g0JrQu9GO0LXRgiwg0L/QvtC00YHQtdC60LDQuSE='

$scriptPath = Join-Path $PSScriptRoot '..\scripts\notify-codex.ps1'
if (-not (Test-Path $scriptPath)) {
  throw "Missing script: $scriptPath"
}

$reply = & $scriptPath -Kind 'needs-reply' -Preview -NoSound
if ($reply.Kind -ne 'needs-reply') {
  throw "Unexpected reply kind: $($reply.Kind)"
}
if ($reply.Message -ne $replyMessage) {
  throw "Unexpected reply message: $($reply.Message)"
}

$finished = & $scriptPath -Kind 'finished' -Preview -NoSound
if ($finished.Message -ne $finishedMessage) {
  throw "Unexpected finished message: $($finished.Message)"
}

$invalidFailed = $false
try {
  & $scriptPath -Kind 'wrong' -Preview -ErrorAction Stop | Out-Null
} catch {
  $invalidFailed = $true
}

if (-not $invalidFailed) {
  throw 'CLI should reject invalid kind.'
}

Write-Host 'PASS tests/notify-codex-cli.test.ps1'
