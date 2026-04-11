# Codex Fishing Mascot

Windows tray prototype that shows a fisherman mascot near the system tray when Codex needs attention.

## Run locally

1. `npm install`
2. `npm run start`
3. In another Windows Terminal tab, run:
   `powershell -ExecutionPolicy Bypass -File .\scripts\start-codex-watcher.ps1`

## Send a test alert

`powershell -ExecutionPolicy Bypass -File .\scripts\send-test-event.ps1 -Kind needs-reply`

## Build a Windows portable app

`npm run package:win`
