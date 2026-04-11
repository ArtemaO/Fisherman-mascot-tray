# Universal Terminal Watcher for Codex Mascot - Design

Date: 2026-04-11
Status: Draft approved in chat, written for review

## Goal

Extend the Windows mascot app so it can attach to an already open terminal window, detect whether Codex is actively working, and show connection status without requiring the helper-launch flow.

The first version of this watcher does not try to understand the full terminal transcript. It only determines whether the selected terminal appears to be actively running Codex work by looking for a line shaped like:

`Working (10s • esc to interrupt)`

The exact timer value can vary. The important signal is the presence of a `Working (... esc to interrupt)` line.

## Version Scope

This version adds a universal terminal watcher subsystem for Windows.

Included:

- discover candidate terminal windows
- select a window from a list
- manual window pick mode
- attach to one chosen window at a time
- text reading through Windows UI Automation first
- fallback to Windows OCR when UI Automation is insufficient
- detect `Working` versus `Idle`
- show connection mode and state inside the app

Not included:

- full reply/confirmation/finished detection
- support guarantees for every terminal program
- long transcript history
- cloud or API integration
- heavy OCR pipelines such as Tesseract

## Supported Platform

- OS: Windows
- primary usage target: terminal windows that may host Codex
- implementation is Windows-only by design

## Product Behavior

### Window discovery

The app scans for visible windows that look like terminal sessions and presents them in a selection UI.

For each discovered window, the app should collect enough metadata to help the user pick the right one:

- window title
- process name
- class name when available
- stable identifier such as HWND

### Window selection

The user can choose the target in two ways:

- select one from the discovered list
- use a manual pick mode to point at a window directly

Only one window is watched at a time.

### Reader strategy

The watcher uses a two-layer reader:

1. UI Automation reader
2. Windows OCR fallback

Default behavior:

- try UI Automation first
- if the returned text is empty, unusable, or repeatedly fails to expose the needed terminal content, switch to OCR fallback

The app must surface which reader is currently active:

- `UIA`
- `OCR fallback`
- `Window unavailable`

### Working-state detection

The watcher only needs to answer one question in this version:

- is Codex currently working?

The detector scans the observed text for a line matching the working pattern. It should tolerate variable elapsed time values and minor formatting differences as long as the semantic form remains equivalent to:

- `Working (10s • esc to interrupt)`

State rules:

- `Working`: the working pattern is seen in two consecutive polls
- `Idle`: the working pattern is absent in two consecutive polls

This debounce prevents noisy state flapping.

### Polling and resource usage

The watcher must stay lightweight.

Rules:

- poll only the selected window
- do not continuously scan every terminal window after selection
- default poll interval: around once per second when the window is available
- reduce polling if the window becomes unavailable, minimized, or unreadable
- OCR should inspect only the relevant captured window region, not the entire desktop
- keep only short-lived state needed for current detection, not large image or text history

## UI Changes

The app should gain a simple operator surface in addition to the mascot:

- list of discovered windows
- action to refresh the list
- action to manually pick a window
- current connection target
- current reader mode (`UIA`, `OCR fallback`, `Window unavailable`)
- current activity state (`Working`, `Idle`)

This status surface is primarily for validation and debugging, not final product polish.

## Architecture

### 1. Window Discovery

Responsibilities:

- enumerate candidate desktop windows
- filter out irrelevant windows where possible
- return metadata suitable for user selection

### 2. Window Picker

Responsibilities:

- present discovered candidates
- support manual pick mode
- persist the currently selected target for the running session

### 3. UIA Reader

Responsibilities:

- attach to the selected window via Windows UI Automation
- read available terminal text content
- report whether the result is usable

### 4. OCR Reader

Responsibilities:

- capture the selected window area
- run Windows OCR over the capture
- return extracted text in the same shape expected by the detector

### 5. Activity Detector

Responsibilities:

- evaluate current text snapshot
- determine `Working` or `Idle`
- debounce state transitions

### 6. Status Surface

Responsibilities:

- display selected window metadata
- display active reader mode
- display current activity state

### 7. Mascot Integration

Responsibilities:

- remain compatible with the existing mascot app shell
- optionally reflect activity state without yet adding full attention semantics

## Error Handling

The watcher should fail softly.

- if the selected window closes, mark it unavailable and pause aggressive polling
- if UI Automation fails, fall back to OCR when possible
- if OCR fails too, report `Window unavailable` rather than crashing
- if text extraction is partial or noisy, keep the previous state until debounce rules are satisfied

## Acceptance Criteria

This version is successful when all of the following are true:

- the app discovers candidate terminal windows
- the user can select a terminal window from a list
- the user can manually pick a window
- the app shows which window is currently selected
- the app shows which reader mode is active
- when the chosen window contains a `Working (... esc to interrupt)` line, the app reports `Working`
- when the line disappears, the app reports `Idle`
- the app does not constantly scan every window after target selection
- the app does not crash when the selected window disappears or becomes unreadable

## Testing Strategy

Testing should focus on practical verification:

- manual discovery test with multiple terminal windows open
- manual selection test from list
- manual pick test
- UI Automation text-read test on a supported terminal
- OCR fallback test on a terminal where UI Automation is insufficient
- working-line detection test using a controlled text source or known Codex session
- stability test to ensure state does not flicker under transient read failures

## Design Summary

Build a Windows-only universal terminal watcher for the mascot app that can attach to an already open terminal window, read its visible text using UI Automation first and Windows OCR second, detect whether Codex is actively working from the presence of a `Working (... esc to interrupt)` line, and surface the selected window, reader mode, and current state in the app.
