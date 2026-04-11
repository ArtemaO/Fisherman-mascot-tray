import { describe, expect, it } from 'vitest';
import { normalizeWindowList } from '../../src/main/windowDiscovery.js';

describe('window discovery normalization', () => {
  it('filters to visible terminal-like windows', () => {
    const rows = normalizeWindowList([
      { hwnd: 100, title: 'Codex', processName: 'WindowsTerminal', className: 'CASCADIA_HOSTING_WINDOW_CLASS' },
      { hwnd: 101, title: '', processName: 'explorer', className: 'CabinetWClass' }
    ]);

    expect(rows).toEqual([
      { hwnd: 100, title: 'Codex', processName: 'WindowsTerminal', className: 'CASCADIA_HOSTING_WINDOW_CLASS' }
    ]);
  });

  it('accepts a single discovered window object and normalizes it into a list', () => {
    expect(
      normalizeWindowList({
        hwnd: 100,
        title: 'Codex',
        processName: 'WindowsTerminal',
        className: 'CASCADIA_HOSTING_WINDOW_CLASS'
      })
    ).toEqual([
      { hwnd: 100, title: 'Codex', processName: 'WindowsTerminal', className: 'CASCADIA_HOSTING_WINDOW_CLASS' }
    ]);
  });

  it('keeps windows with an allowed class name when processName is missing', () => {
    expect(
      normalizeWindowList({
        hwnd: 100,
        title: 'Codex',
        className: 'CASCADIA_HOSTING_WINDOW_CLASS'
      })
    ).toEqual([
      { hwnd: 100, title: 'Codex', className: 'CASCADIA_HOSTING_WINDOW_CLASS' }
    ]);
  });
});
