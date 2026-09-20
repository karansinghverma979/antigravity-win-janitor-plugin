# 🧹 Win-Janitor: Agent Rules & Operational Invariants

Whenever invoking the `win_janitor` agent or executing maintenance operations via `janitor.ps1`, all Antigravity agents must strictly obey these directives:

---

### 1. 🛡️ The Sakshi Immutable Sanctuary Invariant (Rule Zero)
* **ABSOLUTE RULE**: Under **NO circumstances** shall you ever kill, pause, modify, relocate, or delete any asset belonging to **`Sakshi`**:
  1. **Scheduled Task**: `\Sakshi` (Running `powershell.exe` with `Sakshi.ps1`) — **MUST REMAIN ACTIVE AT ALL TIMES**.
  2. **Sanctuary Directory**: `%USERPROFILE%\Void\Sakshi\` and all child files.
  3. **Protected Assets & Credentials**: Any process, file, service, or path matching `*Sakshi*`.
* If any command, sweep, or query targets a path containing `Sakshi`, immediately abort that specific target, bypass it safely, and log that the Sakshi Shield was asserted.

---

### 2. ⚡ Safe Working-Set Trimming Over Process Termination
* Reclaim RAM primarily through Win32 `EmptyWorkingSet` memory flush (`psapi.dll`), which shifts unreferenced pages to the standby list without terminating running applications.
* Never terminate developer workflows (active Neovim, PowerShell sessions, IDEs, code editors, or browser windows with active developer state).
* Only terminate known detached background ghosts (`Widgets`, `CrossDeviceResume`, `IGCCTray`, `TextInputHost` memory leaks, orphaned `SearchHost` WebView2 subprocesses).

---

### 3. 💾 Runtime State Decoupling & Quarantine
* Pre-cleanup registry dumps (`reg_*.reg`) and user `PATH` backups (`path_backup_*.txt`) must **never** be saved inside the git working tree.
* All runtime backups must be written to `%LOCALAPPDATA%\win-janitor\backups\` (or git-ignored `.local/backups` fallback).
* `drift.json` and `learned_rules.json` must remain clean and generic, containing zero machine-specific user paths.

---

### 4. 🛣️ Zero Absolute Machine Path Leaks
* Never hardcode `C:\Users\<username>\` in any scripts, rules, or documentation.
* Enforce dynamic resolution via `$env:USERPROFILE`, `$env:LOCALAPPDATA`, or `[Environment]::GetFolderPath(...)`.

---

### 5. 🧬 Dynamic Rule Schema Integrity
* Candidate telemetry daemons and bloat services must stage through `drift.json` before assimilation into `learned_rules.json`.
* Both files must conform to their JSON schema and pass validation before saving.
