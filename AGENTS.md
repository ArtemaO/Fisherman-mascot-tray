# Project Memory

This file keeps the high-signal decisions for the project so future work does not lose context.

## Product Goal

Build the simplest reliable Windows notifier that alerts the user when Codex needs attention.

The notifier must not interpret the meaning of the chat. It only reacts to a narrow set of attention states:

- waiting for user reply
- waiting for confirmation
- task finished and requesting attention

## User-Approved Product Shape

- Windows-only direct notifier for v1
- No long-lived background process in idle state
- No terminal watcher for v1
- Standard Windows toast notification
- Short text message per attention state
- App icon if available
- Optional short system sound
- Friendly phrase allowed in toast text:
  - `Klyuet, podsekay!`
  - `Клюет, подсекай!`

## Confirmed Platform

- OS: Windows
- v1 implementation target: PowerShell-based direct notifier
- Direct invocation from the active local Codex workflow

## Mascot Direction

- 2D desktop-pet style
- Based on the user's fishing look:
  - baseball cap
  - dark fishing suit
  - red-tinted polarized sunglasses
  - friendly smile
- Fish species: burbot (`Lota lota`, nalim)

The fisherman mascot remains a future enhancement rather than the first implementation target.

## Current Visual Asset

- Generated mascot reference image:
  - `C:\project\ChatGPT Image 11 апр. 2026 г., 22_42_58.png`
- App mascot asset to preserve for future versions:
  - `C:\project\assets\mascot\fisherman-base.png`

This image remains the style reference for a future mascot-based version and should be preserved.

## Technical Decisions Locked for v1

- Use a direct Windows toast notification for the first minimal implementation
- Implement the notifier as a local PowerShell script
- Do not keep a resident tray app or watcher process running in idle state
- Keep the notifier usable even if sound fails
- Keep the notifier usable even if icon loading fails
- Support only these direct attention kinds:
  - `needs-reply`
  - `needs-confirmation`
  - `finished`

## Notification Strategy for v1

Direct generic inspection of Windows Terminal content is not the implementation target for v1.

For v1, use a direct invocation path:

- trigger notifications intentionally from the active Codex workflow
- call a local script such as `scripts/notify-codex.ps1`
- show a standard Windows toast with short text
- optionally play a short system sound
- exit immediately after notification

This satisfies the product goal with minimal complexity and minimal idle resource usage.

## Out of Scope for v1

- Electron tray runtime
- mascot popup window
- terminal watcher
- OCR
- UI Automation
- deep Codex API integration
- semantic parsing of the conversation
- support for every Windows terminal app
- auto-update

## Source of Truth

- Current design spec:
  - `C:\project\docs\superpowers\specs\2026-04-13-codex-direct-windows-notifier-design.md`
- Historical specs superseded by the new v1 direction:
  - `C:\project\docs\superpowers\specs\2026-04-11-codex-fishing-mascot-design.md`
  - `C:\project\docs\superpowers\specs\2026-04-11-universal-terminal-watcher-design.md`

## Current Direction

- the direct notifier is the recommended v1 path
- earlier Electron and watcher work is now legacy prototype material
- old files may be removed during implementation if they do not support the new direct notifier path
- the fisherman mascot remains a future enhancement, not part of the minimal first implementation

## Workflow Rule

When a major product or technical decision changes, update this file in the same work session.
