# Fisherman Mascot Tray

Минимальный Windows-нотификатор для Codex.

## Что делает проект

Скрипт показывает стандартное Windows-уведомление только в трех состояниях:

- нужен ответ пользователя
- нужно подтверждение
- задача завершена

Проект намеренно не читает терминал и не держит резидентные процессы в фоне.

## Быстрый запуск

`powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\notify-codex.ps1 -Kind needs-reply`

`powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\notify-codex.ps1 -Kind needs-confirmation`

`powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\notify-codex.ps1 -Kind finished`

## Проверка

`powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\notify-codex.test.ps1`

`powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\notify-codex-cli.test.ps1`

`powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\notify-codex-shortcut.test.ps1`

`powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\repo-layout.test.ps1`
