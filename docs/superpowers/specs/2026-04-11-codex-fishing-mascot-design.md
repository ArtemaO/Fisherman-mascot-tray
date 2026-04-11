# Codex Fishing Mascot for Windows - Design

Date: 2026-04-11
Status: Draft approved in chat, written for review

## Goal

Create a Windows desktop prototype that watches a terminal session running Codex and alerts the user only when Codex requires attention. The app should not interpret the meaning of the conversation. It should only react to a limited set of service states such as:

- Codex is waiting for a user reply
- Codex is waiting for confirmation for the next action
- Codex finished a task and requests attention

The alert should appear as a small fisherman mascot near the Windows system tray. The mascot rings bells attached to a fishing rod, waves at the user, and shows a speech bubble with the text `Клюет, подсекай!`

## Scope for Version 1

This is a working prototype that can be installed and manually tested on Windows. It should be usable enough to validate the product idea, but it does not need production-grade packaging or deep integration.

Version 1 includes:

- Windows desktop app
- System tray icon
- Transparent mascot window near the clock area
- Detection of Codex attention states from terminal output
- Bell sound alert
- Simple 2D mascot animation
- Manual test alert from tray menu
- Manual and automatic alert dismissal

Version 1 does not include:

- Full production installer pipeline
- Auto-update
- Deep Codex API integration
- Reading or understanding the actual meaning of Codex chat content
- Support for every terminal application on Windows
- Complex frame-by-frame animation pipeline

## Platform and Environment

- OS: Windows
- Primary terminal target: Windows Terminal version 1.23.20211.0
- Codex is expected to run in a terminal session observed by the app
- The first version should be optimized for this environment instead of trying to support every possible terminal setup

## Product Behavior

### Idle behavior

- The app runs quietly in the system tray
- The mascot is not always visible on screen
- The tray icon remains available for controls and status

### Alert behavior

When Codex enters a state that requires user attention:

1. The mascot window appears near the bottom-right corner by the system tray
2. The mascot plays a short bell sound
3. The fisherman waves
4. The rod and line react as if a fish is biting
5. A speech bubble appears with `Клюет, подсекай!`

If the user does not react, the app should repeat a softer alert after a configurable interval in the implementation, with a reasonable default.

### Alert dismissal

An active alert can be cleared in two ways:

- Manually: the user clicks the mascot or the tray icon/menu action
- Automatically: the app confidently detects that Codex has resumed work and is no longer waiting for user attention

Manual dismissal is the primary reset path for version 1. Automatic dismissal is best-effort and must not be more aggressive than manual control.

## Mascot Design

### Character

The mascot is a stylized 2D fisherman based on the user's appearance:

- baseball cap
- dark fishing suit
- red-tinted polarized fishing glasses
- friendly smile

The design direction is closer to a desktop pet or small indie game mascot than to a realistic illustration.

### Fish

The fish should be a burbot (`Lota lota`, nalim), with species cues preserved:

- elongated body
- mottled brown pattern
- broad flat head
- small whisker under the chin

### Animation direction

Animation should be simple and suitable for a prototype:

- idle pose
- alert pose
- waving hand
- rod bend and line movement
- bell jingle motion

The visual asset style should favor clean separable shapes over heavy detail so the mascot can be animated simply.

## Technical Approach

### Recommended stack

Use Electron for version 1.

Rationale:

- fastest route to a testable Windows prototype
- straightforward tray support
- straightforward transparent always-on-top window behavior
- easy integration of HTML/CSS/JS-based animation
- lower implementation risk than Tauri for this prototype

### Core modules

#### 1. Tray App

Responsibilities:

- launch and lifetime management
- tray icon and tray menu
- access to test functions
- mute/pause/exit controls

Suggested tray actions for version 1:

- `Test alert`
- `Mute sound`
- `Pause watching`
- `Exit`

#### 2. Watcher

Responsibilities:

- observe Codex-related terminal output
- match only a limited set of attention-requesting patterns
- avoid semantic parsing of the conversation

Version 1 rule:

The watcher should detect service-style terminal output patterns that indicate attention is required, but it should not attempt to understand the task content or user conversation.

#### 3. Alert State Manager

Responsibilities:

- deduplicate repeated alerts
- track whether an alert is active
- schedule repeat alerts
- dismiss alerts manually or automatically

#### 4. Mascot Window

Responsibilities:

- render the fisherman mascot near the system tray area
- remain transparent and always on top while active
- show or hide based on alert state
- display speech bubble and visual reaction

#### 5. Asset and Animation Layer

Responsibilities:

- store mascot image assets
- run simple 2D animation states
- coordinate bell sound and motion timing

## Event Flow

1. Codex writes output in the watched terminal session
2. The watcher detects a known attention pattern
3. The alert state manager determines whether this is a new alert or a duplicate
4. If it is a new alert, the mascot window is shown
5. Bell sound, waving motion, rod reaction, and speech bubble are triggered
6. If the alert remains unresolved, a softer repeat alert occurs after an interval
7. The alert is cleared either by user action or by confident detection that Codex resumed normal work

## Sound Design

Sound is part of the primary interaction, not an optional extra.

Requirements:

- short bell-jingle sound as the main alert
- pleasant and brief, roughly around half a second to one and a half seconds
- suitable for repeated playback without becoming too harsh
- mute toggle available from tray
- if audio cannot load, the app must still function with visual alert only

## Error Handling

Version 1 should degrade gracefully.

- If terminal watching fails, the app should stay running and allow test alerts from tray
- If the sound file is missing or fails to play, the visual alert still works
- If automatic clear cannot be determined confidently, the alert stays active until manual dismissal
- If the mascot asset fails to load, the app should still expose tray controls and a diagnostic path

## Acceptance Criteria

The version 1 prototype is considered successful when all of the following are true:

- The app launches on Windows
- A tray icon appears
- The tray menu provides a working manual test alert
- When a Codex attention event is detected, the mascot appears near the clock area
- The bells ring
- The mascot waves and visually reacts
- The speech bubble `Клюет, подсекай!` appears
- Repeat alerts occur if the user does not respond
- The alert can be cleared manually
- The alert can also clear automatically when the app confidently sees Codex resume work
- The app does not analyze the meaning of the conversation
- Failures in sound or watching do not crash the app

## Testing Strategy

Testing for version 1 should be focused and practical:

- manual tray test for alert rendering
- manual watcher test using controlled sample terminal output
- manual sound verification
- manual repeat-alert verification
- manual clear and auto-clear verification

At minimum, the implementation should make it easy to simulate watcher events without requiring a live Codex session for every test.

## Open Implementation Decisions for Planning

These do not block the design, but they must be resolved during planning:

- exact watcher strategy for Windows Terminal integration
- exact event patterns to treat as `needs reply`, `needs confirmation`, and `finished`
- repeat-alert interval defaults
- packaging format for the first installable build
- whether animation uses CSS transforms, canvas, or a lightweight animation library

## Design Summary

Build an Electron-based Windows tray app that listens only for a narrow set of Codex attention signals in Windows Terminal. When such a signal appears, show a small fisherman desktop mascot near the system tray, ring rod bells, animate the fisherman, show the text `Клюет, подсекай!`, and keep the alert active with gentle repeats until the user or the terminal state clears it.
