---
name: win-janitor
description: >-
  Autonomous Windows 11 system janitor, bloatware eradicater, and performance governor.
  Use whenever auditing Windows memory, trimming RAM working-sets, purging uninstalled app leftovers,
  disabling telemetry background services, investigating CPU/RAM spikes, enforcing baseline OS policies,
  or recovering from Windows Update bloat drift on Motobook.
---

# 🧹 Win-Janitor: Windows Performance & System Governor

The authoritative management skill and runbook for maintaining Windows 11 workstations in a pristine, low-latency state tailored for core developer workflows (**Terminal 50%, Browser 30%, Obsidian/Notes 20%**).

---

## 🏛️ Core Principles & Invariants

```
┌────────────────────────────────────────────────────────────────────────┐
│                        WIN-JANITOR ARCHITECTURE                        │
├───────────────────┬───────────────────┬────────────────────────────────┤
│ 🛡️ SAKSHI SHIELD  │ ⚡ MEMORY GOVERNOR │ 🧹 ZERO-LEFTOVER INVARIANT     │
├───────────────────┼───────────────────┼────────────────────────────────┤
│ • Task: \Sakshi   │ • EmptyWorkingSet │ • AppData & Registry purged    │
│ • Path: /Sakshi/  │ • 0% Boot Bloat   │ • 10 Services Kept Disabled    │
│ • ZERO MUTATION   │ • Standby Trimming│ • Edge background mode blocked │
└───────────────────┴───────────────────┴────────────────────────────────┘
```

1. **🛡️ Sakshi Shield (Zero Mutation Invariant)**:
   - All tasks, files, and resources matching `Sakshi` or `Void\Sakshi` are **100% immune** from deletion, termination, or modification.
   - Deep specification: [Sakshi Shield Specification](./references/sakshi_shield_invariant.md).
2. **Deterministic CLI Engine**:
   - Every operation is powered by `scripts/janitor.ps1` with zero runtime dependencies.
3. **No 24/7 Daemon Footprint**:
   - `win-janitor` consumes **0 MB RAM and 0% CPU idle**. It runs on-demand or during the 360° Session Boot Radar.

---

## 🔄 The 5 Core Operations

### 1. 📊 System Health & Memory Audit (`audit`)
Fast, non-invasive diagnostic check across physical RAM, top 10 memory consumers, baseline services, and startup registry keys:

```powershell
pwsh -NoProfile -File "$env:USERPROFILE\.gemini\config\plugins\win-janitor-plugin\skills\win-janitor\scripts\janitor.ps1" audit
```

### 2. ⚡ Instant Working-Set Memory Trim (`trim`)
Calls the Win32 `EmptyWorkingSet` API across inactive background processes, terminates ghost helpers (`Widgets`, `CrossDeviceResume`, `IGCCTray`), and executes garbage collection without restarting apps:

```powershell
pwsh -NoProfile -File "$env:USERPROFILE\.gemini\config\plugins\win-janitor-plugin\skills\win-janitor\scripts\janitor.ps1" trim
```

### 3. 🧹 Deep Cache & Leftover Purge (`purge`)
Wipes residual caches and ghost directories left behind by uninstalled applications (`Google`, `Telegram`, `Notion`, `Anytype`, `Ollama`), cleans temporary files, and audits package caches:

```powershell
pwsh -NoProfile -File "$env:USERPROFILE\.gemini\config\plugins\win-janitor-plugin\skills\win-janitor\scripts\janitor.ps1" purge
```

### 4. 🛡️ Baseline Integrity Enforcement (`enforce-baseline`)
Enforces the pristine operating system baseline:
- Keeps the **10 bloat services** (`WSearch`, `SysMain`, `DiagTrack`, `InventorySvc`, `wuqisvc`, `whesvc`, `dptftcs`, `DPS`, `Spooler`, `TrkWks`) disabled.
- Keeps Microsoft Edge background daemon and startup boost blocked via Group Policy.
- Keeps Windows 11 Widgets board blocked via Group Policy.

```powershell
sudo pwsh -NoProfile -File "$env:USERPROFILE\.gemini\config\plugins\win-janitor-plugin\skills\win-janitor\scripts\janitor.ps1" enforce-baseline
```

### 5. 🔍 Root-Cause Diagnostics & Update Drift (`diagnose`)
Scenario-based investigations for high RAM, runaway CPU spikes, or Windows Update service drift:

