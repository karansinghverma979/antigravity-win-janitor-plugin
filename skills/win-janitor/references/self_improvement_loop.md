# 🧬 The Sentinel Self-Improvement Flywheel

> **Scope**: Specification of the automated drift sensing, candidate buffering, invariant filtering, and schema-driven rule assimilation engine in `win-janitor-plugin`.

---

## 🏛️ 1. Why Static Janitors Fail (The Windows Drift Problem)

Windows is a non-static operating system:
1. **Cumulative Updates**: Patch Tuesday updates frequently restore disabled services (e.g. `DiagTrack`, `WSearch`, `SysMain`) and register new telemetry tasks.
2. **Third-Party App Clutter**: Development and productivity software (browsers, Electron runtimes, update helpers) leave behind orphan daemons and gigabytes of cache in `AppData`.
3. **Startup Creep**: Newly installed tools silently append entries to `HKCU` or `HKLM` `Run` registry keys.

A static script with hardcoded lists becomes obsolete within weeks. Conversely, a blindly self-modifying script that rewrites its own code risks OS corruption, race conditions, and accidental destruction of protected assets.

---

## 🔄 2. The 4-Stage Gated Architecture

```
┌────────────────────────────────────────────────────────────────────────┐
│                   THE SENTINEL EVOLUTION FLYWHEEL                      │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│   1. SENSE (`janitor.ps1 learn`)                                       │
│   ┌────────────────────────────────────────────────────────────────┐   │
│   │ • Scans processes: Filters out 35+ critical system components  │   │
│   │ • Scans startup: Inspects HKCU/HKLM Run keys                   │   │
│   │ • Scans services: Detects telemetry/updater patterns           │   │
│   └───────────────────────────────┬────────────────────────────────┘   │
│                                   │                                    │
│                                   ▼                                    │
│   2. STAGE (`drift.json`)                                              │
│   ┌────────────────────────────────────────────────────────────────┐   │
│   │ • Anomaly buffer outside production code                       │   │
│   │ • Tracks hitCount, firstSeen, lastSeen, recommendedAction      │   │
│   │ • Prevents duplicate logging; updates metadata incrementally   │   │
│   └───────────────────────────────┬────────────────────────────────┘   │
│                                   │                                    │
│                                   ▼                                    │
│   3. VALIDATE (Invariant Guardrails)                                   │
│   ┌────────────────────────────────────────────────────────────────┐   │
│   │ • Hard Sakshi Shield check: Any match immediately purged       │   │
│   │ • System whitelist: Prevents targeting core OS executables     │   │
│   └───────────────────────────────┬────────────────────────────────┘   │
│                                   │                                    │
│                                   ▼                                    │
│   4. ASSIMILATE (`learned_rules.json`)                                 │
│   ┌────────────────────────────────────────────────────────────────┐   │
│   │ • Schema-driven rule insertion (Zero string-splicing code risk)│   │
│   │ • Automatically merged on every `audit`, `trim`, `purge`, etc. │   │
│   └────────────────────────────────────────────────────────────────┘   │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 🛡️ 3. Safety Guardrails & Invariants

### 1. Zero Code Mutation (Configuration-Driven Assimilation)
Under no circumstances does the engine rewrite `janitor.ps1` via text replacement. Instead:
- Core execution logic is fixed and deterministic.
- Dynamic rules live in `learned_rules.json`.
- `janitor.ps1` loads `learned_rules.json` at runtime and merges them with base rules.

### 2. The Sakshi Sanctuary Invariant
Before any candidate is staged in `drift.json` or committed to `learned_rules.json`, it is evaluated by `Assert-SakshiShield`. Any path, task, or argument matching `Sakshi` or `Void\Sakshi` is immediately dropped and blocked.

### 3. The OS Core Process Whitelist
The drift sensor strictly excludes 35+ essential Windows processes, including:
- `System`, `Idle`, `smss`, `csrss`, `wininit`, `services`, `lsass`, `winlogon`
- `explorer`, `dwm`, `fontdrvhost`, `svchost`, `pwsh`, `powershell`, `WindowsTerminal`
- `Secure System`, `DefenderSessionHelper`, `backgroundTaskHost`, `OfficeClickToRun`
- Hardware drivers (`IntelGraphics.*`, `SenaryAudio.*`)

---

## 💻 4. Operational Playbook

### Step 1: Detect Drift
```powershell
pwsh -NoProfile -File "$env:USERPROFILE\.gemini\config\plugins\win-janitor-plugin\skills\win-janitor\scripts\janitor.ps1" learn
```

### Step 2: Review Staged Candidates
Inspect the output table or view `drift.json`. Candidates are classified into:
- **`Process`**: Target for working set trim or ghost process termination.
- **`Service`**: Target for baseline disabling.
- **`Startup`**: Target for boot Run key removal.
- **`Folder`**: Target for residual AppData purge.

### Step 3: Assimilate or Whitelist
```powershell
# Assimilate candidate into permanent learned rules
pwsh -NoProfile -File "$env:USERPROFILE\.gemini\config\plugins\win-janitor-plugin\skills\win-janitor\scripts\janitor.ps1" assimilate <candidate-id>

# Or ignore candidate (whitelist)
pwsh -NoProfile -File "$env:USERPROFILE\.gemini\config\plugins\win-janitor-plugin\skills\win-janitor\scripts\janitor.ps1" ignore <candidate-id>
```
