# Codex Fishing Mascot Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an installable Electron-based Windows tray app that raises a fisherman mascot alert when a helper-watched Codex session needs user attention.

**Architecture:** The app uses an Electron main process for tray management, alert state, and a local event bridge; a lightweight renderer for the mascot window and animation; and a PowerShell helper that launches Codex inside Windows Terminal-compatible shells while forwarding only narrow attention events. The implementation keeps the product testable without deep terminal scraping by making the watcher path explicit and reliable.

**Tech Stack:** Electron, TypeScript, Node.js, Vitest, Playwright, electron-builder, PowerShell

---

## Planned File Structure

- `package.json` - project scripts and dependency manifest
- `tsconfig.json` - TypeScript configuration for main and renderer code
- `vitest.config.ts` - unit-test configuration
- `playwright.config.ts` - basic renderer smoke-test configuration
- `electron-builder.json` - Windows packaging configuration
- `assets/mascot/fisherman-base.png` - approved mascot art
- `assets/audio/bells.wav` - short bell-jingle alert sound
- `src/main/index.ts` - Electron app bootstrap
- `src/main/tray.ts` - tray icon and menu wiring
- `src/main/alertState.ts` - alert dedupe, repeat timing, and clear logic
- `src/main/patternMatcher.ts` - line-based attention pattern detection
- `src/main/eventBridge.ts` - local HTTP bridge for watcher events
- `src/main/window.ts` - mascot BrowserWindow creation and placement
- `src/preload/index.ts` - safe IPC bridge between main and renderer
- `src/shared/events.ts` - shared alert event types
- `src/renderer/mascot.html` - transparent mascot window markup
- `src/renderer/mascot.css` - mascot layout and animation classes
- `src/renderer/mascot.ts` - renderer-side alert state handling
- `scripts/start-codex-watcher.ps1` - PowerShell helper that runs Codex and emits app events
- `scripts/send-test-event.ps1` - manual event simulator for watcher testing
- `tests/unit/alertState.spec.ts` - unit tests for alert state manager
- `tests/unit/patternMatcher.spec.ts` - unit tests for line matcher
- `tests/e2e/mascot-window.spec.ts` - basic renderer smoke test
- `README.md` - local setup, run, and packaging instructions

## Task 1: Scaffold the Electron project

**Files:**
- Create: `package.json`
- Create: `tsconfig.json`
- Create: `vitest.config.ts`
- Create: `playwright.config.ts`
- Create: `electron-builder.json`
- Create: `src/main/index.ts`
- Create: `src/main/window.ts`
- Create: `src/preload/index.ts`
- Create: `src/renderer/mascot.html`
- Create: `src/renderer/mascot.css`
- Create: `src/renderer/mascot.ts`

- [ ] **Step 1: Write the failing bootstrap smoke test**

```ts
// tests/unit/bootstrap.spec.ts
import { existsSync } from 'node:fs';
import { describe, expect, it } from 'vitest';

describe('bootstrap files', () => {
  it('defines the Electron entrypoint', () => {
    expect(existsSync('src/main/index.ts')).toBe(true);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npx vitest run tests/unit/bootstrap.spec.ts`
Expected: FAIL with `expected false to be true`

- [ ] **Step 3: Add the minimal project scaffold**

```json
{
  "name": "codex-fishing-mascot",
  "version": "0.1.0",
  "private": true,
  "main": "dist/main/index.js",
  "scripts": {
    "build": "tsc && copyfiles -u 1 \"src/renderer/**/*.html\" \"src/renderer/**/*.css\" dist/renderer",
    "dev": "npm run build && electron .",
    "test": "vitest run",
    "test:e2e": "playwright test",
    "package:win": "npm run build && electron-builder --win portable"
  },
  "devDependencies": {
    "@playwright/test": "^1.55.0",
    "@types/node": "^24.0.0",
    "copyfiles": "^2.4.1",
    "electron": "^37.0.0",
    "electron-builder": "^26.0.0",
    "typescript": "^5.8.0",
    "vitest": "^3.2.0"
  }
}
```

