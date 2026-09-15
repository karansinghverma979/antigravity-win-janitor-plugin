# 📖 Windows Triage & Diagnostic Playbooks: Root Causes & Remediation

*Authoritative diagnostic guide for the `win_janitor` subagent: Explains why issues occur, when they occur, how to detect them, and the exact deterministic fix.*

---

## 🚨 Playbook 1: High RAM Utilization (>75%–85%)

### Why It Happens:
1. **Standby Memory Traps**: Windows file-cache keeps gigabytes of read files in Standby state instead of flushing to free memory.
2. **Electron / WebApp Proliferation**: Each open tab, Obsidian plugin, Edge WebView2, or terminal process creates multiple renderer child processes with separate V8 heaps.
3. **Orphaned Background Daemons**: Apps like PowerToys, Widgets, Notion updaters, and Teams keep processes alive even when the window is closed.

### When It Happens:
- After prolonged system uptime (>48–72 hours).
- After heavy multitasking sessions (multiple browser tabs + IDE + local servers).

### How to Diagnose:
```powershell
Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 10 Id, ProcessName, @{N="RAM_MB";E={[math]::Round($_.WorkingSet64/1MB,1)}}, @{N="Priv_MB";E={[math]::Round($_.PrivateMemorySize64/1MB,1)}} | Format-Table
```

### Deterministic Remediation:
1. Call `EmptyWorkingSet` across inactive processes via `sentinel.ps1 trim`.
2. Terminate rogue background ghosts (`Widgets.exe`, `CrossDeviceResume.exe`).
3. If Edge is consuming >1.5GB, advise user to use `Shift + Esc` in Edge to close hung background tabs.

---

## ⚡ Playbook 2: High CPU Spikes & Fan Ramping

### Why It Happens:
1. **`TiWorker.exe` / `TrustedInstaller.exe`**: Windows Update or Component-Based Servicing (CBS) is compiling native images or scanning packages.
2. **`WmiPrvSE.exe` (WMI Provider Host)**: A monitoring tool or hardware sensor is polling WMI queries too rapidly with memory leaks.
3. **`SearchIndexer.exe`**: Windows Search walking recursive code repositories.
4. **`MsMpEng.exe`**: Defender real-time scanning file writes during git operations.

### When It Happens:
- Right after boot, or when a background Windows Update check fires.
- When running `npm install`, `cargo build`, or compiling code in directories without Defender exclusions.

### How to Diagnose:
```powershell
Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 Id, ProcessName, @{N="CPU_s";E={[math]::Round($_.CPU,1)}}
```

### Deterministic Remediation:
1. If `WSearch` is active $\rightarrow$ Stop and disable `WSearch`.
2. If `MsMpEng` is spiking $\rightarrow$ Verify developer exclusions (`.gemini`, `scoop`, `Obsidian`) are registered in `Add-MpPreference`.
3. If `WmiPrvSE` is pegged $\rightarrow$ Run `Restart-Service winmgmt -Force` (if elevated).

---

## 🔄 Playbook 3: Windows Update Reversion Drift (The Cumulative Update Trap)

### Why It Happens:
Whenever Microsoft pushes a Cumulative Update (e.g. Patch Tuesday KB packages) or a feature update:
- Windows servicing overwrites registry flags.
- It silently restores `DiagTrack`, `WSearch`, `SysMain`, and `Edge Startup Boost` back to `Automatic` / `Enabled`.
- It re-registers default AppX packages (like Widgets / WebExperience).

### When It Happens:
- 24–48 hours after a Windows Update restarts the machine.

### How to Diagnose:
```powershell
Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 3
Get-Service DiagTrack, WSearch, SysMain | Select-Object Name, Status, StartType
```

### Deterministic Remediation:
Run `sentinel.ps1 enforce-baseline`. It immediately resets all 10 services back to `Disabled`, re-applies Edge and Widget Group Policies, and restores the pristine workstation state.

---

## 🧹 Playbook 4: Leftover AppData & Registry Ghost Accumulation

### Why It Happens:
Standard Windows uninstalls (MSI or InnoSetup) almost NEVER delete user profile data in:
- `%LOCALAPPDATA%\<AppName>` (caches, logs, telemetry, SQLite DBs)
- `%APPDATA%\<AppName>` (settings, credentials)
- `HKCU:\Software\<AppName>` and `HKCU:\...\Run`
- `%LOCALAPPDATA%\Package Cache` (installer setups cached forever)

### When It Happens:
- After removing any software (Google Chrome, Notion, Telegram, Ollama, PC Manager).

### How to Diagnose:
```powershell
$ghostPaths = @("$env:LOCALAPPDATA\Google", "$env:APPDATA\Telegram Desktop", "$env:LOCALAPPDATA\Programs\Notion", "$env:LOCALAPPDATA\notion-updater")
$ghostPaths | Where-Object { Test-Path $_ }
```

### Deterministic Remediation:
Run `sentinel.ps1 purge`. It automatically validates the path against the **Sakshi Shield**, then recursively wipes orphaned folders and frees disk space.
