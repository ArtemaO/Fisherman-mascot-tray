# Codex Direct Windows Notifier Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the legacy Electron watcher prototype with a minimal PowerShell-based Windows toast notifier that runs only when Codex explicitly asks for user attention.

**Architecture:** The implementation keeps all runtime behavior in PowerShell. A small library script maps attention kinds to user-facing text and builds toast XML with built-in WinRT APIs, while a thin CLI script acts as the public entrypoint. After the notifier works, the plan removes the old Electron and watcher stack so the repository matches the new product direction.

**Tech Stack:** PowerShell 5.1, built-in WinRT toast APIs, plain PowerShell test scripts, git

---

## Planned File Structure

- `AGENTS.md` - project memory for the notifier-first direction
- `README.md` - local usage instructions
- `.gitignore` - local-only ignore rules for the reduced repository
- `scripts/notify-codex.ps1` - public entrypoint for notifications
- `scripts/lib/notify-codex-lib.ps1` - reusable PowerShell functions for content mapping and toast display
- `tests/notify-codex.test.ps1` - unit-style checks for kind mapping and toast XML generation
- `tests/notify-codex-cli.test.ps1` - CLI smoke test using preview mode
- `tests/repo-layout.test.ps1` - cleanup check proving legacy Electron files are gone
- `docs/superpowers/specs/2026-04-13-codex-direct-windows-notifier-design.md` - approved design spec
- `docs/superpowers/plans/2026-04-13-codex-direct-windows-notifier.md` - this implementation plan
- `assets/mascot/fisherman-base.png` - preserved future mascot asset
- `ChatGPT Image 11 апр. 2026 г., 22_42_58.png` - preserved future mascot reference

## Task 1: Add the PowerShell notification library with tests

**Files:**
- Create: `scripts/lib/notify-codex-lib.ps1`
- Create: `tests/notify-codex.test.ps1`

- [ ] **Step 1: Write the failing library test**

```powershell
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

$reply = Get-CodexNotificationContent -Kind 'needs-reply'
Assert-Equal $reply.Title 'Codex' 'Reply title mismatch'
Assert-Equal $reply.Message 'Нужен ответ. Клюет, подсекай!' 'Reply message mismatch'
Assert-Equal $reply.AppId 'PowerShell' 'Reply AppId mismatch'

$confirmation = Get-CodexNotificationContent -Kind 'needs-confirmation'
Assert-Equal $confirmation.Message 'Нужно подтверждение. Клюет, подсекай!' 'Confirmation message mismatch'

$finished = Get-CodexNotificationContent -Kind 'finished'
Assert-Equal $finished.Message 'Задача завершена. Клюет, подсекай!' 'Finished message mismatch'

$xml = New-CodexToastXml -Content $reply -IncludeSound
$xmlString = $xml.GetXml()
if ($xmlString -notmatch 'Нужен ответ\. Клюет, подсекай!') {
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\notify-codex.test.ps1`
Expected: FAIL with `Missing library`

- [ ] **Step 3: Write the minimal notification library**

```powershell
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:CodexToastAppId = 'PowerShell'

function Get-CodexNotificationContent {
  param(
    [Parameter(Mandatory)]
    [ValidateSet('needs-reply', 'needs-confirmation', 'finished')]
    [string] $Kind
  )

  $message = switch ($Kind) {
    'needs-reply' { 'Нужен ответ. Клюет, подсекай!' }
    'needs-confirmation' { 'Нужно подтверждение. Клюет, подсекай!' }
    'finished' { 'Задача завершена. Клюет, подсекай!' }
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\notify-codex.test.ps1`
Expected: PASS with `PASS tests/notify-codex.test.ps1`

- [ ] **Step 5: Commit**

```bash
git add scripts/lib/notify-codex-lib.ps1 tests/notify-codex.test.ps1
git commit -m "feat: add powershell codex notification library"
```

## Task 2: Add the notifier entrypoint and operator docs

**Files:**
- Create: `scripts/notify-codex.ps1`
- Create: `tests/notify-codex-cli.test.ps1`
- Modify: `README.md`

- [ ] **Step 1: Write the failing CLI smoke test**

