const PROCESS_ALLOWLIST = new Set([
  'windowsterminal',
  'powershell',
  'pwsh',
  'cmd',
  'wezterm',
  'alacritty'
]);

const CLASS_ALLOWLIST = new Set([
  'CASCADIA_HOSTING_WINDOW_CLASS',
  'ConsoleWindowClass'
]);

export function normalizeWindowList(rows) {
  const items = Array.isArray(rows) ? rows : rows ? [rows] : [];

  return items.filter((row) => {
    if (!row?.title) {
      return false;
    }

    const processName = String(row.processName ?? '').trim().toLowerCase();
    const className = String(row.className ?? '').trim();

    return PROCESS_ALLOWLIST.has(processName) || CLASS_ALLOWLIST.has(className);
  });
}
