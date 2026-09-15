# 🛡️ Sakshi Shield Invariant & Security Contract

> **Scope**: Immutable protection protocol for all files, scheduled tasks, and resources belonging to `Sakshi`.  
> **Authority**: Governed by explicit executive sanctuary mandate.

---

## 🏛️ 1. The Sakshi Rule (Zero Mutation Policy)

Under NO circumstances shall any script, subagent, automated sweep, or manual clean-up tool touch, alter, pause, kill, modify, or delete any asset associated with `Sakshi`.

### Protected Entities:
1. **Scheduled Task**:
   - Task Name: `\Sakshi`
   - Target Binary: `powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "%USERPROFILE%\Void\Sakshi\Sakshi.ps1"`
   - State Mandate: Must remain **`Running`** or **`Ready`** at all times.
2. **Filesystem Boundaries**:
   - `%USERPROFILE%\Void\Sakshi\` (and all child scripts, banners, and logs).
   - Any credentials, designated protected data, registry keys, or environment variables referencing `Sakshi`.

---

## ⚡ 2. Automated Shield Verification in Scripts

Every script within `win-janitor` must execute `Assert-SakshiShield` before performing any deletion or termination:

```powershell
function Assert-SakshiShield {
    param ([string]$PathToCheck)
    if ($PathToCheck -match "Sakshi|Void\\Sakshi") {
        Write-Host "🛡️ [SHIELD TRIGGERED]: Target blocked by Sakshi Protection Protocol: $PathToCheck" -ForegroundColor Magenta
        return $false
    }
    return $true
}
```

If a clean-up scan identifies any file matching `*sakshi*`, it is automatically bypassed and logged with a green shield badge.