```powershell
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptPath = Join-Path $PSScriptRoot '..\scripts\notify-codex.ps1'
if (-not (Test-Path $scriptPath)) {
  throw "Missing script: $scriptPath"
}

$reply = & $scriptPath -Kind 'needs-reply' -Preview -NoSound
if ($reply.Kind -ne 'needs-reply') {
  throw "Unexpected reply kind: $($reply.Kind)"
}
if ($reply.Message -ne 'Нужен ответ. Клюет, подсекай!') {
  throw "Unexpected reply message: $($reply.Message)"
}

$finished = & $scriptPath -Kind 'finished' -Preview -NoSound
if ($finished.Message -ne 'Задача завершена. Клюет, подсекай!') {
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\notify-codex-cli.test.ps1`
Expected: FAIL with `Missing script`

- [ ] **Step 3: Add the public notifier script and update README**

```powershell
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
```

```md
# Fisherman Mascot Tray

Этот репозиторий теперь хранит минимальный Windows-нотификатор для Codex.

## Быстрый запуск

Показать уведомление о необходимости ответа:

`powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\notify-codex.ps1 -Kind needs-reply`

Показать уведомление о необходимости подтверждения:

`powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\notify-codex.ps1 -Kind needs-confirmation`

Показать уведомление о завершении задачи:

`powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\notify-codex.ps1 -Kind finished`

Отключить звук:

`powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\notify-codex.ps1 -Kind finished -NoSound`

## Проверка без показа toast

`powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\notify-codex.ps1 -Kind needs-reply -Preview`

## Тесты

`powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\notify-codex.test.ps1`

`powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\notify-codex-cli.test.ps1`
```

- [ ] **Step 4: Run tests and a manual smoke check**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\notify-codex.test.ps1`
Expected: PASS with `PASS tests/notify-codex.test.ps1`

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\notify-codex-cli.test.ps1`
Expected: PASS with `PASS tests/notify-codex-cli.test.ps1`

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\notify-codex.ps1 -Kind finished`
Expected: A Windows toast appears with `Codex` and `Задача завершена. Клюет, подсекай!`

- [ ] **Step 5: Commit**

```bash
git add scripts/notify-codex.ps1 tests/notify-codex-cli.test.ps1 README.md
git commit -m "feat: add direct codex notifier entrypoint"
```

## Task 3: Remove the legacy Electron and watcher implementation from the repository

**Files:**
- Modify: `.gitignore`
- Modify: `AGENTS.md`
- Modify: `README.md`
- Create: `tests/repo-layout.test.ps1`
- Delete: `docs/superpowers/plans/2026-04-11-codex-fishing-mascot.md`
- Delete: `docs/superpowers/specs/2026-04-11-codex-fishing-mascot-design.md`
- Delete: `docs/superpowers/specs/2026-04-11-universal-terminal-watcher-design.md`
- Delete: `electron-builder.json`
- Delete: `package-lock.json`
- Delete: `package.json`
- Delete: `playwright.config.js`
- Delete: `scripts/send-test-event.ps1`
- Delete: `scripts/start-codex-watcher.ps1`
- Delete: `src/main/alertState.js`
- Delete: `src/main/eventBridge.js`
- Delete: `src/main/index.js`
- Delete: `src/main/patternMatcher.js`
- Delete: `src/main/tray.js`
- Delete: `src/main/window.js`
- Delete: `src/preload/index.js`
- Delete: `src/renderer/mascot.css`
- Delete: `src/renderer/mascot.html`
- Delete: `src/renderer/mascot.js`
- Delete: `tests/e2e/mascot-window.spec.js`
- Delete: `tests/unit/alertState.test.js`
- Delete: `tests/unit/eventBridge.test.js`
- Delete: `tests/unit/patternMatcher.test.js`
- Delete: `vitest.config.mjs`

- [ ] **Step 1: Write the failing repository cleanup test**

```powershell
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot

$requiredPaths = @(
  'scripts/notify-codex.ps1',
  'scripts/lib/notify-codex-lib.ps1',
  'tests/notify-codex.test.ps1',
  'tests/notify-codex-cli.test.ps1',
  'README.md',
  'AGENTS.md'
)

