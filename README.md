# Fisherman Mascot Tray

Этот репозиторий теперь хранит минимальный Windows-нотификатор для Codex.

## Быстрый запуск

Показать уведомление о необходимости ответа:

`powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\notify-codex.ps1 -Kind needs-reply`

Показать уведомление о необходимости подтверждения:

`powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\notify-codex.ps1 -Kind needs-confirmation`

Показать уведомление о завершении задачи:

`powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\notify-codex.ps1 -Kind finished`

Отключить звук:

`powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\notify-codex.ps1 -Kind finished -NoSound`

## Проверка без показа toast

`powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\notify-codex.ps1 -Kind needs-reply -Preview`

## Тесты

`powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\notify-codex.test.ps1`

`powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\notify-codex-cli.test.ps1`
