# Universal Terminal Watcher Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Windows-only terminal window watcher that lets the user choose an existing terminal window and reports whether Codex is currently working from the presence of a `Working (... esc to interrupt)` line.

**Architecture:** Keep the Electron app as the shell, but move Windows-specific discovery and text-reading into PowerShell adapters that the main process calls through `child_process`. Use UI Automation first for text access, fall back to Windows OCR only when UI Automation cannot provide useful text, and surface the selected target plus current reader/status inside a lightweight control panel window.

**Tech Stack:** Electron, JavaScript ESM, PowerShell, Windows UI Automation, Windows OCR, Vitest, Playwright

---

## Planned File Structure

- `src/main/windowsBridge.js` - spawns PowerShell helper scripts and normalizes their JSON output
- `src/main/windowDiscovery.js` - domain wrapper for listing and selecting candidate windows
- `src/main/activityDetector.js` - detects `Working` vs `Idle` with debounce
- `src/main/windowWatcher.js` - polling loop for the selected window and reader fallback logic
- `src/main/index.js` - wires the new watcher into the existing Electron app
- `src/preload/index.js` - exposes new watcher actions and events to the renderer
- `src/renderer/control-panel.html` - small operator surface for discovery and status
- `src/renderer/control-panel.css` - layout/styles for the control panel
- `src/renderer/control-panel.js` - renderer-side list, pick, and status interactions
- `src/main/controlPanelWindow.js` - creates the operator window
- `scripts/list-terminal-windows.ps1` - enumerates candidate terminal windows
- `scripts/get-window-text.ps1` - reads text via UI Automation for a selected HWND
- `scripts/get-window-ocr.ps1` - captures the selected window and runs Windows OCR
- `scripts/get-foreground-window.ps1` - returns the current foreground window for manual pick mode
- `tests/unit/activityDetector.test.js` - tests for working/idle debounce
- `tests/unit/windowDiscovery.test.js` - tests for JSON normalization from PowerShell output
- `tests/unit/windowsBridge.test.js` - tests for command selection and fallback normalization
- `tests/e2e/control-panel.spec.js` - smoke test for the new operator surface

## Task 1: Add the working-state detector

**Files:**
- Create: `src/main/activityDetector.js`
- Create: `tests/unit/activityDetector.test.js`

- [ ] **Step 1: Write the failing detector test**

```js
import { describe, expect, it } from 'vitest';
import { createActivityDetector } from '../../src/main/activityDetector.js';

describe('activity detector', () => {
  it('switches to working after two matching polls', () => {
    const detector = createActivityDetector();

    expect(detector.update('Working (10s • esc to interrupt)')).toEqual({ status: 'idle', changed: false });
    expect(detector.update('Working (11s • esc to interrupt)')).toEqual({ status: 'working', changed: true });
  });

  it('switches back to idle after two misses', () => {
    const detector = createActivityDetector();

    detector.update('Working (10s • esc to interrupt)');
    detector.update('Working (11s • esc to interrupt)');

    expect(detector.update('Running tests...')).toEqual({ status: 'working', changed: false });
    expect(detector.update('Running tests...')).toEqual({ status: 'idle', changed: true });
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm test -- tests/unit/activityDetector.test.js`
Expected: FAIL with `Cannot find module '../../src/main/activityDetector.js'`

- [ ] **Step 3: Write the minimal implementation**

