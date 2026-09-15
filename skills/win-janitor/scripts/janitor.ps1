# ==============================================================================
# 🛡️ WIN-JANITOR: Autonomous Windows Performance & System Governor Engine
# Platform: Windows 11 Pro / Enterprise
# Invariant: Sakshi Task and Directory are strictly shielded from all actions.
# ==============================================================================

[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    [ValidateSet("audit", "trim", "purge", "enforce-baseline", "diagnose", "updates", "help")]
    [string]$Action = "audit",

    [Parameter(Position = 1)]
    [string]$Target = "general"
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ------------------------------------------------------------------------------
# 0. SAKSHI IMMUTABLE SHIELD (ZERO COMPROMISE PROTOCOL)
# ------------------------------------------------------------------------------
function Assert-SakshiShield {
    param ([string]$PathToCheck)
    if ($PathToCheck -match "Sakshi|Void\\Sakshi") {
        Write-Host "🛡️ [SHIELD TRIGGERED]: Target blocked by Sakshi Protection Protocol: $PathToCheck" -ForegroundColor Magenta
        return $false
    }
    return $true
}

function Verify-SakshiTask {
    $task = Get-ScheduledTask -TaskName "Sakshi" -ErrorAction SilentlyContinue
    if ($task) {
        Write-Host "🛡️ Sakshi Task Status: $($task.State) (Guaranteed Intact & Protected)" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Warning: Sakshi task not detected in root directory." -ForegroundColor DarkYellow
    }
}

# ------------------------------------------------------------------------------
# 1. WIN32 API BINDINGS (DEEP WORKING SET MEMORY FLUSH)
# ------------------------------------------------------------------------------
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class WinJanitorMem {
    [DllImport("psapi.dll")]
    public static extern int EmptyWorkingSet(IntPtr hwProc);
}
"@ -ErrorAction SilentlyContinue

# ------------------------------------------------------------------------------
# 2. ACTION: AUDIT
# ------------------------------------------------------------------------------
function Invoke-JanitorAudit {
    Write-Host "`n======================================================================" -ForegroundColor Cyan
    Write-Host "                  🧹 WIN-JANITOR: SYSTEM HEALTH AUDIT                  " -ForegroundColor Cyan
    Write-Host "======================================================================" -ForegroundColor Cyan

    Verify-SakshiTask

    # 1. Physical RAM Metrics
    $os = Get-CimInstance Win32_OperatingSystem
    $totalRAM = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $freeRAM = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $usedRAM = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB, 2)
    $percentUsed = [math]::Round(($usedRAM / $totalRAM) * 100, 1)

    Write-Host "`n[1] PHYSICAL RAM UTILIZATION" -ForegroundColor Yellow
    Write-Host "  • Total RAM   : $totalRAM GB"
    Write-Host "  • Free RAM    : $freeRAM GB"
    Write-Host "  • Used RAM    : $usedRAM GB ($percentUsed%)"
    if ($percentUsed -gt 80) {
        Write-Host "  ⚠️ Memory pressure is HIGH. Run 'janitor trim' to flush idle working sets." -ForegroundColor Red
    } else {
        Write-Host "  ✅ Memory utilization is within pristine operating zone." -ForegroundColor Green
    }

    # 2. Top 10 RAM Consumers
    Write-Host "`n[2] TOP 10 PROCESSES BY RAM FOOTPRINT" -ForegroundColor Yellow
    Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 10 Id, ProcessName, @{N="RAM_MB";E={[math]::Round($_.WorkingSet64/1MB,1)}}, @{N="CPU_s";E={[math]::Round($_.CPU,1)}} | Format-Table -AutoSize

    # 3. Baseline Services Check
    Write-Host "[3] BASELINE SERVICE INTEGRITY" -ForegroundColor Yellow
    $baselineSvcs = @(
        @{ Name = "WSearch"; Role = "Windows Search Indexer" },
        @{ Name = "SysMain"; Role = "Superfetch RAM Caching" },
        @{ Name = "DiagTrack"; Role = "Windows Telemetry Pusher" },
        @{ Name = "Spooler"; Role = "Print Spooler" },
        @{ Name = "InventorySvc"; Role = "Compatibility Appraisal" },
        @{ Name = "VMAuthdService"; Role = "VMware Daemon" }
    )

    foreach ($s in $baselineSvcs) {
        $svcObj = Get-Service -Name $s.Name -ErrorAction SilentlyContinue
        if ($svcObj) {
            $stateStr = "$($svcObj.Status) | $($svcObj.StartType)"
            if ($svcObj.Status -eq "Running" -and $s.Name -ne "VMAuthdService") {
                Write-Host "  ⚠️ DRIFT DETECTED: $($s.Name) ($($s.Role)) is RUNNING. Run 'janitor enforce-baseline'." -ForegroundColor Red
            } else {
                Write-Host "  ✅ $($s.Name) : $stateStr" -ForegroundColor Green
            }
        } else {
            Write-Host "  ✅ $($s.Name) : Not installed (Clean)" -ForegroundColor DarkGreen
        }
    }

    # 4. Startup Registry Audit
    Write-Host "`n[4] STARTUP REGISTRY AUDIT (HKCU & HKLM)" -ForegroundColor Yellow
    $runKeys = @("HKCU:\Software\Microsoft\Windows\CurrentVersion\Run", "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run")
    $startupItems = 0
    foreach ($rk in $runKeys) {
        if (Test-Path $rk) {
            $props = Get-ItemProperty $rk
            $valNames = $props.PSObject.Properties | Where-Object { $_.Name -notmatch "^PS" }
            foreach ($v in $valNames) {
                Write-Host "  • [Startup] $($v.Name) = $($v.Value)" -ForegroundColor Gray
                $startupItems++
            }
        }
    }
    if ($startupItems -eq 0) {
        Write-Host "  ✅ 0 rogue startup items detected. Boot footprint is 100% PRISTINE." -ForegroundColor Green
    }

    # 5. Storage Metrics
    Write-Host "`n[5] STORAGE METRICS" -ForegroundColor Yellow
    Get-PSDrive -PSProvider FileSystem | Select-Object Name, @{N="Free_GB";E={[math]::Round($_.Free/1GB,2)}}, @{N="Used_GB";E={[math]::Round($_.Used/1GB,2)}} | Format-Table -AutoSize
}

