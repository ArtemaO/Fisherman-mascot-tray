Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:CodexToastAppId = 'PowerShell'

function Decode-CodexUtf8Base64 {
  param(
    [Parameter(Mandatory)]
    [string] $Value
  )

  [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Value))
}

function Get-CodexNotificationContent {
  param(
    [Parameter(Mandatory)]
    [ValidateSet('needs-reply', 'needs-confirmation', 'finished')]
    [string] $Kind
  )

  $message = switch ($Kind) {
    'needs-reply' { Decode-CodexUtf8Base64 '0J3Rg9C20LXQvSDQvtGC0LLQtdGCLiDQmtC70Y7QtdGCLCDQv9C+0LTRgdC10LrQsNC5IQ==' }
    'needs-confirmation' { Decode-CodexUtf8Base64 '0J3Rg9C20L3QviDQv9C+0LTRgtCy0LXRgNC20LTQtdC90LjQtS4g0JrQu9GO0LXRgiwg0L/QvtC00YHQtdC60LDQuSE=' }
    'finished' { Decode-CodexUtf8Base64 '0JfQsNC00LDRh9CwINC30LDQstC10YDRiNC10L3QsC4g0JrQu9GO0LXRgiwg0L/QvtC00YHQtdC60LDQuSE=' }
  }

  [pscustomobject]@{
    Kind    = $Kind
    Title   = 'Codex'
    Message = $message
    AppId   = $script:CodexToastAppId
  }
}

function New-CodexToastXml {
  param(
    [Parameter(Mandatory)]
    [psobject] $Content,

    [switch] $IncludeSound
  )

  [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

  $title = [System.Security.SecurityElement]::Escape([string] $Content.Title)
  $message = [System.Security.SecurityElement]::Escape([string] $Content.Message)
  $audioXml = if ($IncludeSound) {
    '<audio src="ms-winsoundevent:Notification.Default" />'
  } else {
    '<audio silent="true" />'
  }

  $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
  $xml.LoadXml("<toast><visual><binding template=`"ToastGeneric`"><text>$title</text><text>$message</text></binding></visual>$audioXml</toast>")
  return $xml
}

function Show-CodexToast {
  param(
    [Parameter(Mandatory)]
    [ValidateSet('needs-reply', 'needs-confirmation', 'finished')]
    [string] $Kind,

    [switch] $NoSound
  )

  [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
  [Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null

  $content = Get-CodexNotificationContent -Kind $Kind
  $xml = New-CodexToastXml -Content $content -IncludeSound:(-not $NoSound)
  $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
  $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($content.AppId)
  $notifier.Show($toast)
  return $content
}
