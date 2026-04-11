Add-Type @"
using System;
using System.Text;
using System.Diagnostics;
using System.Runtime.InteropServices;
public static class Win32Foreground {
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);
  [DllImport("user32.dll")] public static extern int GetClassName(IntPtr hWnd, StringBuilder text, int count);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);
}
"@

$hWnd = [Win32Foreground]::GetForegroundWindow()
$title = New-Object System.Text.StringBuilder 512
[void][Win32Foreground]::GetWindowText($hWnd, $title, $title.Capacity)
$class = New-Object System.Text.StringBuilder 256
[void][Win32Foreground]::GetClassName($hWnd, $class, $class.Capacity)
[uint32]$pid = 0
[void][Win32Foreground]::GetWindowThreadProcessId($hWnd, [ref]$pid)
$process = Get-Process -Id $pid -ErrorAction SilentlyContinue

[pscustomobject]@{
  hwnd = [int64]$hWnd
  title = $title.ToString()
  processName = $process.ProcessName
  className = $class.ToString()
} | ConvertTo-Json