$legacyPaths = @(
  'electron-builder.json',
  'package-lock.json',
  'package.json',
  'playwright.config.js',
  'scripts/send-test-event.ps1',
  'scripts/start-codex-watcher.ps1',
  'src/main/index.js',
  'src/renderer/mascot.html',
  'tests/e2e/mascot-window.spec.js',
  'tests/unit/alertState.test.js',
  'vitest.config.mjs',
  'docs/superpowers/plans/2026-04-11-codex-fishing-mascot.md',
  'docs/superpowers/specs/2026-04-11-codex-fishing-mascot-design.md',
  'docs/superpowers/specs/2026-04-11-universal-terminal-watcher-design.md'
)

foreach ($path in $requiredPaths) {
  $fullPath = Join-Path $repoRoot $path
  if (-not (Test-Path $fullPath)) {
    throw "Required path missing: $path"
  }
}

foreach ($path in $legacyPaths) {
  $fullPath = Join-Path $repoRoot $path
  if (Test-Path $fullPath) {
    throw "Legacy path still present: $path"
  }
}

Write-Host 'PASS tests/repo-layout.test.ps1'
```

- [ ] **Step 2: Run test to verify it fails**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\repo-layout.test.ps1`
Expected: FAIL with `Legacy path still present`

- [ ] **Step 3: Remove legacy files and reduce the repository**

```gitignore
.superpowers/
.worktrees/
.tmp/
.serena/
```

```md
# Fisherman Mascot Tray

Минимальный Windows-нотификатор для Codex.

## Что делает проект

Скрипт показывает стандартное Windows-уведомление только в трех состояниях:

- нужен ответ пользователя
- нужно подтверждение
- задача завершена

Проект намеренно не читает терминал и не держит резидентные процессы в фоне.

## Быстрый запуск

`powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\notify-codex.ps1 -Kind needs-reply`

`powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\notify-codex.ps1 -Kind needs-confirmation`

`powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\notify-codex.ps1 -Kind finished`

## Проверка

`powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\notify-codex.test.ps1`

`powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\notify-codex-cli.test.ps1`

`powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\repo-layout.test.ps1`
```

```bash
git rm docs/superpowers/plans/2026-04-11-codex-fishing-mascot.md
git rm docs/superpowers/specs/2026-04-11-codex-fishing-mascot-design.md
git rm docs/superpowers/specs/2026-04-11-universal-terminal-watcher-design.md
git rm electron-builder.json package-lock.json package.json playwright.config.js
git rm scripts/send-test-event.ps1 scripts/start-codex-watcher.ps1
git rm src/main/alertState.js src/main/eventBridge.js src/main/index.js src/main/patternMatcher.js src/main/tray.js src/main/window.js
git rm src/preload/index.js src/renderer/mascot.css src/renderer/mascot.html src/renderer/mascot.js
git rm tests/e2e/mascot-window.spec.js tests/unit/alertState.test.js tests/unit/eventBridge.test.js tests/unit/patternMatcher.test.js vitest.config.mjs
```

- [ ] **Step 4: Run the reduced test set**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\notify-codex.test.ps1`
Expected: PASS with `PASS tests/notify-codex.test.ps1`

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\notify-codex-cli.test.ps1`
Expected: PASS with `PASS tests/notify-codex-cli.test.ps1`

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\repo-layout.test.ps1`
Expected: PASS with `PASS tests/repo-layout.test.ps1`

- [ ] **Step 5: Commit**

```bash
git add .gitignore AGENTS.md README.md tests/repo-layout.test.ps1
git commit -m "refactor: remove legacy watcher and electron stack"
```

## Self-Review

### Spec coverage

- direct invocation from Codex workflow: covered in Tasks 1 and 2
- standard Windows toast: covered in Task 1
- narrow kinds `needs-reply`, `needs-confirmation`, `finished`: covered in Tasks 1 and 2
- no background runtime: covered by the library design in Task 1 and the cleanup in Task 3
- minimal repository without legacy watcher stack: covered in Task 3

### Placeholder scan

- No `TODO`, `TBD`, or deferred placeholders remain
- The WinRT toast mechanism is fixed explicitly in Task 1
- The cleanup scope is explicit and file-based in Task 3

### Type consistency

- The only supported kinds are `needs-reply`, `needs-confirmation`, and `finished`
- Library functions are `Get-CodexNotificationContent`, `New-CodexToastXml`, and `Show-CodexToast`
- CLI parameters are `Kind`, `NoSound`, and `Preview`