```powershell
# Investigate High RAM root cause
pwsh -NoProfile -File "$env:USERPROFILE\.gemini\config\plugins\win-janitor-plugin\skills\win-janitor\scripts\janitor.ps1" diagnose ram

# Investigate High CPU spikes
pwsh -NoProfile -File "$env:USERPROFILE\.gemini\config\plugins\win-janitor-plugin\skills\win-janitor\scripts\janitor.ps1" diagnose cpu

# Reverse telemetry drift after a Windows Cumulative Update
sudo pwsh -NoProfile -File "$env:USERPROFILE\.gemini\config\plugins\win-janitor-plugin\skills\win-janitor\scripts\janitor.ps1" updates
```

### 6. 📡 Drift Sensor & Continuous Learning (`learn`)
Scans for unmapped background daemons, newly added startup registry hooks, and telemetry services installed by OS updates or new apps, staging them into `drift.json`:

```powershell
pwsh -NoProfile -File "$env:USERPROFILE\.gemini\config\plugins\win-janitor-plugin\skills\win-janitor\scripts\janitor.ps1" learn
```

### 7. 🧬 Gated Rule Assimilation (`assimilate` & `ignore`)
Assimilates candidate rules dynamically into `learned_rules.json` without touching core code, instantly extending `trim`, `purge`, and `enforce-baseline`:

```powershell
# Assimilate a specific candidate by ID
pwsh -NoProfile -File "$env:USERPROFILE\.gemini\config\plugins\win-janitor-plugin\skills\win-janitor\scripts\janitor.ps1" assimilate <candidate-id>

# Or whitelist/ignore a benign candidate
pwsh -NoProfile -File "$env:USERPROFILE\.gemini\config\plugins\win-janitor-plugin\skills\win-janitor\scripts\janitor.ps1" ignore <candidate-id>
```

### 8. 📦 Package Manager Hygiene (`packages`)
Audits and purges historical Scoop application versions and cache archives, and checks Winget upgrades:

```powershell
# Audit pending Scoop and Winget updates
pwsh -NoProfile -File "$env:USERPROFILE\.gemini\config\plugins\win-janitor-plugin\skills\win-janitor\scripts\janitor.ps1" packages audit

# Clean old Scoop versions and installer caches
pwsh -NoProfile -File "$env:USERPROFILE\.gemini\config\plugins\win-janitor-plugin\skills\win-janitor\scripts\janitor.ps1" packages clean
```

### 9. 🛣️ Environment PATH Deduplication & Dead Directory Pruner (`path-clean`)
Scans the User `PATH`, removes duplicates, prunes non-existent directories, and saves an automatic timestamped backup:

```powershell
pwsh -NoProfile -File "$env:USERPROFILE\.gemini\config\plugins\win-janitor-plugin\skills\win-janitor\scripts\janitor.ps1" path-clean
```

### 10. 🧹 Residual Registry Hive Purger (`reg-clean`)
Scans `HKCU:\Software` and `HKLM:\Software` for abandoned vendor keys of uninstalled software (`Google`, `VMware`, `Notion`, `Ollama`, etc.) with pre-deletion `.reg` export backups:

```powershell
pwsh -NoProfile -File "$env:USERPROFILE\.gemini\config\plugins\win-janitor-plugin\skills\win-janitor\scripts\janitor.ps1" reg-clean
```

### 11. 🐍 Developer Environment & Python Isolation (`dev-hygiene`)
Audits global Python packages vs. local virtual environments, inspects NPM cache sizes, and verifies Rule 8 path portability:

```powershell
pwsh -NoProfile -File "$env:USERPROFILE\.gemini\config\plugins\win-janitor-plugin\skills\win-janitor\scripts\janitor.ps1" dev-hygiene
```

### 12. 🖥️ Windows Shell, DWM & UI Freeze Remediation (`fix-shell`)
Eliminates virtual desktop switching lag (enforces 0ms switching), terminates frozen `dllhost.exe` RPC thumbnail workers (`AppHangXProcB1`), purges corrupted `thumbcache_*.db` / `iconcache_*.db` databases, restarts Explorer, and refreshes the DWM compositor:

```powershell
pwsh -NoProfile -File "$env:USERPROFILE\.gemini\config\plugins\win-janitor-plugin\skills\win-janitor\scripts\janitor.ps1" fix-shell
```

---

## 📖 Deep Technical References

- [Windows Shell, DWM & UI Freeze Troubleshooting](./references/shell_and_ui_troubleshooting.md)
- [Package, PATH & System Hygiene Runbook](./references/package_and_system_hygiene.md)
- [The Sentinel Self-Improvement Flywheel](./references/self_improvement_loop.md)
- [Windows 11 Memory Internals & Working Sets](./references/windows_internals_memory.md)
- [Diagnostic Triage Playbooks: Why & When Issues Come](./references/diagnostic_playbooks.md)
- [Windows Updates & Component Store Servicing](./references/update_and_servicing.md)
- [Sakshi Shield Specification](./references/sakshi_shield_invariant.md)