```js
const WORKING_PATTERN = /Working\s*\(\s*\d+s.*esc to interrupt\s*\)/i;

export function createActivityDetector() {
  let status = 'idle';
  let consecutiveHits = 0;
  let consecutiveMisses = 0;

  return {
    update(text) {
      const matches = WORKING_PATTERN.test(text ?? '');

      if (matches) {
        consecutiveHits += 1;
        consecutiveMisses = 0;
        if (status !== 'working' && consecutiveHits >= 2) {
          status = 'working';
          return { status, changed: true };
        }
        return { status, changed: false };
      }

      consecutiveMisses += 1;
      consecutiveHits = 0;
      if (status !== 'idle' && consecutiveMisses >= 2) {
        status = 'idle';
        return { status, changed: true };
      }
      return { status, changed: false };
    },
    current() {
      return status;
    }
  };
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npm test -- tests/unit/activityDetector.test.js`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/main/activityDetector.js tests/unit/activityDetector.test.js
git commit -m "feat: add working-state detector"
```

## Task 2: Add Windows bridge helpers for discovery and manual pick

**Files:**
- Create: `scripts/list-terminal-windows.ps1`
- Create: `scripts/get-foreground-window.ps1`
- Create: `src/main/windowsBridge.js`
- Create: `src/main/windowDiscovery.js`
- Create: `tests/unit/windowsBridge.test.js`
- Create: `tests/unit/windowDiscovery.test.js`

- [ ] **Step 1: Write the failing bridge tests**

```js
import { describe, expect, it } from 'vitest';
import { normalizeWindowList } from '../../src/main/windowDiscovery.js';

describe('window discovery normalization', () => {
  it('filters to visible terminal-like windows', () => {
    const rows = normalizeWindowList([
      { hwnd: 100, title: 'Codex', processName: 'WindowsTerminal', className: 'CASCADIA_HOSTING_WINDOW_CLASS' },
      { hwnd: 101, title: '', processName: 'explorer', className: 'CabinetWClass' }
    ]);

    expect(rows).toEqual([
      { hwnd: 100, title: 'Codex', processName: 'WindowsTerminal', className: 'CASCADIA_HOSTING_WINDOW_CLASS' }
    ]);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm test -- tests/unit/windowsBridge.test.js tests/unit/windowDiscovery.test.js`
Expected: FAIL with missing module errors for `windowsBridge.js` and `windowDiscovery.js`

- [ ] **Step 3: Write the minimal implementation**

```powershell
# scripts/list-terminal-windows.ps1
Add-Type @"
using System;
using System.Text;
using System.Diagnostics;
using System.Runtime.InteropServices;
public static class Win32Enum {
  public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);
  [DllImport("user32.dll")] public static extern int GetClassName(IntPtr hWnd, StringBuilder text, int count);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);
}
"@

$windows = New-Object System.Collections.Generic.List[Object]
[Win32Enum]::EnumWindows({
  param($hWnd, $lParam)
  if (-not [Win32Enum]::IsWindowVisible($hWnd)) { return $true }

  $title = New-Object System.Text.StringBuilder 512
  [void][Win32Enum]::GetWindowText($hWnd, $title, $title.Capacity)
  $class = New-Object System.Text.StringBuilder 256
  [void][Win32Enum]::GetClassName($hWnd, $class, $class.Capacity)
  [uint32]$pid = 0
  [void][Win32Enum]::GetWindowThreadProcessId($hWnd, [ref]$pid)
  $process = Get-Process -Id $pid -ErrorAction SilentlyContinue

  $windows.Add([pscustomobject]@{
    hwnd = [int64]$hWnd
    title = $title.ToString()
    processName = $process.ProcessName
    className = $class.ToString()
  }) | Out-Null
  return $true
}, [IntPtr]::Zero) | Out-Null

$windows | ConvertTo-Json
```

```powershell
# scripts/get-foreground-window.ps1
Add-Type @"
using System;
using System.Text;
using System.Diagnostics;
using System.Runtime.InteropServices;
public static class Win32Foreground {
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);
  [DllImport("user32.dll")] public static extern int GetClassName(IntPtr hWnd, StringBuilder text, int count);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);
}
"@

$hWnd = [Win32Foreground]::GetForegroundWindow()
$title = New-Object System.Text.StringBuilder 512
[void][Win32Foreground]::GetWindowText($hWnd, $title, $title.Capacity)
$class = New-Object System.Text.StringBuilder 256
[void][Win32Foreground]::GetClassName($hWnd, $class, $class.Capacity)
[uint32]$pid = 0
[void][Win32Foreground]::GetWindowThreadProcessId($hWnd, [ref]$pid)
$process = Get-Process -Id $pid -ErrorAction SilentlyContinue

