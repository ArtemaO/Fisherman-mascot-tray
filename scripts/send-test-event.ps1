param(
  [ValidateSet("needs-reply", "needs-confirmation", "finished")]
  [string]$Kind = "needs-reply",
  [string]$EventUrl = "http://127.0.0.1:43123/events"
)

$payload = @{
  action = "activate"
  key = "$Kind:test"
  kind = $Kind
  sourceLine = "manual test"
} | ConvertTo-Json

Invoke-RestMethod -Method Post -Uri $EventUrl -ContentType "application/json" -Body $payload
