# 📦 Package, PATH & System Hygiene Runbook

> **Scope**: Standard operating procedures for package managers, environment variables, residual registry hives, and developer dependency hygiene.

---

## 🏛️ 1. Package Manager Maintenance (Scoop & Winget)

### 1. Scoop Version & Cache Hygiene
Over time, Scoop accumulates historical versions of binaries (e.g. `python`, `nodejs-lts`, `git`, `neovim`) across `$env:USERPROFILE\scoop\apps\<app>\<version>`. This can consume tens of gigabytes of disk space.
- **Audit**: `janitor.ps1 packages audit`
- **Cleanup**: `janitor.ps1 packages clean` (Executes `scoop cleanup *` to delete old versions and `scoop cache rm *` to delete installer cache archives).

### 2. Winget Upgrade Auditing
Windows Package Manager tracks native desktop applications and MSI packages.
- `winget upgrade --include-unknown` queries upstream manifests for security patches and new versions.

---

## 🛣️ 2. Environment Variable & PATH Hygiene

### The Problem
When software (e.g. Ollama, VMware, old SDKs, discarded editors) is uninstalled, Windows frequently fails to clean up entries in the User and System `PATH` environment variables. Over time:
1. **Dead Directories**: The shell searches paths that no longer exist, introducing execution latency.
2. **Duplication Clutter**: Duplicate directory entries inflate the `PATH` length beyond standard limits.

### The Solution: `janitor.ps1 path-clean`
1. **Deduplication**: Case-insensitive normalization (`TrimEnd('\')`) and hash set tracking.
2. **Dead Path Pruning**: Verifies path existence via `Test-Path`.
3. **Automated Safety Backup**: Exports pre-cleanup PATH to `%LOCALAPPDATA%\win-janitor\backups\path_backup_<timestamp>.txt` (or `.local\backups` fallback).
4. **Instant In-Memory & Persistent Sync**: Updates `[Environment]::SetEnvironmentVariable` and `$env:PATH`.

---

## 🧹 3. Residual Registry Hive Purging

### The Problem
Applications frequently leave abandoned vendor keys in `HKCU:\Software` and `HKLM:\Software` after uninstallation (e.g., `Google`, `VMware, Inc.`, `Notion`, `Anytype`, `Ollama`).

### The Solution: `janitor.ps1 reg-clean`
1. **Pre-Purge Backup**: Exports target keys using `reg.exe export` into `%LOCALAPPDATA%\win-janitor\backups\reg_*.reg` (or `.local\backups` fallback).
2. **Safe Deletion**: Deletes orphaned vendor hives cleanly.
3. **OS-Bridge Resilience**: If a subkey is retained by active OS policies (e.g., Microsoft Edge's `BrowserCore` native messaging host under `Google\Chrome`), the engine logs it safely without erroring.

---

## 🐍 4. Developer Environment & Python Isolation (Rule 8)

### Best Practices:
1. **Avoid Global Pip Pollution**:
   - Heavy dependencies (e.g. `PySide6`, `torch`, `playwright`, `scikit-learn`) should live in project-specific virtual environments (`.venv`).
   - Use modern package managers like `uv` (`uv venv`, `uv pip install`) for 10–100x faster, isolated execution.
2. **Portable Relative Paths**:
   - Never hardcode `C:\Users\<user>` in project code or scripts.
   - Use `$env:USERPROFILE`, `%USERPROFILE%`, or relative paths (`./`, `../`).
3. **NPM Cache Hygiene**:
   - Audit `$env:LOCALAPPDATA\npm-cache` periodically with `janitor.ps1 dev-hygiene`.
