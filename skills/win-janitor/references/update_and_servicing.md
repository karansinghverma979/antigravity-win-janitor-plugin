# 📦 Windows Updates, Servicing Stack & Component Store Guide

*Technical reference for inspecting Windows updates, maintaining the WinSxS component store, and preventing OS corruption.*

---

## 🏛️ 1. The Windows Component Store (`WinSxS`)

### What It Is:
The `C:\Windows\WinSxS` (Windows Side-by-Side) folder stores all operating system components, hard links, manifests, and historical versions of DLLs to allow rollbacks and system repairs.

### The Bloat Phenomenon:
After several monthly Cumulative Updates, older versions of components remain in the store as superseded packages, taking up 5GB to 15GB of disk space.

### Safe Component Store Optimization (Elevated):
1. **Analyze Component Store Health**:
   ```cmd
   Dism.exe /Online /Cleanup-Image /AnalyzeComponentStore
   ```
2. **Clean Superseded Components**:
   ```cmd
   Dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase
   ```
   - `/StartComponentCleanup`: Removes superseded components.
   - `/ResetBase`: Removes all superseded versions of components (prevents uninstalling past updates, but frees maximum space).

---

## 🔍 2. Auditing Recent Windows Updates

To verify what updates have been installed recently:

```powershell
Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 5 HotFixID, Description, InstalledOn, InstalledBy
```

### Checking for Update Drift:
If a recent update has been installed within the last 48 hours, always run:
```powershell
pwsh -NoProfile -File "$env:USERPROFILE\.gemini\antigravity-cli\skills\win-janitor\scripts\janitor.ps1" enforce-baseline
```
This ensures that Windows Update hasn't silently re-enabled `DiagTrack`, `WSearch`, `SysMain`, or Edge background mode.
