<#
Click timing recorder (diagnostic, throwaway).

Records every mouse BUTTON edge (no movement, no wheel) plus a small set of
keyboard keys that mouse software commonly emits for remapped buttons
(volume/media, browser back/forward, F13-F24). Nothing is blocked or changed.

  powershell -ExecutionPolicy Bypass -File tools\clicklog.ps1 -Seconds 60

-AllKeys   also log every keyboard key (virtual-key codes only). Use it when a
           mouse button is mapped to an ordinary key or macro. Do not type
           passwords while it runs.
-SuspectMs presses that start sooner than this after the previous release of
           the same button are flagged as probable chatter (default 150).
#>
param(
    [int]$Seconds = 60,
    [string]$Out = (Join-Path $PSScriptRoot ("clicklog-{0:yyyyMMdd-HHmmss}.csv" -f (Get-Date))),
    [int]$SuspectMs = 150,
    [switch]$AllKeys
)

$src = @'
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public static class ClickLog
{
    delegate IntPtr HookProc(int code, IntPtr w, IntPtr l);

    [StructLayout(LayoutKind.Sequential)]
    struct MSLL { public int x, y; public uint mouseData, flags, time; public IntPtr extra; }
    [StructLayout(LayoutKind.Sequential)]
    struct KBLL { public uint vk, scan, flags, time; public IntPtr extra; }

    [DllImport("user32.dll", SetLastError = true)]
    static extern IntPtr SetWindowsHookEx(int id, HookProc proc, IntPtr mod, uint thread);
    [DllImport("user32.dll")]
    static extern bool UnhookWindowsHookEx(IntPtr h);
    [DllImport("user32.dll")]
    static extern IntPtr CallNextHookEx(IntPtr h, int code, IntPtr w, IntPtr l);
    [DllImport("kernel32.dll")]
    static extern IntPtr GetModuleHandle(string name);

    static HookProc mouseProc, keyProc;   // kept alive so the GC cannot collect them
    static IntPtr mouseHook, keyHook;
    static StreamWriter log;
    static bool allKeys;
    static readonly Stopwatch clock = new Stopwatch();
    static readonly Dictionary<string, double> lastUp = new Dictionary<string, double>();
    static readonly Dictionary<string, double> lastDown = new Dictionary<string, double>();
    static readonly HashSet<string> held = new HashSet<string>();

    public static int Run(string path, int seconds, bool logAllKeys)
    {
        allKeys = logAllKeys;
        log = new StreamWriter(path, false);
        log.WriteLine("t_ms,button,edge,injected,gap_since_up_ms,hold_ms");
        IntPtr mod = GetModuleHandle(null);
        mouseProc = MouseCb; keyProc = KeyCb;
        clock.Start();
        mouseHook = SetWindowsHookEx(14, mouseProc, mod, 0);
        keyHook = SetWindowsHookEx(13, keyProc, mod, 0);
        if (mouseHook == IntPtr.Zero || keyHook == IntPtr.Zero)
        {
            int err = Marshal.GetLastWin32Error();
            log.Dispose();
            return err == 0 ? -1 : err;
        }
        Timer t = new Timer();
        t.Interval = seconds * 1000;
        t.Tick += delegate { t.Stop(); Application.ExitThread(); };
        t.Start();
        Application.Run();
        UnhookWindowsHookEx(mouseHook);
        UnhookWindowsHookEx(keyHook);
        log.Dispose();
        return 0;
    }

    static void Record(string name, bool down, bool injected)
    {
        double now = clock.Elapsed.TotalMilliseconds;
        string gap = "", hold = "";
        if (down)
        {
            if (held.Contains(name)) return;          // keyboard auto-repeat, not a new press
            held.Add(name);
            double up;
            if (lastUp.TryGetValue(name, out up)) gap = (now - up).ToString("F1", CultureInfo.InvariantCulture);
            lastDown[name] = now;
        }
        else
        {
            held.Remove(name);
            double dn;
            if (lastDown.TryGetValue(name, out dn)) hold = (now - dn).ToString("F1", CultureInfo.InvariantCulture);
            lastUp[name] = now;
        }
        log.WriteLine(string.Join(",", new string[] {
            now.ToString("F1", CultureInfo.InvariantCulture), name, down ? "down" : "up",
            injected ? "1" : "0", gap, hold }));
    }

    static IntPtr MouseCb(int code, IntPtr w, IntPtr l)
    {
        if (code >= 0)
        {
            int msg = w.ToInt32();
            if (msg != 0x200 && msg != 0x20A && msg != 0x20E)   // skip move, wheel, hwheel
            {
                MSLL d = (MSLL)Marshal.PtrToStructure(l, typeof(MSLL));
                bool inj = (d.flags & 1) != 0;
                switch (msg)
                {
                    case 0x201: Record("left", true, inj); break;
                    case 0x202: Record("left", false, inj); break;
                    case 0x204: Record("right", true, inj); break;
                    case 0x205: Record("right", false, inj); break;
                    case 0x207: Record("middle", true, inj); break;
                    case 0x208: Record("middle", false, inj); break;
                    case 0x20B: Record("x" + (d.mouseData >> 16), true, inj); break;
                    case 0x20C: Record("x" + (d.mouseData >> 16), false, inj); break;
                }
            }
        }
        return CallNextHookEx(mouseHook, code, w, l);
    }

    static bool Interesting(uint vk)
    {
        return (vk >= 0xA6 && vk <= 0xB7)    // browser, volume, media, launch keys
            || (vk >= 0x7C && vk <= 0x87);   // F13-F24
    }

    static IntPtr KeyCb(int code, IntPtr w, IntPtr l)
    {
        if (code >= 0)
        {
            KBLL d = (KBLL)Marshal.PtrToStructure(l, typeof(KBLL));
            if (allKeys || Interesting(d.vk))
            {
                int msg = w.ToInt32();
                bool down = (msg == 0x100 || msg == 0x104);
                Record("vk" + d.vk.ToString("X2"), down, (d.flags & 0x10) != 0);
            }
        }
        return CallNextHookEx(keyHook, code, w, l);
    }
}
'@

