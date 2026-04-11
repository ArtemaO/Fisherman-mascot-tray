import { execFile } from 'node:child_process';
import path from 'node:path';
import { promisify } from 'node:util';

const execFileAsync = promisify(execFile);

export async function runPowerShellScript(appRoot, scriptName) {
  const scriptPath = path.join(appRoot, 'scripts', scriptName);
  const { stdout } = await execFileAsync(
    'powershell',
    ['-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', scriptPath],
    {
      windowsHide: true,
      maxBuffer: 1024 * 1024 * 4
    }
  );

  return JSON.parse(stdout || 'null');
}
