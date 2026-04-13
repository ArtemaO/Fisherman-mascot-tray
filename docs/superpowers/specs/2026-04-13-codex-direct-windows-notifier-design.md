# Codex Direct Windows Notifier - Design

Date: 2026-04-13
Status: Approved in chat, written for review

## Goal

Build the simplest reliable Windows notifier for Codex attention states without watching terminal output and without keeping a desktop app running in the background.

The system must alert the user only for three narrow states:

- waiting for user reply
- waiting for confirmation
- task finished and requesting attention

The notifier should be lightweight enough that it does not meaningfully load the PC or interfere with AI work when idle.

## Version Scope

This version replaces the earlier watcher-first prototype direction for v1.

Included:

- Windows-only notification path
- direct invocation from the active Codex session
- standard Windows toast notification
- short text message for each attention state
- app icon if available
- optional short system sound when supported
- no long-lived watcher process
- no polling of windows or terminal content

Not included:

- Electron tray app
- transparent mascot window
- terminal watcher
- OCR
- UI Automation
- universal terminal support
- semantic chat parsing
- repeat scheduling outside the calling workflow

## Product Shape

The first minimal product is a single local PowerShell entrypoint:

- `scripts/notify-codex.ps1`

The script is called directly when attention is needed. It shows a standard Windows notification and exits immediately.

There is no resident process in idle state.

## User Experience

When Codex needs attention, Windows shows a normal toast notification with:

- title: `Codex`
- short body text matching the attention state
- optional second line with `Klyuet, podsekay!`
- application icon when available

Example messages:

- reply: `Nuzhen otvet. Klyuet, podsekay!`
- confirmation: `Nuzhno podtverzhdenie. Klyuet, podsekay!`
- finished: `Zadacha zavershena. Klyuet, podsekay!`

The notification should be readable, brief, and immediately recognizable as coming from the local Codex workflow.

## Architecture

### 1. Notification Script

Responsibilities:

- accept a narrow `Kind` parameter
- map `Kind` to user-facing notification text
- invoke Windows toast APIs
- optionally trigger a short system sound
- exit cleanly

Supported kinds:

- `needs-reply`
- `needs-confirmation`
- `finished`

### 2. Calling Path

Responsibilities:

- invoke the notification script only when attention is genuinely required
- keep invocation explicit rather than inferred from terminal scraping

The calling side may be:

- a Codex-side tool invocation
- a helper command the operator runs manually
- a wrapper used by the local workflow

The important design rule is that notification is direct and intentional, not discovered by watching terminal output.

## Performance and Resource Use

This design is optimized for minimal overhead.

Rules:

- no background watcher
- no polling loop
- no resident Electron process
- no terminal scanning
- the notification process lives only for the duration of the toast call

Idle cost should be effectively zero outside normal Windows notification infrastructure.

## Error Handling

Failure should be soft:

- if toast display fails, the script should return a nonzero exit code and print a concise error
- if sound fails, the notification should still succeed
- if icon loading fails, the notification should still succeed with text only
- unsupported `Kind` values should fail clearly

## Acceptance Criteria

This version is successful when all of the following are true:

- a local command can trigger a Windows toast
- the toast text differs correctly for reply, confirmation, and finished
- the script exits after showing the notification
- no tray app or watcher needs to stay running in the background
- idle resource use remains negligible
- the implementation does not inspect terminal output to decide attention state

## Migration Impact

This design supersedes the earlier v1 direction that centered the product around:

- Electron tray runtime
- mascot popup window
- local HTTP watcher bridge
- helper-based stdout pattern matching

Those files may be removed during implementation if they are not needed for the direct notifier path.

The fisherman mascot remains a valid future enhancement, but it is no longer part of the minimal first implementation.

## Testing Strategy

Testing should stay narrow:

- unit test for `Kind` to message mapping
- manual invocation test for each supported kind
- manual failure test for an invalid kind

No browser automation or terminal watcher testing is required for this version.

## Design Summary

Build a Windows-only direct notifier for Codex that is invoked explicitly when attention is needed, shows a standard Windows toast with short text and optional icon and sound, and exits immediately without any watcher, polling, or long-lived desktop process.
