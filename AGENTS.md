# Project Memory

This file keeps the high-signal decisions for the project so future work does not lose context.

## Product Goal

Build a Windows desktop prototype that alerts the user when Codex in Windows Terminal needs attention.

The app must not interpret the meaning of the chat. It only reacts to a narrow set of attention states:

- waiting for user reply
- waiting for confirmation
- task finished and requesting attention

## User-Approved Product Shape

- Windows desktop app
- System tray icon
- Hidden by default
- Small transparent mascot window appears near the clock area when attention is needed
- Fisherman mascot rings rod bells, waves, and shows a speech bubble
- Speech bubble text: `Klyuet, podsekay!` / `Клюет, подсекай!`
- Repeat alerts if the user does not react
- Manual clear and automatic clear

## Confirmed Platform

- OS: Windows
- Terminal target for v1: Windows Terminal 1.23.20211.0
- App stack for v1: Electron

## Mascot Direction

- 2D desktop-pet style
- Based on the user's fishing look:
  - baseball cap
  - dark fishing suit
  - red-tinted polarized sunglasses
  - friendly smile
- Fish species: burbot (`Lota lota`, nalim)
- Prototype animation style:
  - idle
  - alert
  - waving hand
  - rod bend
  - bell jingle

## Current Visual Asset

- Generated mascot reference image:
  - `C:\project\ChatGPT Image 11 апр. 2026 г., 22_42_58.png`
- App mascot asset in use:
  - `C:\project\assets\mascot\fisherman-base.png`

This image is the current style reference for the mascot and should be preserved.

## Technical Decisions Locked for v1

- Use Electron for the prototype
- Keep the codebase in plain JavaScript ESM for v1 speed instead of adding a TypeScript build layer
- Use a tray app plus a transparent always-on-top mascot window
- Keep the app usable even if sound fails
- Keep the app usable even if automatic watcher clearing is uncertain
- Local watcher bridge listens on `http://127.0.0.1:43123/events`
- Include tray actions:
  - `Test alert`
  - `Mute sound`
  - `Pause watching`
  - `Exit`

## Watcher Strategy for v1

Direct generic inspection of arbitrary Windows Terminal content is not the first implementation target.

For v1, use a reliable helper-based watcher path:

- run Codex through a project-provided PowerShell helper in Windows Terminal
- stream Codex output through the helper
- detect only narrow service-style attention patterns
- forward those events into the Electron app
- when ordinary output resumes after an active alert, send a best-effort auto-clear event

This still satisfies the product goal for a working prototype while avoiding fragile OCR or deep terminal scraping.

## Out of Scope for v1

- deep Codex API integration
- semantic parsing of the conversation
- support for every Windows terminal app
- complex frame-by-frame animation pipeline
- auto-update

## Source of Truth

- Design spec:
  - `C:\project\docs\superpowers\specs\2026-04-11-codex-fishing-mascot-design.md`
- Next design spec:
  - `C:\project\docs\superpowers\specs\2026-04-11-universal-terminal-watcher-design.md`
- Implementation plan:
  - `C:\project\docs\superpowers\plans\2026-04-11-codex-fishing-mascot.md`
- Built artifacts:
  - `C:\project\dist\win-unpacked\Codex Fishing Mascot.exe`
  - `C:\project\dist\Codex Fishing Mascot 0.1.0.exe`

## Packaging Note

- `electron-builder` portable packaging required `signAndEditExecutable: false` in `electron-builder.json`
- default Electron icon is still in use for v1

## Approved Next Stage

- add a Windows-only universal terminal watcher
- discover candidate terminal windows
- let the user select from a list or manually pick a window
- use UI Automation first
- use Windows OCR as fallback
- detect only `Working` versus `Idle` in the first version of this watcher
- use the `Working (... esc to interrupt)` line as the primary activity signal
- optimize for low overhead:
  - watch only one selected window
  - poll roughly once per second
  - debounce state changes over two polls

## Universal Watcher Progress

Work is currently happening in the git worktree:

- `C:\project\.worktrees\universal-terminal-watcher`
- branch: `feature/universal-terminal-watcher`

Progress snapshot:

- Design spec written and committed:
  - `f9a5f86 docs: add universal terminal watcher design`
- Worktree setup and ignore rule committed on main:
  - `ab2dc72 chore: ignore project worktrees`
- Task 1 complete:
  - detector file: `src/main/activityDetector.js`
  - tests: `tests/unit/activityDetector.test.js`
  - commit: `dd47703 feat: add working-state detector`
- Task 2 mostly complete:
  - PowerShell scripts:
    - `scripts/list-terminal-windows.ps1`
    - `scripts/get-foreground-window.ps1`
  - JS bridge:
    - `src/main/windowsBridge.js`
    - `src/main/windowDiscovery.js`
  - tests:
    - `tests/unit/windowsBridge.test.js`
    - `tests/unit/windowDiscovery.test.js`
  - latest task commit: `e06435e feat: add terminal window discovery bridge`

Current stop point:

- Task 2 hardening fix is now applied.
- `windowsBridge.js` now launches PowerShell with:
  - `-NoProfile`
  - `-NonInteractive`
- Reason: stdout must stay clean for JSON parsing even if the user PowerShell profile prints text on startup.
- Focused verification completed and passed:
  - `npm test -- tests/unit/windowsBridge.test.js`
  - `npm test -- tests/unit/windowDiscovery.test.js`
- Next implementation step:
  - continue with the universal watcher UI and window selection flow

## Git State Reminder

- Main repository is already initialized and connected to GitHub:
  - `https://github.com/ArtemaO/Fisherman-mascot-tray`
- `origin/main` currently contains the prototype commit:
  - `bddd025 feat: add codex fishing mascot prototype`
- Local `main` is ahead of `origin/main` by two commits and has not been pushed yet:
  - `f9a5f86 docs: add universal terminal watcher design`
  - `ab2dc72 chore: ignore project worktrees`
- The universal watcher work is on a separate local feature branch/worktree and is also not pushed yet:
  - branch: `feature/universal-terminal-watcher`
  - current head: `e06435e feat: add terminal window discovery bridge`

## Workflow Rule

When a major product or technical decision changes, update this file in the same work session.

## Repository Note

At the time this file was created, `C:\project` was not a git repository.
