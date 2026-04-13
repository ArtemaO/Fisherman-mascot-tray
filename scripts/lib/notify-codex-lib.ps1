Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:CodexToastAppId = 'ArtemaO.FishermanMascotTray.CodexNotifier'
$script:CodexShellLinkTypeName = 'Codex.ToastInterop.ShellLinkManager'

function Initialize-CodexShellLinkInterop {
  $shellLinkType = ([System.Management.Automation.PSTypeName] $script:CodexShellLinkTypeName).Type
  if ($null -ne $shellLinkType) {
    return
  }

  Add-Type -Language CSharp @'
using System;
using System.Runtime.InteropServices;
using System.Text;

namespace Codex.ToastInterop
{
    [ComImport]
    [Guid("00021401-0000-0000-C000-000000000046")]
    internal class CShellLink
    {
    }

    [ComImport]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    [Guid("000214F9-0000-0000-C000-000000000046")]
    internal interface IShellLinkW
    {
        void GetPath([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszFile, int cch, out WIN32_FIND_DATAW pfd, uint fFlags);
        void GetIDList(out IntPtr ppidl);
        void SetIDList(IntPtr pidl);
        void GetDescription([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszName, int cch);
        void SetDescription([MarshalAs(UnmanagedType.LPWStr)] string pszName);
        void GetWorkingDirectory([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszDir, int cch);
        void SetWorkingDirectory([MarshalAs(UnmanagedType.LPWStr)] string pszDir);
        void GetArguments([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszArgs, int cch);
        void SetArguments([MarshalAs(UnmanagedType.LPWStr)] string pszArgs);
        void GetHotkey(out short pwHotkey);
        void SetHotkey(short wHotkey);
        void GetShowCmd(out int piShowCmd);
        void SetShowCmd(int iShowCmd);
        void GetIconLocation([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszIconPath, int cch, out int piIcon);
        void SetIconLocation([MarshalAs(UnmanagedType.LPWStr)] string pszIconPath, int iIcon);
        void SetRelativePath([MarshalAs(UnmanagedType.LPWStr)] string pszPathRel, uint dwReserved);
        void Resolve(IntPtr hwnd, uint fFlags);
        void SetPath([MarshalAs(UnmanagedType.LPWStr)] string pszFile);
    }

    [ComImport]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    [Guid("0000010b-0000-0000-C000-000000000046")]
    internal interface IPersistFile
    {
        void GetClassID(out Guid pClassID);
        void IsDirty();
        void Load([MarshalAs(UnmanagedType.LPWStr)] string pszFileName, uint dwMode);
        void Save([MarshalAs(UnmanagedType.LPWStr)] string pszFileName, bool fRemember);
        void SaveCompleted([MarshalAs(UnmanagedType.LPWStr)] string pszFileName);
        void GetCurFile([MarshalAs(UnmanagedType.LPWStr)] out string ppszFileName);
    }

    [ComImport]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    [Guid("886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99")]
    internal interface IPropertyStore
    {
        void GetCount(out uint cProps);
        void GetAt(uint iProp, out PROPERTYKEY pkey);
        void GetValue(ref PROPERTYKEY key, out PROPVARIANT pv);
        void SetValue(ref PROPERTYKEY key, ref PROPVARIANT pv);
        void Commit();
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    internal struct WIN32_FIND_DATAW
    {
        public uint dwFileAttributes;
        public System.Runtime.InteropServices.ComTypes.FILETIME ftCreationTime;
        public System.Runtime.InteropServices.ComTypes.FILETIME ftLastAccessTime;
        public System.Runtime.InteropServices.ComTypes.FILETIME ftLastWriteTime;
        public uint nFileSizeHigh;
        public uint nFileSizeLow;
        public uint dwReserved0;
        public uint dwReserved1;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)]
        public string cFileName;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 14)]
        public string cAlternateFileName;
    }

    [StructLayout(LayoutKind.Sequential, Pack = 4)]
    internal struct PROPERTYKEY
    {
        public Guid fmtid;
        public uint pid;

        public PROPERTYKEY(Guid formatId, uint propertyId)
        {
            fmtid = formatId;
            pid = propertyId;
        }
    }

    [StructLayout(LayoutKind.Sequential)]
    internal struct PROPVARIANT
    {
        public ushort vt;
        public ushort wReserved1;
        public ushort wReserved2;
        public ushort wReserved3;
        public IntPtr pointerValue;
        public int intValue;

        public static PROPVARIANT FromString(string value)
        {
            return new PROPVARIANT
            {
                vt = 31,
                pointerValue = Marshal.StringToCoTaskMemUni(value)
            };
        }

        public string GetString()
        {
            if ((vt == 31 || vt == 30) && pointerValue != IntPtr.Zero)
            {
                return Marshal.PtrToStringUni(pointerValue);
            }

            return null;
        }
    }

    public static class ShellLinkManager
    {
        private static readonly PROPERTYKEY AppIdKey = new PROPERTYKEY(new Guid("9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3"), 5);

        [DllImport("Ole32.dll")]
        private static extern int PropVariantClear(ref PROPVARIANT pvar);

        public static void CreateShortcut(string shortcutPath, string targetPath, string arguments, string workingDirectory, string description, string appId)
        {
            var shellLink = (IShellLinkW)new CShellLink();
            shellLink.SetPath(targetPath);

            if (!string.IsNullOrWhiteSpace(arguments))
            {
                shellLink.SetArguments(arguments);
            }

            if (!string.IsNullOrWhiteSpace(workingDirectory))
            {
                shellLink.SetWorkingDirectory(workingDirectory);
            }

            if (!string.IsNullOrWhiteSpace(description))
            {
                shellLink.SetDescription(description);
            }

            shellLink.SetIconLocation(targetPath, 0);

            var propertyStore = (IPropertyStore)shellLink;
            var appIdVariant = PROPVARIANT.FromString(appId);
            var appIdKey = AppIdKey;

            try
            {
                propertyStore.SetValue(ref appIdKey, ref appIdVariant);
                propertyStore.Commit();
            }
            finally
            {
                PropVariantClear(ref appIdVariant);
            }

            ((IPersistFile)shellLink).Save(shortcutPath, true);
        }

        public static string GetAppUserModelId(string shortcutPath)
        {
            var shellLink = (IShellLinkW)new CShellLink();
            ((IPersistFile)shellLink).Load(shortcutPath, 0);
            var propertyStore = (IPropertyStore)shellLink;
            var appIdKey = AppIdKey;
            PROPVARIANT value;
            propertyStore.GetValue(ref appIdKey, out value);

            try
            {
                return value.GetString();
            }
            finally
            {
                PropVariantClear(ref value);
            }
        }
    }
}
'@
}

function Decode-CodexUtf8Base64 {
  param(
    [Parameter(Mandatory)]
    [string] $Value
  )

  [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Value))
}

function Get-CodexToastRegistration {
  $shortcutDirectory = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
  $shortcutPath = Join-Path $shortcutDirectory 'Codex Notifier.lnk'
  $targetPath = Join-Path $PSHOME 'powershell.exe'
  $workingDirectory = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

  [pscustomobject]@{
    AppId            = $script:CodexToastAppId
    ShortcutPath     = $shortcutPath
    TargetPath       = $targetPath
    Arguments        = '-NoProfile'
    WorkingDirectory = $workingDirectory
    Description      = 'Codex direct Windows notifier'
  }
}

function Get-CodexShortcutAppId {
  param(
    [Parameter(Mandatory)]
    [string] $ShortcutPath
  )

  Initialize-CodexShellLinkInterop
  [Codex.ToastInterop.ShellLinkManager]::GetAppUserModelId($ShortcutPath)
}

function Ensure-CodexToastShortcut {
  param(
    [Parameter(Mandatory)]
    [string] $ShortcutPath,

    [Parameter(Mandatory)]
    [string] $AppId,

    [Parameter(Mandatory)]
    [string] $TargetPath,

    [string] $Arguments = '',
    [string] $WorkingDirectory = '',
    [string] $Description = ''
  )

  Initialize-CodexShellLinkInterop

  $shortcutDirectory = Split-Path -Parent $ShortcutPath
  if (-not (Test-Path $shortcutDirectory)) {
    New-Item -ItemType Directory -Path $shortcutDirectory -Force | Out-Null
  }

  $currentAppId = if (Test-Path $ShortcutPath) {
    Get-CodexShortcutAppId -ShortcutPath $ShortcutPath
  } else {
    $null
  }

  if ($currentAppId -eq $AppId) {
    return $ShortcutPath
  }

  [Codex.ToastInterop.ShellLinkManager]::CreateShortcut(
    $ShortcutPath,
    $TargetPath,
    $Arguments,
    $WorkingDirectory,
    $Description,
    $AppId
  )

  return $ShortcutPath
}

function Get-CodexNotificationContent {
  param(
    [Parameter(Mandatory)]
    [ValidateSet('needs-reply', 'needs-confirmation', 'finished')]
    [string] $Kind
  )

  $message = switch ($Kind) {
    'needs-reply' { Decode-CodexUtf8Base64 '0J3Rg9C20LXQvSDQvtGC0LLQtdGCLiDQmtC70Y7QtdGCLCDQv9C+0LTRgdC10LrQsNC5IQ==' }
    'needs-confirmation' { Decode-CodexUtf8Base64 '0J3Rg9C20L3QviDQv9C+0LTRgtCy0LXRgNC20LTQtdC90LjQtS4g0JrQu9GO0LXRgiwg0L/QvtC00YHQtdC60LDQuSE=' }
    'finished' { Decode-CodexUtf8Base64 '0JfQsNC00LDRh9CwINC30LDQstC10YDRiNC10L3QsC4g0JrQu9GO0LXRgiwg0L/QvtC00YHQtdC60LDQuSE=' }
  }

  [pscustomobject]@{
    Kind    = $Kind
    Title   = 'Codex'
    Message = $message
    AppId   = $script:CodexToastAppId
  }
}

function New-CodexToastXml {
  param(
    [Parameter(Mandatory)]
    [psobject] $Content,

    [switch] $IncludeSound
  )

  [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

  $title = [System.Security.SecurityElement]::Escape([string] $Content.Title)
  $message = [System.Security.SecurityElement]::Escape([string] $Content.Message)
  $audioXml = if ($IncludeSound) {
    '<audio src="ms-winsoundevent:Notification.Default" />'
  } else {
    '<audio silent="true" />'
  }

  $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
  $xml.LoadXml("<toast><visual><binding template=`"ToastGeneric`"><text>$title</text><text>$message</text></binding></visual>$audioXml</toast>")
  return $xml
}

function Show-CodexToast {
  param(
    [Parameter(Mandatory)]
    [ValidateSet('needs-reply', 'needs-confirmation', 'finished')]
    [string] $Kind,

    [switch] $NoSound
  )

  [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
  [Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null

  $registration = Get-CodexToastRegistration
  Ensure-CodexToastShortcut `
    -ShortcutPath $registration.ShortcutPath `
    -AppId $registration.AppId `
    -TargetPath $registration.TargetPath `
    -Arguments $registration.Arguments `
    -WorkingDirectory $registration.WorkingDirectory `
    -Description $registration.Description | Out-Null

  $content = Get-CodexNotificationContent -Kind $Kind
  $xml = New-CodexToastXml -Content $content -IncludeSound:(-not $NoSound)
  $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
  $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($registration.AppId)
  $notifier.Show($toast)
  return $content
}
