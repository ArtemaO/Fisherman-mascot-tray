import { beforeEach, describe, expect, it, vi } from 'vitest';
import { promisify } from 'node:util';

const execFileMock = vi.fn();
const execFilePromisifiedMock = vi.fn();

execFileMock[promisify.custom] = execFilePromisifiedMock;

vi.mock('node:child_process', () => ({
  execFile: execFileMock
}));

describe('windows bridge', () => {
  beforeEach(() => {
    execFileMock.mockReset();
    execFilePromisifiedMock.mockReset();
  });

  it('runs the requested PowerShell script from the app scripts directory', async () => {
    execFilePromisifiedMock.mockResolvedValue({
      stdout: JSON.stringify({ hwnd: 42 }),
      stderr: ''
    });

    const { runPowerShellScript } = await import('../../src/main/windowsBridge.js');
    await expect(runPowerShellScript('C:/project/app', 'list-terminal-windows.ps1')).resolves.toEqual({ hwnd: 42 });
    expect(execFilePromisifiedMock).toHaveBeenCalledWith(
      'powershell',
      [
        '-NoProfile',
        '-NonInteractive',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        'C:\\project\\app\\scripts\\list-terminal-windows.ps1'
      ],
      {
        windowsHide: true,
        maxBuffer: 1024 * 1024 * 4
      }
    );
  });
});
