# 🧹 antigravity-win-janitor-plugin

> **Autonomous Windows 11 System Janitor, Bloatware Eradicator & Performance Governor Plugin for Google Antigravity.**

An enterprise-grade, deterministic Antigravity plugin engineered to keep Windows 11 developer workstations in a low-latency, zero-bloat state. It combines an autonomous AI agent (`win_janitor`), specialized skills, a Win32 API-backed PowerShell engine (`janitor.ps1`), and root-cause diagnostic playbooks.

---

## 🏛️ Architecture

```
antigravity-win-janitor-plugin/
├── agents/
│   └── win_janitor.md                     # Declarative Antigravity Agent definition
├── plugin.json                            # Antigravity Plugin manifest
├── drift.json                             # Anomaly buffer for detected drift & candidates
├── learned_rules.json                     # Dynamic schema-driven assimilated rules
├── skills/
│   └── win-janitor/
│       ├── SKILL.md                       # Antigravity Skill instructions & router
│       ├── scripts/
│       │   └── janitor.ps1                # Pure PowerShell 7 execution engine
│       └── references/
│           ├── diagnostic_playbooks.md    # RAM/CPU troubleshooting playbooks
│           ├── package_and_system_hygiene.md # Scoop/Winget, PATH & Registry runbook
│           ├── sakshi_shield_invariant.md # Immutable sanctuary protection contract
│           ├── self_improvement_loop.md   # Drift sensor & assimilation architecture
│           ├── shell_and_ui_troubleshooting.md # DWM, virtual desktop & shell freeze runbook
│           ├── update_and_servicing.md    # Component store (WinSxS) & update hygiene
│           └── windows_internals_memory.md# Win32 working set & paging internals
├── .gitignore
├── LICENSE
└── README.md
```

---

## ⚡ Core Capabilities

```
┌────────────────────────────────────────────────────────────────────────┐
│                        WIN-JANITOR CAPABILITIES                        │
├───────────────────┬───────────────────┬────────────────────────────────┤
│ 🛡️ SAKSHI SHIELD  │ ⚡ MEMORY GOVERNOR │ 🧹 ZERO-LEFTOVER INVARIANT     │
├───────────────────┼───────────────────┼────────────────────────────────┤
│ • Zero Mutation   │ • EmptyWorkingSet │ • Ghost AppData clean          │
│ • Task Protection │ • Standby Flush   │ • 10 Bloat Services Disabled   │
│ • Path Sanctuary  │ • 0% CPU Idle     │ • Edge & Widgets Policed       │
└───────────────────┴───────────────────┴────────────────────────────────┘
```

1. **📊 Instant System Audit (`audit`)**:
   - Inspects physical RAM, available memory, top 10 memory-consuming processes, baseline service states, and startup registry entries (`HKCU`/`HKLM` Run keys).

2. **⚡ Win32 Working-Set Trimming (`trim`)**:
   - Uses the Win32 `EmptyWorkingSet` API (`psapi.dll`) to reclaim inactive working-set pages into the standby list.
   - Cleans up detached zombie background processes (`Widgets`, `CrossDeviceResume`, `IGCCTray`) and forces garbage collection.

3. **🧹 Deep Cache & Leftover Scrubber (`purge`)**:
   - Recursively deletes residual AppData/Local/Roaming folders left behind by uninstalled applications.
   - Flushes temporary file directories safely without corrupting locked active files.

4. **🛡️ Baseline Telemetry Enforcement (`enforce-baseline`)**:
   - Enforces **10 background bloat/telemetry services** to `Disabled`:
     - `WSearch` (Windows Search Indexer)
     - `SysMain` (Superfetch RAM thrashing)
     - `DiagTrack` (Connected User Experiences and Telemetry)
     - `InventorySvc` (Compatibility Appraisal)
     - `wuqisvc` (Quality Insights)
     - `whesvc` (Windows Health Experiences)
     - `dptftcs` (Intel Dynamic Tuning Telemetry)
     - `DPS` (Diagnostic Policy Service)
     - `Spooler` (Print Spooler)
     - `TrkWks` (Distributed Link Tracking)
   - Enforces Group Policy blocks against Edge background daemons and Windows 11 Widgets.

5. **🔍 Scenario Diagnostics (`diagnose`)**:
   - **`diagnose ram`**: Deep memory allocation inspection.
   - **`diagnose cpu`**: CPU spike root-cause analysis.
   - **`diagnose shell`**: Windows Shell, DWM compositor, and cross-process RPC hang diagnostics (`AppHangXProcB1`).
   - **`updates`**: Analyzes recent Windows Cumulative Updates and reverses any silent telemetry service restoration.

6. **🖥️ Windows Shell & Virtual Desktop Freeze Remediation (`fix-shell`)**:
   - Solves virtual desktop switching latency, desktop right-click freezes, and terminal UI lockups.
   - Enforces 0ms switching (`MinAnimate = 0`), terminates blocked `dllhost.exe` RPC thumbnail workers, purges corrupted `thumbcache_*.db` / `iconcache_*.db` databases, restarts Explorer, and refreshes the DWM compositor.

