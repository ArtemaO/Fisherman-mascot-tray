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