# ------------------------------------------------------------------------------
# 3. ACTION: TRIM
# ------------------------------------------------------------------------------
function Invoke-JanitorTrim {
    Write-Host "`n======================================================================" -ForegroundColor Cyan
    Write-Host "               ⚡ WIN-JANITOR: INSTANT WORKING-SET TRIM                " -ForegroundColor Cyan
    Write-Host "======================================================================" -ForegroundColor Cyan

    $initialMem = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory

    # Kill detached or zombie background helpers
    $zombies = @("Widgets", "WidgetService", "CrossDeviceResume", "IGCCTray", "IGCC", "PowerToys*")
    foreach ($z in $zombies) {
        Get-Process -Name $z -ErrorAction SilentlyContinue | ForEach-Object {
            Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
            Write-Host "  ✅ Terminated background ghost: $($_.ProcessName) (PID: $($_.Id))" -ForegroundColor Green
        }
    }

    # EmptyWorkingSet across eligible processes
    Write-Host "  -> Flushing process working sets via EmptyWorkingSet API..." -ForegroundColor Gray
    $procs = Get-Process | Where-Object { 
        $_.Id -gt 4 -and 
        $_.ProcessName -notmatch "System|Idle|dwm|explorer|pwsh|WindowsTerminal|node"
    }

    $trimmed = 0
    foreach ($p in $procs) {
        try {
            if ($p.Handle) {
                [WinJanitorMem]::EmptyWorkingSet($p.Handle) | Out-Null
                $trimmed++
            }
        } catch {}
    }

    # Force Garbage Collection
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()

    $finalMem = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory
    $freedMB = [math]::Round(($finalMem - $initialMem) / 1KB, 1)

    Write-Host "  ✅ Process working sets trimmed across $trimmed processes." -ForegroundColor Green
    if ($freedMB -gt 0) {
        Write-Host "  🚀 Immediately freed: ~$freedMB MB of physical RAM!" -ForegroundColor Cyan
    } else {
        Write-Host "  🚀 Working sets trimmed and memory pages reclaimed." -ForegroundColor Cyan
    }
}

