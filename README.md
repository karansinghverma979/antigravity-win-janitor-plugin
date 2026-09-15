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
├── skills/
│   └── win-janitor/
│       ├── SKILL.md                       # Antigravity Skill instructions & router
│       ├── scripts/
│       │   └── janitor.ps1                # Pure PowerShell 7 execution engine
│       └── references/
│           ├── diagnostic_playbooks.md    # RAM/CPU troubleshooting playbooks
│           ├── sakshi_shield_invariant.md # Immutable sanctuary protection contract
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
   - **`updates`**: Analyzes recent Windows Cumulative Updates and reverses any silent telemetry service restoration.

6. **🛡️ The Sanctuary Shield Invariant**:
   - Immutable security contract that safeguards designated sanctuary tasks, directories, and credentials from automated termination or deletion.

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

# 1. System Health Audit
pwsh -NoProfile -File $Janitor audit

# 2. Reclaim Process Working Sets
pwsh -NoProfile -File $Janitor trim

# 3. Clean Residual Caches & Leftover Files
pwsh -NoProfile -File $Janitor purge

# 4. Enforce Baseline Services (Run as Administrator)
sudo pwsh -NoProfile -File $Janitor enforce-baseline

# 5. Root-Cause Diagnostic Scenarios
pwsh -NoProfile -File $Janitor diagnose ram
pwsh -NoProfile -File $Janitor diagnose cpu
sudo pwsh -NoProfile -File $Janitor updates
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
