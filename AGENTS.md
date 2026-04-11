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
- Implementation plan:
  - `C:\project\docs\superpowers\plans\2026-04-11-codex-fishing-mascot.md`
- Built artifacts:
  - `C:\project\dist\win-unpacked\Codex Fishing Mascot.exe`
  - `C:\project\dist\Codex Fishing Mascot 0.1.0.exe`

## Packaging Note

- `electron-builder` portable packaging required `signAndEditExecutable: false` in `electron-builder.json`
- default Electron icon is still in use for v1

## Workflow Rule

When a major product or technical decision changes, update this file in the same work session.

## Repository Note

At the time this file was created, `C:\project` was not a git repository.