```ts
// src/main/index.ts
import { app } from 'electron';
import { createMascotWindow } from './window';

app.whenReady().then(() => {
  createMascotWindow({ show: false });
});
```

```ts
// src/main/window.ts
import { BrowserWindow, screen } from 'electron';
import path from 'node:path';

export function createMascotWindow(options: { show: boolean }) {
  const display = screen.getPrimaryDisplay().workArea;
  const width = 320;
  const height = 320;
  const win = new BrowserWindow({
    width,
    height,
    x: display.x + display.width - width - 16,
    y: display.y + display.height - height - 16,
    frame: false,
    transparent: true,
    resizable: false,
    show: options.show,
    alwaysOnTop: true,
    skipTaskbar: true,
    webPreferences: {
      preload: path.join(process.cwd(), 'dist/preload/index.js'),
      contextIsolation: true,
      nodeIntegration: false
    }
  });

  win.loadFile(path.join(process.cwd(), 'dist/renderer/mascot.html'));
  return win;
}
```

```ts
// src/preload/index.ts
import { contextBridge, ipcRenderer } from 'electron';

contextBridge.exposeInMainWorld('codexMascot', {
  onShowAlert(handler: () => void) {
    ipcRenderer.on('alert:show', () => handler());
  },
  onRepeatAlert(handler: () => void) {
    ipcRenderer.on('alert:repeat', () => handler());
  },
  onHideAlert(handler: () => void) {
    ipcRenderer.on('alert:hide', () => handler());
  },
  dismissAlert() {
    ipcRenderer.send('alert:dismiss');
  }
});
```

```html
<!-- src/renderer/mascot.html -->
<!doctype html>
<html lang="ru">
  <head>
    <meta charset="UTF-8" />
    <title>Codex Mascot</title>
    <link rel="stylesheet" href="./mascot.css" />
  </head>
  <body>
    <div id="app" class="hidden">
      <img id="mascot" alt="Mascot" />
      <div id="bubble">Клюет, подсекай!</div>
    </div>
    <script type="module" src="./mascot.js"></script>
  </body>
</html>
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npx vitest run tests/unit/bootstrap.spec.ts`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add package.json tsconfig.json vitest.config.ts playwright.config.ts electron-builder.json src/main/index.ts src/main/window.ts src/preload/index.ts src/renderer/mascot.html src/renderer/mascot.css src/renderer/mascot.ts tests/unit/bootstrap.spec.ts
git commit -m "chore: scaffold electron mascot app"
```

## Task 2: Implement alert-state logic with TDD

**Files:**
- Create: `src/shared/events.ts`
- Create: `src/main/alertState.ts`
- Test: `tests/unit/alertState.spec.ts`

- [ ] **Step 1: Write the failing alert-state tests**

```ts
// tests/unit/alertState.spec.ts
import { describe, expect, it } from 'vitest';
import { createAlertState } from '../../src/main/alertState';