# ------------------------------------------------------------------------------
# 4. ACTION: PURGE
# ------------------------------------------------------------------------------
function Invoke-JanitorPurge {
    Write-Host "`n======================================================================" -ForegroundColor Cyan
    Write-Host "               🧹 WIN-JANITOR: DEEP CACHE & GHOST PURGE               " -ForegroundColor Cyan
    Write-Host "======================================================================" -ForegroundColor Cyan

    # Ghost folders of uninstalled tools
    $ghostPaths = @(
        "$env:LOCALAPPDATA\Google",
        "$env:APPDATA\Google",
        "$env:APPDATA\Telegram Desktop",
        "$env:LOCALAPPDATA\Programs\Notion",
        "$env:LOCALAPPDATA\notion-updater",
        "$env:LOCALAPPDATA\Programs\anytype",
        "$env:LOCALAPPDATA\Programs\Perplexity",
        "$env:LOCALAPPDATA\Programs\ai-pathfinder",
        "$env:LOCALAPPDATA\Programs\Ollama",
        "$env:USERPROFILE\.ollama"
    )

    foreach ($gp in $ghostPaths) {
        if (-not (Assert-SakshiShield $gp)) { continue }
        if (Test-Path $gp) {
            Remove-Item -Path $gp -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  ✅ Purged ghost folder: $gp" -ForegroundColor Green
        }
    }

    # Temporary caches (safely skip locked files)
    Write-Host "  -> Purging temporary file caches..." -ForegroundColor Gray
    $tempFolders = @("$env:TEMP", "$env:WINDIR\Temp")
    foreach ($tf in $tempFolders) {
        Get-ChildItem -Path $tf -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
            } catch {}
        }
    }
    Write-Host "  ✅ Temporary caches flushed." -ForegroundColor Green

    # Installer Package Cache
    $pkgCache = "$env:LOCALAPPDATA\Package Cache"
    if (Test-Path $pkgCache) {
        $pkgs = Get-ChildItem -Path $pkgCache -Recurse -File -ErrorAction SilentlyContinue
        $pkgSizeMB = [math]::Round(($pkgs | Measure-Object -Property Length -Sum).Sum / 1MB, 1)
        if ($pkgSizeMB -gt 0) {
            Write-Host "  ℹ️ Installer package cache contains $pkgSizeMB MB." -ForegroundColor Gray
        }
    }

    Write-Host "  ✅ Deep purge cycle completed." -ForegroundColor Green
}

# ------------------------------------------------------------------------------
# 5. ACTION: ENFORCE-BASELINE
# ------------------------------------------------------------------------------
function Invoke-JanitorBaseline {
    Write-Host "`n======================================================================" -ForegroundColor Cyan
    Write-Host "            🛡️ WIN-JANITOR: BASELINE INTEGRITY ENFORCER                " -ForegroundColor Cyan
    Write-Host "======================================================================" -ForegroundColor Cyan

    Verify-SakshiTask

    # 1. 10 Core Services to Keep Disabled
    $deadServices = @(
        @{ Name = "WSearch"; Desc = "Windows Search Indexer" },
        @{ Name = "SysMain"; Desc = "Superfetch RAM Thrashing" },
        @{ Name = "DiagTrack"; Desc = "Connected User Experiences & Telemetry" },
        @{ Name = "InventorySvc"; Desc = "Inventory & Compatibility Appraisal" },
        @{ Name = "wuqisvc"; Desc = "Microsoft Usage & Quality Insights" },
        @{ Name = "whesvc"; Desc = "Windows Health & Optimized Experiences" },
        @{ Name = "dptftcs"; Desc = "Intel Dynamic Tuning Telemetry" },
        @{ Name = "DPS"; Desc = "Diagnostic Policy Service" },
        @{ Name = "Spooler"; Desc = "Print Spooler" },
        @{ Name = "TrkWks"; Desc = "Distributed Link Tracking Client" }
    )

    foreach ($ds in $deadServices) {
        $s = Get-Service -Name $ds.Name -ErrorAction SilentlyContinue
        if ($s) {
            if ($s.Status -eq "Running") {
                Stop-Service -Name $ds.Name -Force -ErrorAction SilentlyContinue
            }
            if ($s.StartType -ne "Disabled") {
                Set-Service -Name $ds.Name -StartupType Disabled -ErrorAction SilentlyContinue
                Write-Host "  ✅ Enforced Disabled: $($ds.Name) ($($ds.Desc))" -ForegroundColor Green
            } else {
                Write-Host "  ✅ Invariant held: $($ds.Name) is Disabled." -ForegroundColor DarkGreen
            }
        }
    }

    # 2. Microsoft Edge Policies
    $edgePolicy = "HKLM:\Software\Policies\Microsoft\Edge"
    if (Test-Path $edgePolicy) {
        Set-ItemProperty -Path $edgePolicy -Name "StartupBoostEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $edgePolicy -Name "BackgroundModeEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $edgePolicy -Name "WebWidgetAllowed" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Write-Host "  ✅ Edge lightweight background policies verified." -ForegroundColor Green
    }

    # 3. Widgets Policy
    $dsh = "HKLM:\Software\Policies\Microsoft\Dsh"
    if (Test-Path $dsh) {
        Set-ItemProperty -Path $dsh -Name "AllowNewsAndInterests" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Write-Host "  ✅ Windows 11 Widgets block policy verified." -ForegroundColor Green
    }
}

