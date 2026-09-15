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

## 2. Shell Animation Stutter on High-Refresh Displays

Windows 11 enables window slide animations (`MinAnimate = 1`) by default.
- On displays with 120Hz refresh rates and integrated graphics (Intel Iris Xe / Arc), calculating slide interpolation while rendering 2.8K composited surfaces across multiple virtual desktop states causes significant frame drops and compositor micro-stutters.
- Disabling slide animations sets virtual desktop switching to **instant (0ms)**, eliminating the DWM transition pipeline overhead completely.

---

## 3. Remediation Protocol (`fix-shell`)

The remediation routine implemented in `janitor.ps1 fix-shell` executes in 5 sequential stages:

### Stage 1: Animation Optimization
Enforces 0ms switching and disables taskbar slide animations:
```powershell
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value "0" -Force
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAnimations" -Value 0 -Type DWord -Force
```

### Stage 2: COM Worker Termination
Forcefully terminates all active `dllhost.exe` processes to release file handles on thumbnail databases, followed by terminating `explorer.exe`:
```powershell
Get-Process dllhost -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
```

### Stage 3: Corrupted Database Purge
Purges all `thumbcache_*.db` and `iconcache_*.db` files from:
- `%LOCALAPPDATA%\Microsoft\Windows\Explorer\`
- `%LOCALAPPDATA%\IconCache.db`

### Stage 4: Shell Restoration
Relaunches a fresh `explorer.exe` process, triggering clean cache database initialization without legacy corruptions:
```powershell
Start-Process explorer.exe
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
