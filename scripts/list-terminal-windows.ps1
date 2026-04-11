Add-Type @"
using System;
using System.Text;
using System.Diagnostics;
using System.Runtime.InteropServices;
public static class Win32Enum {
  public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);
  [DllImport("user32.dll")] public static extern int GetClassName(IntPtr hWnd, StringBuilder text, int count);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);
}
"@

$windows = New-Object System.Collections.Generic.List[Object]
[Win32Enum]::EnumWindows({
  param($hWnd, $lParam)
  if (-not [Win32Enum]::IsWindowVisible($hWnd)) { return $true }

  $title = New-Object System.Text.StringBuilder 512
  [void][Win32Enum]::GetWindowText($hWnd, $title, $title.Capacity)
  $class = New-Object System.Text.StringBuilder 256
  [void][Win32Enum]::GetClassName($hWnd, $class, $class.Capacity)
  [uint32]$pid = 0
  [void][Win32Enum]::GetWindowThreadProcessId($hWnd, [ref]$pid)
  $process = Get-Process -Id $pid -ErrorAction SilentlyContinue

  $windows.Add([pscustomobject]@{
    hwnd = [int64]$hWnd
    title = $title.ToString()
    processName = $process.ProcessName
    className = $class.ToString()
  }) | Out-Null
  return $true
}, [IntPtr]::Zero) | Out-Null

$windows | ConvertTo-Json