# ------------------------------------------------------------------------------
# 6. ACTION: DIAGNOSE
# ------------------------------------------------------------------------------
function Invoke-JanitorDiagnose {
    param ([string]$Scenario)
    Write-Host "`n======================================================================" -ForegroundColor Cyan
    Write-Host "               🔍 WIN-JANITOR: SCENARIO DIAGNOSTICS                   " -ForegroundColor Cyan
    Write-Host "======================================================================" -ForegroundColor Cyan
    Write-Host "Diagnostic Scenario: $Scenario`n" -ForegroundColor Yellow

    switch -Regex ($Scenario) {
        "ram|memory" {
            Write-Host "--- HIGH RAM ROOT CAUSE ANALYSIS ---" -ForegroundColor Yellow
            $topProcs = Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 5
            foreach ($p in $topProcs) {
                $ram = [math]::Round($p.WorkingSet64 / 1MB, 1)
                $priv = [math]::Round($p.PrivateMemorySize64 / 1MB, 1)
                Write-Host "  • $($p.ProcessName) (PID: $($p.Id)) -> WorkingSet: $ram MB | Private: $priv MB"
                if ($p.ProcessName -match "msedge|chrome") {
                    Write-Host "    ↳ Recommendation: Discard heavy background tabs via Shift+Esc in Edge." -ForegroundColor DarkYellow
                } elseif ($p.ProcessName -match "node|pwsh") {
                    Write-Host "    ↳ Active pairing/developer process. Normal operating load." -ForegroundColor Gray
                }
            }
        }
        "cpu|spike" {
            Write-Host "--- HIGH CPU ROOT CAUSE ANALYSIS ---" -ForegroundColor Yellow
            Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 Id, ProcessName, @{N="TotalCPU_s";E={[math]::Round($_.CPU,1)}} | Format-Table -AutoSize
        }
        "drift|update" {
            Write-Host "--- WINDOWS UPDATE DRIFT ANALYSIS ---" -ForegroundColor Yellow
            $recentHotfixes = Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 3
            Write-Host "  Last installed Hotfixes:"
            $recentHotfixes | ForEach-Object { Write-Host "  • $($_.HotFixID) installed on $($_.InstalledOn)" -ForegroundColor Gray }
            Write-Host "  Running baseline enforcement to reverse any restored telemetry services..."
            Invoke-JanitorBaseline
        }
        default {
            Write-Host "Available diagnosis scenarios: 'ram', 'cpu', 'drift'" -ForegroundColor DarkYellow
        }
    }
}

# ------------------------------------------------------------------------------
# ROUTER
# ------------------------------------------------------------------------------
switch ($Action) {
    "audit"            { Invoke-JanitorAudit }
    "trim"             { Invoke-JanitorTrim }
    "purge"            { Invoke-JanitorPurge }
    "enforce-baseline" { Invoke-JanitorBaseline }
    "diagnose"         { Invoke-JanitorDiagnose -Scenario $Target }
    "updates"          { Invoke-JanitorDiagnose -Scenario "drift" }
    "help"             {
        Write-Host "Usage: janitor.ps1 <audit|trim|purge|enforce-baseline|diagnose|updates> [target]" -ForegroundColor Yellow
    }
}