describe('alert state', () => {
  it('activates a new alert and deduplicates the same key', () => {
    const state = createAlertState({ repeatMs: 30000 });
    expect(state.raise({ key: 'reply', kind: 'needs-reply' })).toEqual({ changed: true, active: true });
    expect(state.raise({ key: 'reply', kind: 'needs-reply' })).toEqual({ changed: false, active: true });
  });

  it('clears the current alert manually', () => {
    const state = createAlertState({ repeatMs: 30000 });
    state.raise({ key: 'confirm', kind: 'needs-confirmation' });
    expect(state.clear('manual')).toEqual({ cleared: true, reason: 'manual' });
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npx vitest run tests/unit/alertState.spec.ts`
Expected: FAIL with `Cannot find module '../../src/main/alertState'`

- [ ] **Step 3: Write the minimal implementation**

```ts
// src/shared/events.ts
export type AlertKind = 'needs-reply' | 'needs-confirmation' | 'finished';

export interface AlertSignal {
  key: string;
  kind: AlertKind;
}
```

```ts
// src/main/alertState.ts
import type { AlertSignal } from '../shared/events';

export function createAlertState({ repeatMs }: { repeatMs: number }) {
  let active: AlertSignal | null = null;

  return {
    raise(signal: AlertSignal) {
      if (active?.key === signal.key) {
        return { changed: false, active: true };
      }
      active = signal;
      return { changed: true, active: true, repeatAt: Date.now() + repeatMs };
    },
    clear(reason: 'manual' | 'auto') {
      if (!active) {
        return { cleared: false, reason };
      }
      active = null;
      return { cleared: true, reason };
    },
    current() {
      return active;
    }
  };
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npx vitest run tests/unit/alertState.spec.ts`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/shared/events.ts src/main/alertState.ts tests/unit/alertState.spec.ts
git commit -m "feat: add alert state manager"
```

## Task 3: Add narrow Codex attention pattern matching

**Files:**
- Create: `src/main/patternMatcher.ts`
- Test: `tests/unit/patternMatcher.spec.ts`

- [ ] **Step 1: Write the failing matcher tests**

```ts
// tests/unit/patternMatcher.spec.ts
import { describe, expect, it } from 'vitest';
import { matchAttentionLine } from '../../src/main/patternMatcher';

describe('pattern matcher', () => {
  it('detects reply prompts', () => {
    expect(matchAttentionLine('?')).toMatchObject({ kind: 'needs-reply' });
  });

  it('detects confirmation prompts', () => {
    expect(matchAttentionLine('Do you want to allow this action?')).toMatchObject({ kind: 'needs-confirmation' });
  });

  it('detects task-finished prompts', () => {
    expect(matchAttentionLine('Task complete. Waiting for your review.')).toMatchObject({ kind: 'finished' });
  });

  it('ignores ordinary output', () => {
    expect(matchAttentionLine('Running tests...')).toBeNull();
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npx vitest run tests/unit/patternMatcher.spec.ts`
Expected: FAIL with `Cannot find module '../../src/main/patternMatcher'`

- [ ] **Step 3: Write the minimal matcher**

```ts
// src/main/patternMatcher.ts
import type { AlertSignal, AlertKind } from '../shared/events';

const RULES: Array<{ kind: AlertKind; test: RegExp }> = [
  { kind: 'needs-confirmation', test: /do you want to allow|confirm|approve/i },
  { kind: 'finished', test: /task complete|finished|waiting for your review/i },
  { kind: 'needs-reply', test: /^(\?|reply|your input|waiting for response)/i }
];

export function matchAttentionLine(line: string): AlertSignal | null {
  for (const rule of RULES) {
    if (rule.test.test(line.trim())) {
      return { key: `${rule.kind}:${line.trim()}`, kind: rule.kind };
    }
  }
  return null;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npx vitest run tests/unit/patternMatcher.spec.ts`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/main/patternMatcher.ts tests/unit/patternMatcher.spec.ts
git commit -m "feat: add codex attention matcher"
```

## Task 4: Add the local event bridge and PowerShell watcher helper

**Files:**
- Create: `src/main/eventBridge.ts`
- Create: `scripts/start-codex-watcher.ps1`
- Create: `scripts/send-test-event.ps1`
- Modify: `src/main/index.ts`

- [ ] **Step 1: Write the failing bridge test**

```ts
// tests/unit/eventBridge.spec.ts
import { describe, expect, it } from 'vitest';
import { parseBridgeBody } from '../../src/main/eventBridge';

describe('watcher payload', () => {
  it('parses a reply event payload', () => {
    expect(parseBridgeBody('{"key":"needs-reply:test","kind":"needs-reply"}')).toEqual({
      key: 'needs-reply:test',
      kind: 'needs-reply'
    });
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npx vitest run tests/unit/eventBridge.spec.ts`
Expected: FAIL with `Cannot find module '../../src/main/eventBridge'`

- [ ] **Step 3: Implement the local bridge and helper**

```ts
// src/main/eventBridge.ts
import http from 'node:http';
import type { AlertSignal } from '../shared/events';

export function parseBridgeBody(body: string): AlertSignal {
  return JSON.parse(body) as AlertSignal;
}

export function startEventBridge(onSignal: (signal: AlertSignal) => void) {
  const server = http.createServer((req, res) => {
    if (req.method !== 'POST' || req.url !== '/events') {
      res.statusCode = 404;
      res.end();
      return;
    }

    const chunks: Buffer[] = [];
    req.on('data', chunk => chunks.push(chunk));
    req.on('end', () => {
      const signal = parseBridgeBody(Buffer.concat(chunks).toString('utf8'));
      onSignal(signal);
      res.statusCode = 202;
      res.end('accepted');
    });
  });

  server.listen(43123, '127.0.0.1');
  return server;
}
```

```ts
// src/main/index.ts
import { app } from 'electron';
import { createAlertState } from './alertState';
import { startEventBridge } from './eventBridge';
import { createMascotWindow } from './window';

app.whenReady().then(() => {
  const alertState = createAlertState({ repeatMs: 30000 });
  const window = createMascotWindow({ show: false });

  startEventBridge(signal => {
    const result = alertState.raise(signal);
    if (result.changed) {
      window.webContents.send('alert:show', signal);
      window.showInactive();
    }
  });
});
```

```powershell
# scripts/start-codex-watcher.ps1
param(
  [string]$CodexCommand = "codex",
  [string]$EventUrl = "http://127.0.0.1:43123/events"
)

$patterns = @(
  @{ Kind = "needs-confirmation"; Regex = "do you want to allow|confirm|approve" },
  @{ Kind = "finished"; Regex = "task complete|finished|waiting for your review" },
  @{ Kind = "needs-reply"; Regex = "^\?|reply|your input|waiting for response" }
)

& $CodexCommand 2>&1 | ForEach-Object {
  $line = "$_"
  Write-Host $line
  foreach ($pattern in $patterns) {
    if ($line -match $pattern.Regex) {
      $payload = @{
        key = "$($pattern.Kind):$line"
        kind = $pattern.Kind
      } | ConvertTo-Json
      Invoke-RestMethod -Method Post -Uri $EventUrl -ContentType "application/json" -Body $payload | Out-Null
      break
    }
  }
}
```

```powershell
# scripts/send-test-event.ps1
param(
  [ValidateSet("needs-reply", "needs-confirmation", "finished")]
  [string]$Kind = "needs-reply",
  [string]$EventUrl = "http://127.0.0.1:43123/events"
)

$payload = @{
  key = "$Kind:test"
  kind = $Kind
} | ConvertTo-Json

Invoke-RestMethod -Method Post -Uri $EventUrl -ContentType "application/json" -Body $payload
```

- [ ] **Step 4: Run tests and manual helper check**

Run: `npx vitest run tests/unit/eventBridge.spec.ts`
Expected: PASS

Run: `powershell -ExecutionPolicy Bypass -File .\scripts\send-test-event.ps1 -Kind needs-reply`
Expected: `accepted`

- [ ] **Step 5: Commit**

```bash
git add src/main/eventBridge.ts src/main/index.ts scripts/start-codex-watcher.ps1 scripts/send-test-event.ps1 tests/unit/eventBridge.spec.ts
git commit -m "feat: add watcher bridge and powershell helper"
```

## Task 5: Implement the tray menu and mascot UI reactions

**Files:**
- Create: `src/main/tray.ts`
- Modify: `src/main/index.ts`
- Modify: `src/renderer/mascot.css`
- Modify: `src/renderer/mascot.ts`
- Create: `assets/mascot/fisherman-base.png`

- [ ] **Step 1: Write the failing renderer reaction test**

```ts
// tests/e2e/mascot-window.spec.ts
import { test, expect } from '@playwright/test';

test('speech bubble becomes visible on alert', async ({ page }) => {
  await page.goto('file://' + process.cwd() + '/dist/renderer/mascot.html');
  await page.evaluate(() => {
    window.dispatchEvent(new CustomEvent('mascot:test-alert'));
  });
  await expect(page.locator('#bubble')).toContainText('Клюет, подсекай!');
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm run build && npx playwright test tests/e2e/mascot-window.spec.ts`
Expected: FAIL because the bubble remains hidden or no handler exists

- [ ] **Step 3: Implement tray and renderer behavior**

```ts
// src/main/tray.ts
import { Menu, Tray, nativeImage } from 'electron';
import path from 'node:path';

export function createTray(actions: {
  onTestAlert: () => void;
  onToggleMute: () => void;
  onToggleWatching: () => void;
  onExit: () => void;
}) {
  const tray = new Tray(nativeImage.createFromPath(path.join(process.cwd(), 'assets', 'mascot', 'fisherman-base.png')));
  const menu = Menu.buildFromTemplate([
    { label: 'Test alert', click: actions.onTestAlert },
    { label: 'Mute sound', type: 'checkbox', click: actions.onToggleMute },
    { label: 'Pause watching', type: 'checkbox', click: actions.onToggleWatching },
    { type: 'separator' },
    { label: 'Exit', click: actions.onExit }
  ]);
  tray.setToolTip('Codex Fishing Mascot');
  tray.setContextMenu(menu);
  return tray;
}
```

```ts
// src/renderer/mascot.ts
const appEl = document.querySelector('#app') as HTMLDivElement;
const bubbleEl = document.querySelector('#bubble') as HTMLDivElement;
const mascotEl = document.querySelector('#mascot') as HTMLImageElement;

mascotEl.src = '../../assets/mascot/fisherman-base.png';

function showAlert() {
  appEl.classList.remove('hidden');
  appEl.classList.add('alert');
  bubbleEl.hidden = false;
}

window.addEventListener('mascot:test-alert', showAlert);
window.codexMascot?.onShowAlert(showAlert);
window.codexMascot?.onRepeatAlert(showAlert);
```

```css
/* src/renderer/mascot.css */
body {
  margin: 0;
  background: transparent;
  overflow: hidden;
}

#app.hidden {
  opacity: 0;
}

#app.alert {
  opacity: 1;
  animation: mascot-wave 0.8s ease-in-out infinite alternate;
}

#bubble {
  position: absolute;
  right: 0;
  top: 12px;
  padding: 10px 12px;
  border-radius: 8px;
  background: #fff8d6;
  color: #2c2418;
  font: 600 16px/1.2 "Segoe UI", sans-serif;
}

@keyframes mascot-wave {
  from { transform: translateY(0); }
  to { transform: translateY(-6px); }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npm run build && npx playwright test tests/e2e/mascot-window.spec.ts`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/main/tray.ts src/main/index.ts src/renderer/mascot.ts src/renderer/mascot.css assets/mascot/fisherman-base.png tests/e2e/mascot-window.spec.ts
git commit -m "feat: add tray controls and mascot ui"
```

## Task 6: Add alert sound, repeat alerts, and clear behavior

**Files:**
- Create: `assets/audio/bells.wav`
- Modify: `src/main/alertState.ts`
- Modify: `src/main/index.ts`
- Modify: `src/renderer/mascot.ts`
- Test: `tests/unit/alertState.spec.ts`

- [ ] **Step 1: Extend the failing alert-state tests**

```ts
it('marks a repeat as due after the interval', async () => {
  const state = createAlertState({ repeatMs: 1 });
  state.raise({ key: 'reply', kind: 'needs-reply' });
  await new Promise(resolve => setTimeout(resolve, 5));
  expect(state.isRepeatDue()).toBe(true);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npx vitest run tests/unit/alertState.spec.ts`
Expected: FAIL with `isRepeatDue is not a function`

- [ ] **Step 3: Implement repeat and clear wiring**

```ts
// src/main/alertState.ts
import type { AlertSignal } from '../shared/events';

export function createAlertState({ repeatMs }: { repeatMs: number }) {
  let active: AlertSignal | null = null;
  let repeatAt = 0;

  return {
    raise(signal: AlertSignal) {
      if (active?.key === signal.key) {
        return { changed: false, active: true };
      }
      active = signal;
      repeatAt = Date.now() + repeatMs;
      return { changed: true, active: true, repeatAt };
    },
    clear(reason: 'manual' | 'auto') {
      if (!active) return { cleared: false, reason };
      active = null;
      repeatAt = 0;
      return { cleared: true, reason };
    },
    isRepeatDue() {
      return !!active && Date.now() >= repeatAt;
    },
    bumpRepeat() {
      repeatAt = Date.now() + repeatMs;
    },
    current() {
      return active;
    }
  };
}
```

```ts
// src/main/index.ts
setInterval(() => {
  if (alertState.isRepeatDue() && alertState.current()) {
    window.webContents.send('alert:repeat', alertState.current());
    alertState.bumpRepeat();
  }
}, 1000);
```

```ts
// src/renderer/mascot.ts
const audio = new Audio('../../assets/audio/bells.wav');

function playBells() {
  audio.currentTime = 0;
  void audio.play().catch(() => undefined);
}

function showAlert() {
  appEl.classList.remove('hidden');
  appEl.classList.add('alert');
  bubbleEl.hidden = false;
  playBells();
}

appEl.addEventListener('click', () => {
  appEl.classList.remove('alert');
  appEl.classList.add('hidden');
  bubbleEl.hidden = true;
});
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `npx vitest run tests/unit/alertState.spec.ts`
Expected: PASS

Run: `npm run build && npx playwright test tests/e2e/mascot-window.spec.ts`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add assets/audio/bells.wav src/main/alertState.ts src/main/index.ts src/renderer/mascot.ts tests/unit/alertState.spec.ts
git commit -m "feat: add repeat alerts and bell sound"
```

## Task 7: Package the app and document the watcher workflow

**Files:**
- Create: `README.md`
- Modify: `electron-builder.json`
- Modify: `package.json`

- [ ] **Step 1: Write the failing packaging check**

```ts
// tests/unit/packageScripts.spec.ts
import { describe, expect, it } from 'vitest';
import pkg from '../../package.json';

describe('package scripts', () => {
  it('defines a Windows packaging command', () => {
    expect(pkg.scripts['package:win']).toBeTruthy();
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npx vitest run tests/unit/packageScripts.spec.ts`
Expected: FAIL if the packaging script is missing or malformed

- [ ] **Step 3: Add packaging config and operator docs**

```json
{
  "appId": "com.codex.fishingmascot",
  "productName": "Codex Fishing Mascot",
  "files": [
    "dist/**/*",
    "assets/**/*",
    "scripts/start-codex-watcher.ps1"
  ],
  "win": {
    "target": ["portable"]
  }
}
```

```md
# Codex Fishing Mascot

## Run locally

1. `npm install`
2. `npm run dev`
3. In another Windows Terminal tab, run:
   `powershell -ExecutionPolicy Bypass -File .\scripts\start-codex-watcher.ps1`

## Send a test alert

`powershell -ExecutionPolicy Bypass -File .\scripts\send-test-event.ps1 -Kind needs-reply`

## Build a Windows portable app

`npm run package:win`
```

- [ ] **Step 4: Run tests and package build**

Run: `npx vitest run tests/unit/packageScripts.spec.ts`
Expected: PASS

Run: `npm run package:win`
Expected: PASS and create a Windows portable build under `dist/` or `release/`

- [ ] **Step 5: Commit**

```bash
git add README.md electron-builder.json package.json tests/unit/packageScripts.spec.ts
git commit -m "docs: add packaging and watcher workflow"
```

## Self-Review

### Spec coverage

- Windows tray app: covered in Tasks 1, 5, and 7
- Transparent mascot window near tray: covered in Tasks 1 and 5
- Codex attention detection without semantic parsing: covered in Tasks 3 and 4
- Bell sound, waving, and speech bubble: covered in Tasks 5 and 6
- Repeat alerts: covered in Task 6
- Manual and automatic clearing: covered in Tasks 2 and 6
- Manual test alert: covered in Tasks 4 and 5
- Installable Windows build: covered in Task 7

### Placeholder scan

- No `TODO`, `TBD`, or "implement later" placeholders remain
- Open design questions were resolved in this plan:
  - watcher strategy: helper-based PowerShell bridge
  - packaging format: Windows portable build
  - repeat alert handling: timer-based repeat in Electron main process

### Type consistency

- Shared alert kinds are `needs-reply`, `needs-confirmation`, and `finished`
- Shared payload type is `AlertSignal`
- Alert-state methods are `raise`, `clear`, `current`, `isRepeatDue`, and `bumpRepeat`
