# 🖥️ Windows Shell, DWM & UI Freeze Troubleshooting Guide

## 1. Executive Summary & Root Cause Architecture

On Windows 11 (specifically 24H2 builds, e.g., 26100+ running high-resolution displays such as 2.8K 2880×1800 @ 120Hz), users frequently experience intermittent shell freezes characterized by:
1. **Virtual Desktop Switch Pauses**: Switching desktops (`Win + Ctrl + Left/Right`) stalls for 2–10 seconds or hangs indefinitely.
2. **Spinning Cursor & Dropped Input**: Mouse cursor enters infinite loading state; keyboard and mouse inputs are queued or dropped.
3. **Desktop Right-Click Freeze**: Right-clicking on the desktop wallpaper either fails to render the context menu or freezes the Explorer UI thread.
4. **Terminal & Window Control Lockup**: Windows Terminal freezes during text selection, scrolling, or copying; window minimize/maximize controls disappear or become unresponsive.

### The Anatomy of `AppHangXProcB1`
When analyzing Windows Error Reporting (WER Event ID 1001) and Application Hangs (Event ID 1002), the root cause is:
- **Faulting Process**: `explorer.exe` (UI thread)
- **Failure Type**: `AppHangXProcB1` (Cross-Process Synchronous RPC Deadlock)
- **Blocked Target**: `P6: dllhost.exe:{ab8902b4-09ca-4bb6-b78d-a8f59079a8d5}`

`{ab8902b4-09ca-4bb6-b78d-a8f59079a8d5}` is the CLSID for the **Thumbnail Cache Out of Proc Server** (`thumbcache.dll`).

```
┌────────────────────────────────────────────────────────┐
│                   Explorer.exe UI Thread               │
└──────────────────────────┬─────────────────────────────┘
                           │ Synchronous COM / RPC Call
                           ▼
┌────────────────────────────────────────────────────────┐
│      dllhost.exe (Thumbnail Cache Out of Proc Server)  │
└──────────────────────────┬─────────────────────────────┘
                           │ File I/O & Database Locks
                           ▼
┌────────────────────────────────────────────────────────┐
│   %LOCALAPPDATA%\Microsoft\Windows\Explorer\           │
│   thumbcache_*.db & iconcache_*.db (Corrupted / Locked)│
└────────────────────────────────────────────────────────┘
```

When high-resolution thumbnail generation collides with corrupted SQLite/Extensible Storage Engine cache headers or concurrent lock contention, `dllhost.exe` hangs. Because Explorer makes synchronous calls to generate virtual desktop taskbar previews and context menu shell extensions, the entire desktop UI thread deadlocks.

---

## 2. Shell Animation Traps: The Task View (`Win+Tab`) & `Alt+Tab` Invariant

In Windows 11 (24H2 XAML Shell architecture):
- **Modern XAML Storyboard Dependency**: Modern `Alt+Tab` and Task View (`Win+Tab` / Multitasking View) are rendered by XAML Islands hosted in the shell. Their entrance transitions **directly subscribe to taskbar animation events**.
- **The Registry Trap**: Setting `TaskbarAnimations = 0` or `MinAnimate = 0` directly in the registry suppresses the animation storyboard trigger entirely. As a result, pressing `Alt+Tab` or `Win+Tab` fails to instantiate the overlay, leaving multitasking unresponsive.
- **The Duplicate Explorer Race Condition**: When `explorer.exe` is stopped, Windows Winlogon automatically resurrects the primary shell within milliseconds. If an automated script calls `Start-Process explorer.exe` without checking, **two concurrent explorer.exe processes** run in Session 1, fighting for global keyboard hooks (`WM_HOTKEY`, `RegisterShellHookWindow`) and breaking Task View.

---

## 3. Remediation Protocol (`fix-shell`)

The remediation routine implemented in `janitor.ps1 fix-shell` executes in 5 sequential stages:

### Stage 1: Shell & Task View Compatibility Verification
Ensures the XAML storyboard transition pipeline is intact:
```powershell
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAnimations" -Value 1 -Type DWord -Force
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value "1" -Force
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value 1 -Type DWord -Force
```

### Stage 2: COM Worker, Shell Hosts & Duplicate Explorer Termination
Terminates all locked `dllhost.exe` workers, all duplicate `explorer.exe` processes, and modern shell hosts (`ShellExperienceHost`, `StartMenuExperienceHost`):
```powershell
Get-Process dllhost -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Stop-Process -Name explorer, ShellExperienceHost, StartMenuExperienceHost -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 1500
```

### Stage 3: Corrupted Database Purge
Purges all `thumbcache_*.db` and `iconcache_*.db` files from:
- `%LOCALAPPDATA%\Microsoft\Windows\Explorer\`
- `%LOCALAPPDATA%\IconCache.db`

### Stage 4: Single Authoritative Shell Resurrection
Verifies Winlogon auto-restart and guarantees **exactly one** authoritative `explorer.exe` instance:
```powershell
Start-Sleep -Milliseconds 1500
$ex = Get-Process explorer -ErrorAction SilentlyContinue
if (-not $ex) {
    Start-Process explorer.exe
    Start-Sleep -Milliseconds 1500
}
```

### Stage 5: Compositor Working Set Flush
Calls `EmptyWorkingSet` on Desktop Window Manager (`dwm.exe`) to reclaim orphaned compositor swapchains and GPU memory surfaces.

---

## 4. Diagnostics CLI (`diagnose shell`)

To inspect shell health and detect latent hangs before they freeze user workflows:
```powershell
pwsh -NoProfile -File "skills/win-janitor/scripts/janitor.ps1" diagnose shell
```

The diagnostic routine evaluates:
1. **Event Log ID 1002**: Quantifies explorer/DWM hangs over the last 72 hours.
2. **WER Event ID 1001 (`AppHangXProcB1`)**: Inspects cross-process RPC targets to identify misbehaving shell extensions or COM hosts.
3. **Compositor Footprint**: Tracks memory and handle counts for `dwm.exe`, `explorer.exe`, and `WindowsTerminal.exe`.
4. **Display & Animation States**: Verifies resolution, refresh rate, and `MinAnimate` configuration.
