param(
  [string]$CodexCommand = "codex",
  [string]$EventUrl = "http://127.0.0.1:43123/events"
)

$alertPatterns = @(
  @{ Kind = "needs-confirmation"; Regex = "do you want to allow|confirm|approve" },
  @{ Kind = "finished"; Regex = "task complete|finished|waiting for your review" },
  @{ Kind = "needs-reply"; Regex = "^\?|reply|your input|waiting for response" }
)

$hasActiveAlert = $false

& $CodexCommand 2>&1 | ForEach-Object {
  $line = "$_"
  Write-Host $line

  $matched = $null
  foreach ($pattern in $alertPatterns) {
    if ($line -match $pattern.Regex) {
      $matched = $pattern
      break
    }
  }

  if ($null -ne $matched) {
    $payload = @{
      action = "activate"
      key = "$($matched.Kind):$line"
      kind = $matched.Kind
      sourceLine = $line
    } | ConvertTo-Json

    Invoke-RestMethod -Method Post -Uri $EventUrl -ContentType "application/json" -Body $payload | Out-Null
    $hasActiveAlert = $true
    return
  }

  if ($hasActiveAlert) {
    $payload = @{
      action = "clear"
      reason = "auto"
    } | ConvertTo-Json

    Invoke-RestMethod -Method Post -Uri $EventUrl -ContentType "application/json" -Body $payload | Out-Null
    $hasActiveAlert = $false
  }
}