7. **🛡️ The Sanctuary Shield Invariant**:
   - Immutable security contract that safeguards designated sanctuary tasks, directories, and credentials from automated termination or deletion.

8. **🧬 The Sentinel Self-Improvement Flywheel**:
   - Continuous drift sensing (`janitor.ps1 learn`) that catches newly registered telemetry daemons, services, dead PATH entries, or boot keys after Windows Updates.
   - Dynamic schema-driven rule assimilation (`learned_rules.json`) that expands protection without editing core source code.

9. **📦 Package Manager Ecosystem Governor (`packages`)**:
   - Audits and purges Scoop historical versions (`scoop cleanup *`) and cache archives (`scoop cache rm *`).
   - Audits Windows Package Manager for pending application upgrades (`winget upgrade`).

10. **🛣️ Environment PATH Deduplication & Dead Directory Pruner (`path-clean`)**:
    - Scans User `PATH`, removes redundant duplicates, prunes non-existent directory paths, and creates timestamped pre-cleanup backups.

11. **🧹 Residual Registry Hive Purger (`reg-clean`)**:
    - Scans and purges leftover vendor registry keys from uninstalled software (`Google`, `VMware`, `Notion`, `Ollama`, etc.) with pre-deletion `.reg` export backups.

12. **🐍 Developer Environment & Python Isolation (`dev-hygiene`)**:
    - Audits global Python pip installations to prevent dependency pollution and ensure virtual environment isolation (`uv` / `venv`).
    - Verifies NPM cache sizes and enforces Rule 8 portable pathing standards.

---

## 🚀 Installation

### Option 1: Global Plugin Directory (Recommended)

Clone or copy this repository into your user Antigravity plugin directory:

```powershell
git clone https://github.com/karansinghverma979/antigravity-win-janitor-plugin.git "$env:USERPROFILE\.gemini\config\plugins\win-janitor-plugin"
```

Once placed, Antigravity automatically detects the plugin, registers the `win_janitor` agent, and activates the `win-janitor` skill across all sessions.

---

## 💻 CLI Usage (Direct PowerShell 7)

All operations can be executed directly without Antigravity via PowerShell 7:

```powershell
$Janitor = "$env:USERPROFILE\.gemini\config\plugins\win-janitor-plugin\skills\win-janitor\scripts\janitor.ps1"

# 1. System Health & RAM Audit
pwsh -NoProfile -File $Janitor audit

# 2. Reclaim Process Working Sets (EmptyWorkingSet Win32 API)
pwsh -NoProfile -File $Janitor trim

# 3. Clean Residual Caches & Leftover Files
pwsh -NoProfile -File $Janitor purge

# 4. Enforce Baseline Services (Run as Administrator)
sudo pwsh -NoProfile -File $Janitor enforce-baseline

# 5. Root-Cause Diagnostic Scenarios
pwsh -NoProfile -File $Janitor diagnose ram
pwsh -NoProfile -File $Janitor diagnose cpu
pwsh -NoProfile -File $Janitor diagnose shell
sudo pwsh -NoProfile -File $Janitor updates

# 6. Windows Shell & Desktop Freeze Remediation
pwsh -NoProfile -File $Janitor fix-shell

# 7. Package Manager Hygiene (Scoop & Winget)
pwsh -NoProfile -File $Janitor packages audit
pwsh -NoProfile -File $Janitor packages clean

# 8. Environment PATH Deduplication & Dead Directory Pruning
pwsh -NoProfile -File $Janitor path-clean

# 9. Residual Registry Hive Purge (Uninstalled Software Leftovers)
pwsh -NoProfile -File $Janitor reg-clean

# 10. Developer Environment & Python Dependency Hygiene
pwsh -NoProfile -File $Janitor dev-hygiene

# 11. Sense Drift & Detect New Telemetry / Bloat Daemons
pwsh -NoProfile -File $Janitor learn

# 12. Assimilate or Whitelist Candidates
pwsh -NoProfile -File $Janitor assimilate <candidate-id>
pwsh -NoProfile -File $Janitor ignore <candidate-id>
```

---

## 🤖 Antigravity Agent Usage

You can invoke the agent directly inside Antigravity conversations:

```
@win_janitor audit the workstation and trim idle memory
```

Or invoke via subagent orchestration:
```json
{
  "TypeName": "win_janitor",
  "Role": "Windows System Janitor",
  "Prompt": "Perform a system audit, check memory pressure, and enforce baseline policies."
}
```

---

## 🔒 Security & Privacy

- **Zero Telemetry**: Collects zero telemetry, zero analytics, and makes zero network calls.
- **Path Portability**: Fully decoupled from hardcoded user paths using `$env:USERPROFILE` and dynamic environment variables.
- **Fail-Safe Shield**: `Assert-SakshiShield` stops any destructive call if a protected target is matched.

---

## 📄 License

MIT License. See [LICENSE](./LICENSE) for details.