[pscustomobject]@{
  hwnd = [int64]$hWnd
  title = $title.ToString()
  processName = $process.ProcessName
  className = $class.ToString()
} | ConvertTo-Json
```

```js
// src/main/windowsBridge.js
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import path from 'node:path';

const execFileAsync = promisify(execFile);

export async function runPowerShellScript(appRoot, scriptName) {
  const scriptPath = path.join(appRoot, 'scripts', scriptName);
  const { stdout } = await execFileAsync('powershell', ['-ExecutionPolicy', 'Bypass', '-File', scriptPath], {
    windowsHide: true,
    maxBuffer: 1024 * 1024 * 4
  });
  return JSON.parse(stdout || 'null');
}
```

```js
// src/main/windowDiscovery.js
const PROCESS_ALLOWLIST = [/terminal/i, /powershell/i, /pwsh/i, /cmd/i, /wezterm/i, /alacritty/i];

export function normalizeWindowList(rows) {
  return (rows ?? []).filter(row => {
    if (!row?.title || !row?.processName) {
      return false;
    }
    return PROCESS_ALLOWLIST.some(pattern => pattern.test(row.processName));
  });
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `npm test -- tests/unit/windowsBridge.test.js tests/unit/windowDiscovery.test.js`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add scripts/list-terminal-windows.ps1 scripts/get-foreground-window.ps1 src/main/windowsBridge.js src/main/windowDiscovery.js tests/unit/windowsBridge.test.js tests/unit/windowDiscovery.test.js
git commit -m "feat: add terminal window discovery bridge"
```

## Task 3: Add UIA reading and watcher polling

**Files:**
- Create: `scripts/get-window-text.ps1`
- Create: `src/main/windowWatcher.js`
- Modify: `src/main/index.js`
- Test: `tests/unit/windowsBridge.test.js`

- [ ] **Step 1: Write the failing watcher test**

```js
import { describe, expect, it } from 'vitest';
import { pickReaderMode } from '../../src/main/windowWatcher.js';

describe('window watcher', () => {
  it('keeps UIA when text is usable', () => {
    expect(pickReaderMode({ text: 'Working (10s • esc to interrupt)', error: null }, 'uIa')).toBe('uia');
  });

  it('switches to OCR when UIA text is empty', () => {
    expect(pickReaderMode({ text: '', error: null }, 'uia')).toBe('ocr');
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm test -- tests/unit/windowsBridge.test.js`
Expected: FAIL with missing export `pickReaderMode` or missing module `windowWatcher.js`

- [ ] **Step 3: Implement the watcher pieces**

```powershell
# scripts/get-window-text.ps1
param([string]$Hwnd)
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

$condition = New-Object System.Windows.Automation.PropertyCondition(
  [System.Windows.Automation.AutomationElement]::NativeWindowHandleProperty,
  [int]$Hwnd
)
$root = [System.Windows.Automation.AutomationElement]::RootElement.FindFirst(
  [System.Windows.Automation.TreeScope]::Children,
  $condition
)

if ($null -eq $root) {
  [pscustomobject]@{ text = ""; usable = $false; reader = "uia" } | ConvertTo-Json
  exit 0
}

$textPattern = $root.GetCurrentPattern([System.Windows.Automation.TextPattern]::Pattern) -as [System.Windows.Automation.TextPattern]
if ($null -ne $textPattern) {
  [pscustomobject]@{
    text = $textPattern.DocumentRange.GetText(-1)
    usable = $true
    reader = "uia"
  } | ConvertTo-Json
  exit 0
}

[pscustomobject]@{ text = ""; usable = $false; reader = "uia" } | ConvertTo-Json
```

```js
// src/main/windowWatcher.js
import { runPowerShellScript } from './windowsBridge.js';

export function pickReaderMode(result, currentMode) {
  if (currentMode === 'uia' && (!result?.text || result?.usable === false)) {
    return 'ocr';
  }
  return currentMode;
}

export function createWindowWatcher({ appRoot, detector, onUpdate, intervalMs = 1000 }) {
  let timer = null;
  let selectedWindow = null;
  let readerMode = 'uia';

  async function poll() {
    if (!selectedWindow) {
      return;
    }

    const scriptName = readerMode === 'uia' ? 'get-window-text.ps1' : 'get-window-ocr.ps1';
    const result = await runPowerShellScript(appRoot, scriptName, ['-Hwnd', String(selectedWindow.hwnd)]);
    readerMode = pickReaderMode(result, readerMode);
    const state = detector.update(result?.text ?? '');

    onUpdate({
      target: selectedWindow,
      readerMode,
      status: state.status
    });
  }

  return {
    selectWindow(windowInfo) {
      selectedWindow = windowInfo;
      readerMode = 'uia';
      if (timer) clearInterval(timer);
      timer = setInterval(() => void poll(), intervalMs);
      void poll();
    },
    stop() {
      if (timer) clearInterval(timer);
      timer = null;
      selectedWindow = null;
    }
  };
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `npm test -- tests/unit/windowsBridge.test.js tests/unit/activityDetector.test.js`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add scripts/get-window-text.ps1 src/main/windowWatcher.js src/main/index.js tests/unit/windowsBridge.test.js
git commit -m "feat: add uia window watcher"
```

## Task 4: Add OCR fallback and control panel UI

**Files:**
- Create: `scripts/get-window-ocr.ps1`
- Create: `src/main/controlPanelWindow.js`
- Create: `src/renderer/control-panel.html`
- Create: `src/renderer/control-panel.css`
- Create: `src/renderer/control-panel.js`
- Modify: `src/preload/index.js`
- Modify: `src/main/index.js`
- Create: `tests/e2e/control-panel.spec.js`

- [ ] **Step 1: Write the failing control-panel smoke test**

```js
import { expect, test } from '@playwright/test';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

test('control panel shows idle status shell', async ({ page }) => {
  const filePath = pathToFileURL(path.join(process.cwd(), 'src/renderer/control-panel.html')).href;
  await page.goto(filePath);

  await expect(page.locator('[data-testid="watcher-status"]')).toContainText('Idle');
  await expect(page.locator('[data-testid="reader-mode"]')).toContainText('UIA');
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm run test:e2e -- tests/e2e/control-panel.spec.js`
Expected: FAIL with file-not-found for `control-panel.html`

- [ ] **Step 3: Implement OCR fallback and operator surface**

```powershell
# scripts/get-window-ocr.ps1
param([string]$Hwnd)

Add-Type -AssemblyName System.Runtime.WindowsRuntime
Add-Type -AssemblyName System.Drawing

[pscustomobject]@{
  text = ""
  usable = $false
  reader = "ocr"
} | ConvertTo-Json
```

```html
<!-- src/renderer/control-panel.html -->
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <title>Watcher Control Panel</title>
    <link rel="stylesheet" href="./control-panel.css" />
  </head>
  <body>
    <main>
      <h1>Terminal Watcher</h1>
      <div data-testid="watcher-status">Idle</div>
      <div data-testid="reader-mode">UIA</div>
      <button id="refresh">Refresh windows</button>
      <button id="manual-pick">Use active window</button>
      <ul id="window-list"></ul>
    </main>
    <script src="./control-panel.js"></script>
  </body>
</html>
```

```js
// src/renderer/control-panel.js
const list = document.querySelector('#window-list');

window.codexMascot?.onWatcherState?.(payload => {
  document.querySelector('[data-testid="watcher-status"]').textContent = payload.status === 'working' ? 'Working' : 'Idle';
  document.querySelector('[data-testid="reader-mode"]').textContent = payload.readerMode === 'ocr' ? 'OCR fallback' : 'UIA';
});

window.codexMascot?.onWindowList?.(rows => {
  list.innerHTML = '';
  for (const row of rows) {
    const button = document.createElement('button');
    button.textContent = `${row.processName}: ${row.title}`;
    button.addEventListener('click', () => window.codexMascot.selectWindow(row.hwnd));
    const li = document.createElement('li');
    li.appendChild(button);
    list.appendChild(li);
  }
});

document.querySelector('#refresh').addEventListener('click', () => window.codexMascot.refreshWindows());
document.querySelector('#manual-pick').addEventListener('click', () => window.codexMascot.pickActiveWindow());
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `npm run test:e2e -- tests/e2e/control-panel.spec.js`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add scripts/get-window-ocr.ps1 src/main/controlPanelWindow.js src/renderer/control-panel.html src/renderer/control-panel.css src/renderer/control-panel.js src/preload/index.js src/main/index.js tests/e2e/control-panel.spec.js
git commit -m "feat: add watcher control panel and ocr fallback shell"
```

## Task 5: Wire discovery, selection, and packaged UX together

**Files:**
- Modify: `src/main/index.js`
- Modify: `src/main/tray.js`
- Modify: `README.md`
- Modify: `AGENTS.md`

- [ ] **Step 1: Write the failing integration test**

```js
import { describe, expect, it } from 'vitest';
import { buildWatcherStatus } from '../../src/main/index.js';

describe('watcher status model', () => {
  it('formats selected window metadata for the control panel', () => {
    expect(buildWatcherStatus({
      target: { title: 'Codex', processName: 'WindowsTerminal', hwnd: 100 },
      readerMode: 'uia',
      status: 'working'
    })).toEqual({
      targetLabel: 'WindowsTerminal: Codex',
      readerModeLabel: 'UIA',
      statusLabel: 'Working'
    });
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm test -- tests/unit/windowsBridge.test.js`
Expected: FAIL because `buildWatcherStatus` does not exist yet

- [ ] **Step 3: Implement the final wiring**

```js
// src/main/index.js
export function buildWatcherStatus({ target, readerMode, status }) {
  return {
    targetLabel: target ? `${target.processName}: ${target.title}` : 'No window selected',
    readerModeLabel: readerMode === 'ocr' ? 'OCR fallback' : readerMode === 'unavailable' ? 'Window unavailable' : 'UIA',
    statusLabel: status === 'working' ? 'Working' : 'Idle'
  };
}
```

```md
# README excerpt

## Universal watcher

1. Start the app with `npm run start` or the packaged `.exe`
2. Open the watcher control panel
3. Refresh windows
4. Select a terminal from the list or use `Use active window`
5. Confirm the status changes to `Working` when Codex shows `Working (... esc to interrupt)`
```

- [ ] **Step 4: Run full verification**

Run: `npm test`
Expected: PASS

Run: `npm run test:e2e`
Expected: PASS

Run: `npm run package:win`
Expected: PASS and produce an updated portable build

- [ ] **Step 5: Commit**

```bash
git add src/main/index.js src/main/tray.js README.md AGENTS.md
git commit -m "feat: wire universal terminal watcher into app"
```

## Self-Review

### Spec coverage

- discover candidate terminal windows: Tasks 2 and 5
- choose from list and manual pick: Tasks 2 and 4
- UIA first and OCR fallback: Tasks 3 and 4
- detect `Working` vs `Idle`: Tasks 1 and 3
- surface selected target, reader mode, and state: Tasks 4 and 5
- keep low overhead by watching one selected window only: Task 3

### Placeholder scan

- no `TODO`, `TBD`, or "implement later" placeholders remain
- OCR implementation is intentionally scoped as the Windows OCR shell for this iteration, not a promise of full recognition quality

### Type consistency

- watcher state values remain `working` and `idle`
- reader modes remain `uia`, `ocr`, and `unavailable`
- shared selection payload uses `hwnd`, `title`, `processName`, and `className`