Add-Type -TypeDefinition $src -ReferencedAssemblies System.Windows.Forms

Write-Host "Recording for $Seconds s. Press each suspect button ~20 times, slowly (about one press per second)."
$rc = [ClickLog]::Run($Out, $Seconds, [bool]$AllKeys)
if ($rc -ne 0) { Write-Error "Could not install hooks (error $rc)"; exit 1 }

$rows = @(Import-Csv $Out)
Write-Host "`nLog: $Out   ($($rows.Count) events)`n"
if ($rows.Count -eq 0) { Write-Host "No button events seen."; exit 0 }

$inv = [Globalization.CultureInfo]::InvariantCulture
$rows | Group-Object button | ForEach-Object {
    $downs = @($_.Group | Where-Object edge -eq 'down')
    $gaps  = @($downs | Where-Object { $_.gap_since_up_ms -ne '' } | ForEach-Object { [double]::Parse($_.gap_since_up_ms, $inv) } | Sort-Object)
    $holds = @($_.Group | Where-Object { $_.hold_ms -ne '' } | ForEach-Object { [double]::Parse($_.hold_ms, $inv) } | Sort-Object)
    [pscustomobject]@{
        Button        = $_.Name
        Presses       = $downs.Count
        Suspect       = @($gaps | Where-Object { $_ -lt $SuspectMs }).Count
        Injected      = @($_.Group | Where-Object injected -eq '1').Count
        ShortestGaps  = (($gaps | Select-Object -First 5 | ForEach-Object { [int]$_ }) -join ' ')
        ShortestHolds = (($holds | Select-Object -First 3 | ForEach-Object { [int]$_ }) -join ' ')
    }
} | Format-Table -AutoSize
Write-Host "Suspect = presses starting < $SuspectMs ms after the previous release of the same button."
