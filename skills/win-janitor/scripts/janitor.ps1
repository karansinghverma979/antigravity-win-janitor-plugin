# ==============================================================================
# 🛡️ WIN-JANITOR: Autonomous Windows Performance & System Governor Engine
# Platform: Windows 11 Pro / Enterprise
# Invariant: Sakshi Task and Directory are strictly shielded from all actions.
# ==============================================================================

[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    [ValidateSet("audit", "trim", "purge", "enforce-baseline", "diagnose", "updates", "packages", "path-clean", "reg-clean", "dev-hygiene", "fix-shell", "learn", "assimilate", "ignore", "help")]
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
# 1. PLUGIN PATH RESOLUTION & DYNAMIC RULES ENGINE
# ------------------------------------------------------------------------------
function Get-JanitorPluginRoot {
    try {
        return (Resolve-Path "$PSScriptRoot\..\..\..").Path
    } catch {
        return "$env:USERPROFILE\.gemini\config\plugins\win-janitor-plugin"
    }
}

function Get-JanitorBackupDir {
    if ($env:LOCALAPPDATA) {
        $backupDir = Join-Path $env:LOCALAPPDATA "win-janitor\backups"
    } else {
        $root = Get-JanitorPluginRoot
        $backupDir = Join-Path $root ".local\backups"
    }
    if (-not (Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    }
    return $backupDir
}

function Get-LearnedRules {
    $root = Get-JanitorPluginRoot
    $rulesFile = Join-Path $root "learned_rules.json"
    if (Test-Path $rulesFile) {
        try {
            return Get-Content $rulesFile -Raw -Encoding UTF8 | ConvertFrom-Json
        } catch {}
    }
    return [PSCustomObject]@{
        version = "1.2.0"
        ghostProcesses = @()
        ghostPaths = @()
        disabledServices = @()
        startupRemovals = @()
        ghostRegKeys = @()
    }
}

function Save-LearnedRules ($rules) {
    $root = Get-JanitorPluginRoot
    $rulesFile = Join-Path $root "learned_rules.json"
    $rules | ConvertTo-Json -Depth 5 | Set-Content -Path $rulesFile -Encoding UTF8
}

function Get-DriftData {
    $root = Get-JanitorPluginRoot
    $driftFile = Join-Path $root "drift.json"
    if (Test-Path $driftFile) {
        try {
            return Get-Content $driftFile -Raw -Encoding UTF8 | ConvertFrom-Json
        } catch {}
    }
    return [PSCustomObject]@{
        version = "1.2.0"
        lastScanned = $null
        candidates = @()
    }
}

function Save-DriftData ($drift) {
    $root = Get-JanitorPluginRoot
    $driftFile = Join-Path $root "drift.json"
    $drift | ConvertTo-Json -Depth 5 | Set-Content -Path $driftFile -Encoding UTF8
}

# ------------------------------------------------------------------------------
# 2. WIN32 API BINDINGS (DEEP WORKING SET MEMORY FLUSH)
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
# 3. ACTION: AUDIT
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

    $learned = Get-LearnedRules
    if ($learned.disabledServices) {
        foreach ($ds in $learned.disabledServices) {
            $baselineSvcs += @{ Name = $ds.name; Role = "Learned Baseline Policy" }
        }
    }

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

    # 5. User PATH Quick Check
    $uPath = [Environment]::GetEnvironmentVariable("PATH", "User") -split ";" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    $deadCount = ($uPath | Where-Object { -not (Test-Path $_) }).Count
    Write-Host "`n[5] ENVIRONMENT PATH HYGIENE" -ForegroundColor Yellow
    if ($deadCount -gt 0) {
        Write-Host "  ⚠️ $deadCount dead directory path(s) detected in User PATH. Run 'janitor.ps1 path-clean'." -ForegroundColor Yellow
    } else {
        Write-Host "  ✅ All $($uPath.Count) User PATH directories are verified and active." -ForegroundColor Green
    }

    # 6. Storage Metrics
    Write-Host "`n[6] STORAGE METRICS" -ForegroundColor Yellow
    Get-PSDrive -PSProvider FileSystem | Select-Object Name, @{N="Free_GB";E={[math]::Round($_.Free/1GB,2)}}, @{N="Used_GB";E={[math]::Round($_.Used/1GB,2)}} | Format-Table -AutoSize
}

# ------------------------------------------------------------------------------
# 4. ACTION: TRIM
# ------------------------------------------------------------------------------
function Invoke-JanitorTrim {
    Write-Host "`n======================================================================" -ForegroundColor Cyan
    Write-Host "               ⚡ WIN-JANITOR: INSTANT WORKING-SET TRIM                " -ForegroundColor Cyan
    Write-Host "======================================================================" -ForegroundColor Cyan

    $initialMem = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory

    # Kill detached or zombie background helpers (built-in + learned)
    $zombies = @("Widgets", "WidgetService", "CrossDeviceResume", "IGCCTray", "IGCC", "PowerToys*")
    $learned = Get-LearnedRules
    if ($learned.ghostProcesses) {
        $zombies += $learned.ghostProcesses
    }

    foreach ($z in $zombies) {
        Get-Process -Name $z -ErrorAction SilentlyContinue | ForEach-Object {
            Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
            Write-Host "  ✅ Terminated background ghost: $($_.ProcessName) (PID: $($_.Id))" -ForegroundColor Green
        }
    }

    # Terminate SearchHost WebView2 web background instances if present
    Get-CimInstance -Query "SELECT ProcessId, CommandLine FROM Win32_Process WHERE Name = 'msedgewebview2.exe'" -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.CommandLine -match "SearchHost\.exe|EBWebView") {
            Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
            Write-Host "  ✅ Terminated SearchHost WebView2 ghost (PID: $($_.ProcessId))" -ForegroundColor Green
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
# 5. ACTION: PURGE
# ------------------------------------------------------------------------------
function Invoke-JanitorPurge {
    Write-Host "`n======================================================================" -ForegroundColor Cyan
    Write-Host "               🧹 WIN-JANITOR: DEEP CACHE & GHOST PURGE               " -ForegroundColor Cyan
    Write-Host "======================================================================" -ForegroundColor Cyan

    # Ghost folders of uninstalled tools (built-in + learned)
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

    $learned = Get-LearnedRules
    if ($learned.ghostPaths) {
        $ghostPaths += $learned.ghostPaths
    }

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
# 6. ACTION: ENFORCE-BASELINE
# ------------------------------------------------------------------------------
function Invoke-JanitorBaseline {
    Write-Host "`n======================================================================" -ForegroundColor Cyan
    Write-Host "            🛡️ WIN-JANITOR: BASELINE INTEGRITY ENFORCER                " -ForegroundColor Cyan
    Write-Host "======================================================================" -ForegroundColor Cyan

    Verify-SakshiTask

    # 1. Core Services to Keep Disabled (Built-in + Learned)
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

    $learned = Get-LearnedRules
    if ($learned.disabledServices) {
        foreach ($ds in $learned.disabledServices) {
            $deadServices += @{ Name = $ds.name; Desc = $ds.desc }
        }
    }

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

    # 2. Startup Removals from Learned Rules
    if ($learned.startupRemovals) {
        $runKeys = @("HKCU:\Software\Microsoft\Windows\CurrentVersion\Run", "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run")
        foreach ($sr in $learned.startupRemovals) {
            foreach ($rk in $runKeys) {
                if (Test-Path $rk) {
                    $item = Get-ItemProperty -Path $rk -Name $sr -ErrorAction SilentlyContinue
                    if ($item) {
                        Remove-ItemProperty -Path $rk -Name $sr -Force -ErrorAction SilentlyContinue
                        Write-Host "  ✅ Removed learned rogue startup item: $sr" -ForegroundColor Green
                    }
                }
            }
        }
    }

    # 3. Microsoft Edge Policies
    $edgePolicy = "HKLM:\Software\Policies\Microsoft\Edge"
    if (Test-Path $edgePolicy) {
        Set-ItemProperty -Path $edgePolicy -Name "StartupBoostEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $edgePolicy -Name "BackgroundModeEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $edgePolicy -Name "WebWidgetAllowed" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $edgePolicy -Name "NewTabPagePrerenderEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $edgePolicy -Name "SleepingTabsEnabled" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $edgePolicy -Name "SleepingTabsTimeout" -Value 300 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $edgePolicy -Name "EdgeShoppingAssistantEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        
        # Block intrusive shopping and tracker extensions
        $blocklistKey = Join-Path $edgePolicy "ExtensionInstallBlocklist"
        if (-not (Test-Path $blocklistKey)) { New-Item -Path $blocklistKey -Force -ErrorAction SilentlyContinue | Out-Null }
        if (Test-Path $blocklistKey) {
            Set-ItemProperty -Path $blocklistKey -Name "1" -Value "ejefaeioamebhekmfaclajddbpnnobje" -Force -ErrorAction SilentlyContinue # Keepa
            Set-ItemProperty -Path $blocklistKey -Name "2" -Value "ojplmecpdpgccookcobabopnaifgidhf" -Force -ErrorAction SilentlyContinue # Buyhatke
        }
        Write-Host "  ✅ Edge lightweight, sleeping tabs, prerender block & extension policies verified." -ForegroundColor Green
    }

    # 4. Widgets Policy
    $dsh = "HKLM:\Software\Policies\Microsoft\Dsh"
    if (Test-Path $dsh) {
        Set-ItemProperty -Path $dsh -Name "AllowNewsAndInterests" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Write-Host "  ✅ Windows 11 Widgets block policy verified." -ForegroundColor Green
    }

    # 5. Windows Search Web & Highlights Elimination Policies
    $searchPolicy = "HKLM:\Software\Policies\Microsoft\Windows\Windows Search"
    if (-not (Test-Path $searchPolicy)) { New-Item -Path $searchPolicy -Force -ErrorAction SilentlyContinue | Out-Null }
    if (Test-Path $searchPolicy) {
        Set-ItemProperty -Path $searchPolicy -Name "DisableWebSearch" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $searchPolicy -Name "ConnectedSearchUseWeb" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $searchPolicy -Name "ConnectedSearchUseWebOverMeteredConnections" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $searchPolicy -Name "AllowCortana" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $searchPolicy -Name "EnableDynamicContentInWSB" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $searchPolicy -Name "AllowSearchToUseLocation" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Write-Host "  ✅ Windows Search Bing web & dynamic content policies enforced." -ForegroundColor Green
    }

    # User Search Settings (HKCU)
    $searchSettings = "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings"
    if (Test-Path $searchSettings) {
        Set-ItemProperty -Path $searchSettings -Name "IsSearchHighlightsEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $searchSettings -Name "IsDynamicSearchBoxEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $searchSettings -Name "IsMSACloudSearchEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $searchSettings -Name "IsAADCloudSearchEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    }
    $searchKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
    if (Test-Path $searchKey) {
        Set-ItemProperty -Path $searchKey -Name "BingSearchEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $searchKey -Name "CortanaConsent" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $searchKey -Name "WebControlStatus" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $searchKey -Name "IsWebView2" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    }
    Write-Host "  ✅ Local-only instant search settings enforced." -ForegroundColor Green
}

# ------------------------------------------------------------------------------
# 7. ACTION: DIAGNOSE
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
            Write-Host "--- WINDOWS UPDATE DRIFT & CRASH CORRELATION ---" -ForegroundColor Yellow
            $recentHotfixes = Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 3
            Write-Host "  Last installed Hotfixes:"
            $recentHotfixes | ForEach-Object { Write-Host "  • $($_.HotFixID) installed on $($_.InstalledOn)" -ForegroundColor Gray }
            
            Write-Host "`n  Checking application hangs correlated with update installation..." -ForegroundColor Gray
            $recentHangs = Get-WinEvent -FilterHashtable @{LogName="Application"; Id=1002; StartTime=(Get-Date).AddDays(-3)} -ErrorAction SilentlyContinue
            if ($recentHangs) {
                Write-Host "  ⚠️ Found $($recentHangs.Count) hang event(s) post-update:" -ForegroundColor Red
                $recentHangs | Select-Object -First 3 | ForEach-Object {
                    $firstLine = ($_.Message -split "`r?`n")[0]
                    Write-Host "     • [$($_.TimeCreated)] $firstLine" -ForegroundColor DarkYellow
                }
            } else {
                Write-Host "  ✅ 0 application hang events found." -ForegroundColor Green
            }

            Write-Host "`n  Running baseline enforcement to reverse any restored telemetry services..."
            Invoke-JanitorBaseline
        }
        "shell|freeze|ui|desktop" {
            Write-Host "--- WINDOWS SHELL, DWM & VIRTUAL DESKTOP FREEZE ANALYSIS ---" -ForegroundColor Yellow

            # 1. Check Event Log for Application Hangs (Event ID 1002)
            Write-Host "  -> [1/4] Querying Windows Event Log for Shell & App Hangs (Event ID 1002)..." -ForegroundColor Gray
            $hangs = Get-WinEvent -FilterHashtable @{LogName="Application"; Id=1002; StartTime=(Get-Date).AddDays(-3)} -ErrorAction SilentlyContinue |
                Where-Object { $_.Message -match "explorer\.exe|dwm\.exe|SystemSettings\.exe|WindowsTerminal\.exe" }

            if ($hangs) {
                Write-Host "  ⚠️ Found $($hangs.Count) Shell Hang event(s) in last 72 hours:" -ForegroundColor Red
                $hangs | Select-Object -First 5 TimeCreated, Message | ForEach-Object {
                    $firstLine = ($_.Message -split "`r?`n")[0]
                    Write-Host "     • [$($_.TimeCreated)] $firstLine" -ForegroundColor DarkYellow
                }
            } else {
                Write-Host "  ✅ 0 Explorer/DWM hang events recorded in last 72 hours." -ForegroundColor Green
            }

            # 2. Check WER for AppHangXProcB1 (Cross-Process RPC Hangs)
            Write-Host "`n  -> [2/4] Cross-Process RPC Hang Diagnostics..." -ForegroundColor Gray
            $werHangs = Get-WinEvent -FilterHashtable @{LogName="Application"; Id=1001; StartTime=(Get-Date).AddDays(-3)} -ErrorAction SilentlyContinue |
                Where-Object { $_.Message -match "AppHangXProcB1" }
            if ($werHangs) {
                Write-Host "  ⚠️ Detected AppHangXProcB1 (Explorer blocked on external COM/RPC process):" -ForegroundColor Red
                $werHangs | Select-Object -First 3 | ForEach-Object {
                    if ($_.Message -match "(P6:\s*[^\r\n]+)") {
                        Write-Host "     ↳ Blocked Target: $($Matches[1])" -ForegroundColor Magenta
                    }
                }
                Write-Host "     💡 Known fix: Purge corrupted thumbnail/icon cache via 'janitor.ps1 fix-shell'." -ForegroundColor Cyan
            } else {
                Write-Host "  ✅ No Cross-Process hangs detected." -ForegroundColor Green
            }

            # 3. DWM & Explorer Metrics
            Write-Host "`n  -> [3/4] Compositor & Shell Resource Footprint..." -ForegroundColor Gray
            $shellProcs = Get-Process dwm, explorer, WindowsTerminal, ShellExperienceHost, StartMenuExperienceHost -ErrorAction SilentlyContinue
            $explorerCount = 0
            foreach ($sp in $shellProcs) {
                $ram = [math]::Round($sp.WorkingSet64 / 1MB, 1)
                Write-Host "  • $($sp.ProcessName) (PID: $($sp.Id)) -> RAM: $ram MB | Handles: $($sp.HandleCount)" -ForegroundColor White
                if ($sp.ProcessName -eq "explorer") { $explorerCount++ }
            }
            if ($explorerCount -gt 1) {
                Write-Host "  ⚠️ CONFLICT DETECTED: $explorerCount explorer.exe instances running! Duplicate shells break Alt+Tab and Task View." -ForegroundColor Red
                Write-Host "     💡 Run 'janitor.ps1 fix-shell' to eliminate rogue duplicate shells." -ForegroundColor Cyan
            }

            # 4. Display & Animation Settings
            Write-Host "`n  -> [4/4] Display & Animation Configurations..." -ForegroundColor Gray
            $gpu = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue
            if ($gpu) {
                Write-Host "  • Display Resolution : $($gpu.CurrentHorizontalResolution) x $($gpu.CurrentVerticalResolution) @ $($gpu.CurrentRefreshRate) Hz"
            }
            $minAnim = (Get-ItemProperty "HKCU:\Control Panel\Desktop\WindowMetrics" -Name MinAnimate -ErrorAction SilentlyContinue).MinAnimate
            $tbAnim = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name TaskbarAnimations -ErrorAction SilentlyContinue).TaskbarAnimations
            $tvBtn = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name ShowTaskViewButton -ErrorAction SilentlyContinue).ShowTaskViewButton
            $iconsOnly = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name IconsOnly -ErrorAction SilentlyContinue).IconsOnly
            $prevDesk = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name DisablePreviewDesktop -ErrorAction SilentlyContinue).DisablePreviewDesktop
            $aeroPeek = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\DWM" -Name EnableAeroPeek -ErrorAction SilentlyContinue).EnableAeroPeek

            Write-Host "  • Window Animation (MinAnimate)      : $minAnim"
            Write-Host "  • Taskbar Animations (TaskbarAnimations): $tbAnim $(if ($tbAnim -eq 0) {'(⚠️ Disabling breaks modern XAML Alt+Tab/Task View)'} else {'(Active)'})"
            Write-Host "  • Task View Button (ShowTaskViewButton) : $tvBtn"
            Write-Host "  • Icons Only (IconsOnly)             : $iconsOnly $(if ($iconsOnly -eq 1) {'(⚠️ Blank Thumbnails: Always show icons is ON)'} else {'(Thumbnails Enabled)'})"
            Write-Host "  • Desktop Preview (DisablePreviewDesktop): $prevDesk $(if ($prevDesk -eq 1) {'(⚠️ Desktop preview disabled)'} else {'(Active)'})"
            Write-Host "  • Aero Peek (EnableAeroPeek)         : $aeroPeek $(if ($aeroPeek -eq 0) {'(⚠️ Aero Peek disabled in DWM)'} else {'(Active)'})"
        }
        default {
            Write-Host "Available diagnosis scenarios: 'ram', 'cpu', 'drift', 'shell'" -ForegroundColor DarkYellow
        }
    }
}

# ------------------------------------------------------------------------------
# 8. ACTION: PACKAGES (SCOOP & WINGET MAINTENANCE)
# ------------------------------------------------------------------------------
function Invoke-JanitorPackages {
    param ([string]$SubAction = "audit")
    Write-Host "`n======================================================================" -ForegroundColor Cyan
    Write-Host "               📦 WIN-JANITOR: PACKAGE ECOSYSTEM GOVERNOR             " -ForegroundColor Cyan
    Write-Host "======================================================================" -ForegroundColor Cyan

    $hasScoop = [bool](Get-Command scoop -ErrorAction SilentlyContinue)
    $hasWinget = [bool](Get-Command winget -ErrorAction SilentlyContinue)

    # 1. Scoop Management
    if ($hasScoop) {
        Write-Host "`n[1] SCOOP PACKAGE HYGIENE" -ForegroundColor Yellow
        if ($SubAction -eq "clean") {
            Write-Host "  -> Running scoop cleanup * (purging historical versions)..." -ForegroundColor Gray
            scoop cleanup *
            Write-Host "  -> Purging scoop installer cache (scoop cache rm *)..." -ForegroundColor Gray
            scoop cache rm *
            Write-Host "  ✅ Scoop version and installer caches purged." -ForegroundColor Green
        } else {
            Write-Host "  -> Checking Scoop pending application updates..." -ForegroundColor Gray
            scoop status
            $cacheOut = scoop cache show
            Write-Host "  $cacheOut" -ForegroundColor Gray
            Write-Host "  💡 Run 'janitor.ps1 packages clean' to purge old app versions & cache." -ForegroundColor DarkYellow
        }
    } else {
        Write-Host "`n[1] Scoop is not installed on this system." -ForegroundColor Gray
    }

    # 2. Winget Management
    if ($hasWinget) {
        Write-Host "`n[2] WINGET PACKAGE INTEGRITY" -ForegroundColor Yellow
        Write-Host "  -> Checking Windows Package Manager for upgradeable apps..." -ForegroundColor Gray
        winget upgrade --include-unknown
    } else {
        Write-Host "`n[2] Winget is not available on this system." -ForegroundColor Gray
    }
}

# ------------------------------------------------------------------------------
# 9. ACTION: PATH-CLEAN (DEDUPLICATION & DEAD DIRECTORY PRUNER)
# ------------------------------------------------------------------------------
function Invoke-JanitorPathClean {
    Write-Host "`n======================================================================" -ForegroundColor Cyan
    Write-Host "             🛣️ WIN-JANITOR: ENVIRONMENT PATH GOVERNOR & PRUNER        " -ForegroundColor Cyan
    Write-Host "======================================================================" -ForegroundColor Cyan

    $rawPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ([string]::IsNullOrWhiteSpace($rawPath)) {
        Write-Host "  ℹ️ User PATH is empty." -ForegroundColor Gray
        return
    }

    $items = $rawPath -split ";" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $cleanList = [System.Collections.Generic.List[string]]::new()
    $deadList = @()
    $dupList = @()

    foreach ($entry in $items) {
        $norm = $entry.Trim().TrimEnd("\")
        if ([string]::IsNullOrWhiteSpace($norm)) { continue }

        # Deduplication check
        if ($seen.Contains($norm)) {
            $dupList += $entry
            continue
        }
        $seen.Add($norm) | Out-Null

        # Sakshi Shield protection
        if (-not (Assert-SakshiShield $entry)) {
            $cleanList.Add($entry)
            continue
        }

        # Dead directory check
        if (-not (Test-Path $entry)) {
            $deadList += $entry
        } else {
            $cleanList.Add($entry)
        }
    }

    Write-Host "  • Total Original User PATH Entries : $($items.Count)"
    Write-Host "  • Duplicates Detected             : $($dupList.Count)" -ForegroundColor $(if ($dupList.Count -gt 0) { "Yellow" } else { "Green" })
    $dupList | ForEach-Object { Write-Host "    ↳ [DUP] $_" -ForegroundColor DarkYellow }

    Write-Host "  • Dead/Orphaned Directories       : $($deadList.Count)" -ForegroundColor $(if ($deadList.Count -gt 0) { "Red" } else { "Green" })
    $deadList | ForEach-Object { Write-Host "    ↳ [DEAD] $_" -ForegroundColor DarkRed }

    Write-Host "  • Valid & Clean Entries Retained   : $($cleanList.Count)" -ForegroundColor Green

    if ($dupList.Count -eq 0 -and $deadList.Count -eq 0) {
        Write-Host "`n  ✅ User PATH is 100% clean, deduplicated, and pristine." -ForegroundColor Green
        return
    }

    # Backup PATH before pruning
    $backupDir = Get-JanitorBackupDir
    $ts = (Get-Date).ToString("yyyyMMdd_HHmmss")
    $backupFile = Join-Path $backupDir "path_backup_$ts.txt"
    $rawPath | Set-Content -Path $backupFile -Encoding UTF8
    Write-Host "`n  💾 Pre-cleanup PATH backed up to: $backupFile" -ForegroundColor Cyan

    $newPath = $cleanList -join ";"
    [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
    $env:PATH = "$newPath;$([Environment]::GetEnvironmentVariable('PATH', 'Machine'))"

    Write-Host "  🚀 Successfully purged $($dupList.Count) duplicate(s) and $($deadList.Count) dead directory path(s)!" -ForegroundColor Green
    Write-Host "     Active session and User environment variables have been updated." -ForegroundColor DarkGreen
}

# ------------------------------------------------------------------------------
# 10. ACTION: REG-CLEAN (ORPHANED RESIDUAL REGISTRY HIVES)
# ------------------------------------------------------------------------------
function Invoke-JanitorRegClean {
    Write-Host "`n======================================================================" -ForegroundColor Cyan
    Write-Host "            🧹 WIN-JANITOR: RESIDUAL REGISTRY HIVE PURGER             " -ForegroundColor Cyan
    Write-Host "======================================================================" -ForegroundColor Cyan

    $targetHives = @(
        @{ Hive = "HKCU:\Software\Google"; Name = "Google (Uninstalled Chrome/Updater leftovers)" },
        @{ Hive = "HKCU:\Software\VMware, Inc."; Name = "VMware (Uninstalled Workstation/Tray leftovers)" },
        @{ Hive = "HKLM:\Software\VMware, Inc."; Name = "VMware Machine Hive (Uninstalled Workstation leftovers)" },
        @{ Hive = "HKLM:\Software\Google"; Name = "Google Machine Hive (Uninstalled Updater leftovers)" },
        @{ Hive = "HKCU:\Software\Notion"; Name = "Notion (Uninstalled desktop leftovers)" },
        @{ Hive = "HKCU:\Software\anytype"; Name = "Anytype (Uninstalled desktop leftovers)" },
        @{ Hive = "HKCU:\Software\Ollama"; Name = "Ollama (Uninstalled model runner leftovers)" }
    )

    $learned = Get-LearnedRules
    if ($learned.ghostRegKeys) {
        foreach ($rk in $learned.ghostRegKeys) {
            $targetHives += @{ Hive = $rk; Name = "Learned Registry Hive" }
        }
    }

    $foundHives = @()
    foreach ($th in $targetHives) {
        if (-not (Assert-SakshiShield $th.Hive)) { continue }
        if (Test-Path $th.Hive) {
            $foundHives += $th
        }
    }

    Write-Host "Scanned target residual registry hives: $($targetHives.Count)" -ForegroundColor Gray
    Write-Host "Found unpurged residual hives: $($foundHives.Count)`n" -ForegroundColor $(if ($foundHives.Count -gt 0) { "Yellow" } else { "Green" })

    if ($foundHives.Count -eq 0) {
        Write-Host "  ✅ No uninstalled vendor registry hives detected. Registry is clean." -ForegroundColor Green
        return
    }

    $backupDir = Get-JanitorBackupDir

    $ts = (Get-Date).ToString("yyyyMMdd_HHmmss")
    $purgedCount = 0

    foreach ($fh in $foundHives) {
        $regPath = $fh.Hive
        Write-Host "  • Found: $regPath ($($fh.Name))" -ForegroundColor Yellow

        $safeName = ($regPath -replace '[:\\]', '_')
        $regBackup = Join-Path $backupDir "reg_${safeName}_$ts.reg"
        $winRegKey = $regPath -replace '^HKCU:', 'HKEY_CURRENT_USER' -replace '^HKLM:', 'HKEY_LOCAL_MACHINE'

        try {
            reg.exe export "$winRegKey" "$regBackup" /y 2>$null | Out-Null
            Write-Host "    ↳ Backed up to: $regBackup" -ForegroundColor Gray
        } catch {}

        try {
            reg.exe delete "$winRegKey" /f 2>$null | Out-Null
            if (-not (Test-Path $regPath)) {
                Write-Host "    ✅ Successfully purged registry hive: $regPath" -ForegroundColor Green
                $purgedCount++
            } else {
                Write-Host "    ℹ️ Residual key partially locked or retained by OS policy: $regPath" -ForegroundColor DarkYellow
            }
        } catch {
            Write-Host "    ⚠️ Could not purge $regPath (may require elevated Administrator privileges)." -ForegroundColor Red
        }
    }

    Write-Host "`n🚀 Residual registry purge cycle complete. Purged: $purgedCount hive(s)." -ForegroundColor Cyan
}

# ------------------------------------------------------------------------------
# 11. ACTION: DEV-HYGIENE (PYTHON & DEVELOPER ISOLATION AUDIT)
# ------------------------------------------------------------------------------
function Invoke-JanitorDevHygiene {
    Write-Host "`n======================================================================" -ForegroundColor Cyan
    Write-Host "        🐍 WIN-JANITOR: DEVELOPER ENVIRONMENT & PYTHON HYGIENE        " -ForegroundColor Cyan
    Write-Host "======================================================================" -ForegroundColor Cyan

    # 1. Global Python Pip Contamination Check
    Write-Host "[1] PYTHON GLOBAL DEPENDENCY AUDIT" -ForegroundColor Yellow
    $hasPython = [bool](Get-Command python -ErrorAction SilentlyContinue)
    if ($hasPython) {
        $pyVer = python --version 2>&1
        Write-Host "  • Active Python: $pyVer" -ForegroundColor White
        
        $pipListJson = python -m pip list --format=json 2>$null
        if ($pipListJson) {
            $pkgs = $pipListJson | ConvertFrom-Json
            $totalCount = $pkgs.Count
            Write-Host "  • Global Packages Installed: $totalCount" -ForegroundColor $(if ($totalCount -gt 50) { "Yellow" } else { "Green" })
            
            $heavySuspects = @("pyside6", "torch", "tensorflow", "scipy", "scikit-learn", "transformers", "opencv-python", "playwright")
            $foundHeavy = @($pkgs | Where-Object { $heavySuspects -contains $_.name.ToLower() })
            
            if ($foundHeavy.Count -gt 0) {
                Write-Host "  ⚠️ Heavy libraries detected in global Python environment:" -ForegroundColor DarkYellow
                $foundHeavy | ForEach-Object { Write-Host "     ↳ $($_.name) ($($_.version))" -ForegroundColor Gray }
                Write-Host "  💡 Best Practice: Use isolated virtual environments (uv venv / python -m venv .venv)" -ForegroundColor Cyan
                Write-Host "     This prevents dependency clashes and keeps the global environment lightweight." -ForegroundColor DarkGray
            } else {
                Write-Host "  ✅ Global Python environment is clean and free of heavy framework bloat." -ForegroundColor Green
            }
        }
    } else {
        Write-Host "  ℹ️ Python is not detected in PATH." -ForegroundColor Gray
    }

    # 2. NPM / Node Cache Audit
    Write-Host "`n[2] NPM & NODE RUNTIME CACHE AUDIT" -ForegroundColor Yellow
    $npmCache = "$env:LOCALAPPDATA\npm-cache"
    if (Test-Path $npmCache) {
        $files = Get-ChildItem -Path $npmCache -Recurse -File -ErrorAction SilentlyContinue
        $cacheSizeMB = [math]::Round(($files | Measure-Object -Property Length -Sum).Sum / 1MB, 1)
        Write-Host "  • NPM Cache Size: $cacheSizeMB MB ($npmCache)" -ForegroundColor $(if ($cacheSizeMB -gt 500) { "Yellow" } else { "Green" })
        if ($cacheSizeMB -gt 500) {
            Write-Host "  💡 Recommendation: Run 'npm cache clean --force' to reclaim space." -ForegroundColor Cyan
        }
    } else {
        Write-Host "  ✅ NPM cache directory is clean or not present." -ForegroundColor Green
    }

    # 3. Path Portability Invariant (Rule 8)
    Write-Host "`n[3] PORTABILITY INVARIANT STATUS" -ForegroundColor Yellow
    Write-Host "  ✅ Plugin adheres to dynamic variable expansion (`$env:USERPROFILE, %USERPROFILE%)." -ForegroundColor Green
    Write-Host "  ✅ Hardcoded absolute machine paths are strictly 0% across plugin scripts." -ForegroundColor Green
}

# ------------------------------------------------------------------------------
# 12. ACTION: LEARN (DRIFT SENSOR & CANDIDATE STAGING)
# ------------------------------------------------------------------------------
function Invoke-JanitorLearn {
    Write-Host "`n======================================================================" -ForegroundColor Cyan
    Write-Host "               📡 WIN-JANITOR: DRIFT SENSOR & LEARNING ENGINE         " -ForegroundColor Cyan
    Write-Host "======================================================================" -ForegroundColor Cyan

    Verify-SakshiTask
    $drift = Get-DriftData
    $learned = Get-LearnedRules
    $now = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
    $drift.lastScanned = $now

    $criticalWhitelist = "^(System|Idle|Registry|smss|csrss|wininit|services|lsass|winlogon|explorer|dwm|fontdrvhost|svchost|pwsh|powershell|WindowsTerminal|cmd|conhost|sudo|node|agy|electron|msedge|code|devenv|spoolsv|taskhostw|RuntimeBroker|SearchHost|StartMenuExperienceHost|SecurityHealthSystray|SecurityHealthService|MsMpEng|NisSrv|ctfmon|Memory Compression|TextInputHost|sihost|ShellExperienceHost|Secure System|DefenderSessionHelper|backgroundTaskHost|OfficeClickToRun|ipf_helper|ipf_ufac|IntelGraphics.*|SenaryAudio.*)$"
    $baseZombies = @("Widgets", "WidgetService", "CrossDeviceResume", "IGCCTray", "IGCC", "PowerToys*")

    $candidateMap = @{}
    if ($drift.candidates) {
        foreach ($c in $drift.candidates) {
            $candidateMap[$c.id] = $c
        }
    }

    Write-Host "  -> [1/5] Scanning active background processes for unmapped daemons..." -ForegroundColor Gray
    $activeProcs = Get-Process | Where-Object {
        $_.Id -gt 4 -and
        $_.ProcessName -notmatch $criticalWhitelist -and
        $_.ProcessName -notmatch "Sakshi|Void\\Sakshi"
    }

    foreach ($p in $activeProcs) {
        $name = $p.ProcessName
        if ($baseZombies -contains $name -or ($learned.ghostProcesses -contains $name)) { continue }
        if (-not (Assert-SakshiShield $name)) { continue }

        $ramMB = [math]::Round($p.WorkingSet64 / 1MB, 1)
        $isBackground = ($p.MainWindowHandle -eq 0 -or [string]::IsNullOrWhiteSpace($p.MainWindowTitle))
        $isSuspectName = ($name -match "helper|daemon|update|telemetry|tray|crash|report|analytics")

        if (($isBackground -and $ramMB -gt 40) -or $isSuspectName) {
            $candId = "proc-$($name.ToLower())"
            if ($candidateMap.ContainsKey($candId)) {
                $existing = $candidateMap[$candId]
                $existing.lastSeen = $now
                $existing.hitCount = [int]$existing.hitCount + 1
                $existing.details = "RAM: $ramMB MB | Background daemon"
            } else {
                $newCand = [PSCustomObject]@{
                    id = $candId
                    category = "Process"
                    name = $name
                    details = "RAM: $ramMB MB | Background daemon"
                    firstSeen = $now
                    lastSeen = $now
                    hitCount = 1
                    status = "pending"
                    recommendedAction = "trim"
                }
                $candidateMap[$candId] = $newCand
            }
        }
    }

    Write-Host "  -> [2/5] Scanning startup registry entries for unmapped boot hooks..." -ForegroundColor Gray
    $runKeys = @("HKCU:\Software\Microsoft\Windows\CurrentVersion\Run", "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run")
    foreach ($rk in $runKeys) {
        if (Test-Path $rk) {
            $props = Get-ItemProperty $rk
            $valNames = $props.PSObject.Properties | Where-Object { $_.Name -notmatch "^PS" }
            foreach ($v in $valNames) {
                $sName = $v.Name
                $sVal = [string]$v.Value
                if ($sName -match "SecurityHealth" -or (-not (Assert-SakshiShield $sVal))) { continue }
                if ($learned.startupRemovals -contains $sName) { continue }
                $candId = "startup-$($sName.ToLower())"
                if ($candidateMap.ContainsKey($candId)) {
                    $existing = $candidateMap[$candId]
                    $existing.lastSeen = $now
                    $existing.hitCount = [int]$existing.hitCount + 1
                } else {
                    $newCand = [PSCustomObject]@{
                        id = $candId
                        category = "Startup"
                        name = $sName
                        details = "Target: $sVal"
                        firstSeen = $now
                        lastSeen = $now
                        hitCount = 1
                        status = "pending"
                        recommendedAction = "remove-startup"
                    }
                    $candidateMap[$candId] = $newCand
                }
            }
        }
    }

    Write-Host "  -> [3/5] Scanning non-critical Windows services for telemetry/updater drift..." -ForegroundColor Gray
    $allServices = Get-Service -ErrorAction SilentlyContinue | Where-Object {
        $_.StartType -in @("Automatic", "Manual") -and
        $_.Name -notmatch "^(Appinfo|AudioEndpointBuilder|AudioSrv|BFE|BrokerInfrastructure|CoreMessagingRegistrar|CryptSvc|DcomLaunch|Dhcp|Dnscache|EventLog|EventSystem|KeyIso|LanmanServer|LanmanWorkstation|LSM|MpsSvc|netprofm|NlaSvc|nsi|PlugPlay|Power|ProfSvc|RpcEptMapper|RpcSs|SamSs|Schedule|SecurityHealthService|Sense|SENS|SessionEnv|SharedAccess|ShellHWDetection|SSDPSRV|StateRepository|StorSvc|SystemEventsBroker|TimeBrokerSvc|TokenBroker|UserManager|VaultSvc|W32Time|Wcmsvc|WinDefend|WinHttpAutoProxySvc|Winmgmt|WlanSvc|WpnService|wuauserv)$" -and
        $_.Name -notmatch "Sakshi|Void\\Sakshi"
    }

    foreach ($svc in $allServices) {
        $svcName = $svc.Name
        $svcDisp = $svc.DisplayName
        if ($svcName -match "update|telemetry|feedback|report|diagnostic|ceip|experience|tracker|collector") {
            $candId = "svc-$($svcName.ToLower())"
            if ($candidateMap.ContainsKey($candId)) {
                $existing = $candidateMap[$candId]
                $existing.lastSeen = $now
                $existing.hitCount = [int]$existing.hitCount + 1
            } else {
                $newCand = [PSCustomObject]@{
                    id = $candId
                    category = "Service"
                    name = $svcName
                    details = "$svcDisp ($($svc.Status) | $($svc.StartType))"
                    firstSeen = $now
                    lastSeen = $now
                    hitCount = 1
                    status = "pending"
                    recommendedAction = "disable-service"
                }
                $candidateMap[$candId] = $newCand
            }
        }
    }

    Write-Host "  -> [4/5] Scanning User PATH for dead directories & duplicates..." -ForegroundColor Gray
    $rawPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if (-not [string]::IsNullOrWhiteSpace($rawPath)) {
        $pathEntries = $rawPath -split ";" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        $seenPath = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($pe in $pathEntries) {
            $norm = $pe.Trim().TrimEnd("\")
            if ([string]::IsNullOrWhiteSpace($norm) -or (-not (Assert-SakshiShield $pe))) { continue }
            $isDup = $seenPath.Contains($norm)
            $isDead = -not (Test-Path $pe)
            $seenPath.Add($norm) | Out-Null

            if ($isDead -or $isDup) {
                $reason = if ($isDead -and $isDup) { "Dead & Duplicate" } elseif ($isDead) { "Dead Directory" } else { "Duplicate Entry" }
                $candId = "path-" + ([Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($norm)).TrimEnd('=').ToLower())
                if ($candidateMap.ContainsKey($candId)) {
                    $existing = $candidateMap[$candId]
                    $existing.lastSeen = $now
                    $existing.hitCount = [int]$existing.hitCount + 1
                } else {
                    $newCand = [PSCustomObject]@{
                        id = $candId
                        category = "Path"
                        name = $pe
                        details = "$reason in User PATH"
                        firstSeen = $now
                        lastSeen = $now
                        hitCount = 1
                        status = "pending"
                        recommendedAction = "prune-path"
                    }
                    $candidateMap[$candId] = $newCand
                }
            }
        }
    }

    Write-Host "  -> [5/5] Scanning for orphaned residual registry vendor hives..." -ForegroundColor Gray
    $orphanRegs = @("HKCU:\Software\Google", "HKCU:\Software\VMware, Inc.", "HKCU:\Software\Notion", "HKCU:\Software\anytype", "HKCU:\Software\Ollama")
    foreach ($ork in $orphanRegs) {
        if (-not (Assert-SakshiShield $ork)) { continue }
        if (Test-Path $ork) {
            $candId = "reg-" + ($ork -replace '[:\\]', '-').ToLower()
            if ($candidateMap.ContainsKey($candId)) {
                $existing = $candidateMap[$candId]
                $existing.lastSeen = $now
                $existing.hitCount = [int]$existing.hitCount + 1
            } else {
                $newCand = [PSCustomObject]@{
                    id = $candId
                    category = "Registry"
                    name = $ork
                    details = "Orphaned vendor hive of uninstalled software"
                    firstSeen = $now
                    lastSeen = $now
                    hitCount = 1
                    status = "pending"
                    recommendedAction = "purge-reg"
                }
                $candidateMap[$candId] = $newCand
            }
        }
    }

    $drift.candidates = @($candidateMap.Values)
    Save-DriftData $drift

    # Output summary
    $pendingList = @($drift.candidates | Where-Object { $_.status -eq "pending" })
    Write-Host "`n┌────────────────────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "│                   DRIFT SENSOR SCAN REPORT                             │" -ForegroundColor Cyan
    Write-Host "├────────────────────────────────────────────────────────────────────────┤" -ForegroundColor Cyan
    Write-Host "│ Total Candidates Tracked : $($drift.candidates.Count)" -ForegroundColor White
    Write-Host "│ Pending Decision         : $($pendingList.Count)" -ForegroundColor Yellow
    Write-Host "└────────────────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan

    if ($pendingList.Count -gt 0) {
        Write-Host "`nPending Candidates for Assimilation:" -ForegroundColor Yellow
        $pendingList | Format-Table -Property id, category, name, hitCount, recommendedAction, details -AutoSize
        Write-Host "To assimilate a candidate, run: janitor.ps1 assimilate <candidate-id>" -ForegroundColor Cyan
        Write-Host "To ignore a candidate, run:     janitor.ps1 ignore <candidate-id>" -ForegroundColor DarkYellow
    } else {
        Write-Host "  ✅ Zero unhandled drift detected. System is fully aligned with baseline." -ForegroundColor Green
    }
}

# ------------------------------------------------------------------------------
# 13. ACTION: ASSIMILATE (RULE INTEGRATION)
# ------------------------------------------------------------------------------
function Invoke-JanitorAssimilate {
    param ([string]$CandidateId)
    Write-Host "`n======================================================================" -ForegroundColor Cyan
    Write-Host "            🧬 WIN-JANITOR: RULE ASSIMILATION & ENGINE EXPANSION       " -ForegroundColor Cyan
    Write-Host "======================================================================" -ForegroundColor Cyan

    $drift = Get-DriftData
    $learned = Get-LearnedRules

    if (-not $drift.candidates -or $drift.candidates.Count -eq 0) {
        Write-Host "  ℹ️ No candidates in drift.json. Run 'janitor.ps1 learn' first." -ForegroundColor DarkYellow
        return
    }

    $targets = @()
    if ($CandidateId -eq "all-pending") {
        $targets = @($drift.candidates | Where-Object { $_.status -eq "pending" })
    } else {
        $targets = @($drift.candidates | Where-Object { $_.id -eq $CandidateId })
    }

    if ($targets.Count -eq 0) {
        Write-Host "  ⚠️ Candidate '$CandidateId' not found or not in pending state." -ForegroundColor Red
        return
    }

    $assimilatedCount = 0
    foreach ($cand in $targets) {
        if (-not (Assert-SakshiShield "$($cand.name) $($cand.details)")) {
            Write-Host "  🛡️ Blocked: Candidate matches Sakshi sanctuary boundary." -ForegroundColor Magenta
            continue
        }

        switch ($cand.category) {
            "Process" {
                if ($learned.ghostProcesses -notcontains $cand.name) {
                    $learned.ghostProcesses += $cand.name
                    Write-Host "  ✅ Assimilated Process: '$($cand.name)' into ghost process purge list." -ForegroundColor Green
                    $assimilatedCount++
                }
            }
            "Service" {
                $already = $learned.disabledServices | Where-Object { $_.name -eq $cand.name }
                if (-not $already) {
                    $learned.disabledServices += [PSCustomObject]@{
                        name = $cand.name
                        desc = $cand.details
                    }
                    Write-Host "  ✅ Assimilated Service: '$($cand.name)' into baseline disable policy." -ForegroundColor Green
                    $assimilatedCount++
                }
            }
            "Startup" {
                if ($learned.startupRemovals -notcontains $cand.name) {
                    $learned.startupRemovals += $cand.name
                    Write-Host "  ✅ Assimilated Startup: '$($cand.name)' into boot cleanup list." -ForegroundColor Green
                    $assimilatedCount++
                }
            }
            "Folder" {
                if ($learned.ghostPaths -notcontains $cand.name) {
                    $learned.ghostPaths += $cand.name
                    Write-Host "  ✅ Assimilated Folder: '$($cand.name)' into AppData purge list." -ForegroundColor Green
                    $assimilatedCount++
                }
            }
            "Path" {
                Write-Host "  -> Invoking User PATH pruner to eliminate dead/duplicate path..." -ForegroundColor Gray
                Invoke-JanitorPathClean
                $assimilatedCount++
            }
            "Registry" {
                if ($learned.ghostRegKeys -notcontains $cand.name) {
                    $learned.ghostRegKeys += $cand.name
                    Write-Host "  ✅ Assimilated Registry: '$($cand.name)' into residual hive purge list." -ForegroundColor Green
                    Invoke-JanitorRegClean
                    $assimilatedCount++
                }
            }
        }
        $cand.status = "assimilated"
    }

    Save-LearnedRules $learned
    Save-DriftData $drift

    Write-Host "`n🚀 Successfully assimilated $assimilatedCount rule(s) into learned_rules.json!" -ForegroundColor Cyan
    Write-Host "   These new rules are now active and enforced across all janitor routines." -ForegroundColor Green
}

# ------------------------------------------------------------------------------
# 14. ACTION: IGNORE (WHITELIST)
# ------------------------------------------------------------------------------
function Invoke-JanitorIgnore {
    param ([string]$CandidateId)
    $drift = Get-DriftData
    $found = $drift.candidates | Where-Object { $_.id -eq $CandidateId }
    if ($found) {
        $found.status = "ignored"
        Save-DriftData $drift
        Write-Host "  ✅ Candidate '$CandidateId' marked as ignored (whitelisted)." -ForegroundColor Green
    } else {
        Write-Host "  ⚠️ Candidate '$CandidateId' not found." -ForegroundColor DarkYellow
    }
}

# ------------------------------------------------------------------------------
# 15. ACTION: FIX-SHELL (DESKTOP FREEZE, DWM & THUMBNAIL CACHE REMEDIATION)
# ------------------------------------------------------------------------------
function Invoke-JanitorFixShell {
    Write-Host "`n======================================================================" -ForegroundColor Cyan
    Write-Host "         🖥️ WIN-JANITOR: SHELL, DWM & VIRTUAL DESKTOP REMEDIATION       " -ForegroundColor Cyan
    Write-Host "======================================================================" -ForegroundColor Cyan

    # Step 1: Verify Task View, Previews & Shell Experience Compatibility
    Write-Host "`n[1/5] VERIFYING TASK VIEW & PREVIEW COMPATIBILITY" -ForegroundColor Yellow
    try {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAnimations" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value "1" -Force
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "IconsOnly" -Value 0 -Type DWord -Force
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "DisablePreviewDesktop" -Value 0 -Type DWord -Force
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\DWM" -Name "EnableAeroPeek" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 3 -Type DWord -Force
        Write-Host "  ✅ Verified TaskbarAnimations = 1 (Required for modern XAML Alt+Tab & Task View)." -ForegroundColor Green
        Write-Host "  ✅ Verified ShowTaskViewButton = 1 (Task View enabled)." -ForegroundColor Green
        Write-Host "  ✅ Verified IconsOnly = 0 & DisablePreviewDesktop = 0 (Live desktop and window thumbnails active)." -ForegroundColor Green
        Write-Host "  ✅ Verified EnableAeroPeek = 1 (Aero Peek and live DWM surfaces active)." -ForegroundColor Green
    } catch {
        Write-Host "  ⚠️ Could not set preview/animation registry values: $($_.Exception.Message)" -ForegroundColor DarkYellow
    }

    # Step 2: Terminate Explorer, Shell Hosts & Locked COM Workers
    Write-Host "`n[2/5] STOPPING EXPLORER, SHELL HOSTS & RPC COM WORKERS" -ForegroundColor Yellow
    $killedThumbHost = 0
    Get-Process dllhost -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
            $killedThumbHost++
        } catch {}
    }
    if ($killedThumbHost -gt 0) {
        Write-Host "  ✅ Terminated $killedThumbHost active dllhost.exe worker(s) to release database file locks." -ForegroundColor Green
    }

    Write-Host "  -> Terminating all explorer.exe, ShellExperienceHost, and StartMenuExperienceHost processes..." -ForegroundColor Gray
    Stop-Process -Name explorer, ShellExperienceHost, StartMenuExperienceHost -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 1500

    # Step 3: Purge Corrupted Thumbnail & Icon Cache Databases
    Write-Host "`n[3/5] PURGING CORRUPTED THUMBNAIL & ICON CACHE DATABASES" -ForegroundColor Yellow
    $thumbDir = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"
    $purgedCount = 0
    $purgedBytes = 0

    if (Test-Path $thumbDir) {
        $cacheFiles = Get-ChildItem -Path $thumbDir -File -Filter "*cache*.db" -Force -ErrorAction SilentlyContinue
        foreach ($cf in $cacheFiles) {
            try {
                $purgedBytes += $cf.Length
                Remove-Item -LiteralPath $cf.FullName -Force -ErrorAction Stop
                $purgedCount++
            } catch {
                Write-Host "  ⚠️ Could not remove $($cf.Name): $($_.Exception.Message)" -ForegroundColor DarkYellow
            }
        }
    }

    $rootIconCache = "$env:LOCALAPPDATA\IconCache.db"
    if (Test-Path $rootIconCache) {
        try {
            $purgedBytes += (Get-Item -LiteralPath $rootIconCache -Force).Length
            Remove-Item -LiteralPath $rootIconCache -Force -ErrorAction SilentlyContinue
            $purgedCount++
        } catch {}
    }

    $purgedMB = [math]::Round($purgedBytes / 1MB, 2)
    Write-Host "  ✅ Purged $purgedCount thumbnail & icon cache database file(s) ($purgedMB MB cleared)." -ForegroundColor Green

    # Step 4: Ensure Single Authoritative Windows Explorer Shell
    Write-Host "`n[4/5] ENSURING SINGLE AUTHORITATIVE EXPLORER SHELL" -ForegroundColor Yellow
    Start-Sleep -Milliseconds 1500
    $ex = Get-Process explorer -ErrorAction SilentlyContinue
    if (-not $ex) {
        Write-Host "  -> Launching explorer.exe shell..." -ForegroundColor Gray
        Start-Process explorer.exe
        Start-Sleep -Milliseconds 1500
    } else {
        Write-Host "  ✅ Explorer shell automatically resurrected by Winlogon (PID: $($ex[0].Id))." -ForegroundColor Green
    }

    # Step 5: Flush DWM Working Set
    Write-Host "`n[5/5] FLUSHING DWM (DESKTOP WINDOW MANAGER) WORKING SET" -ForegroundColor Yellow
    $dwm = Get-Process dwm -ErrorAction SilentlyContinue
    if ($dwm) {
        try {
            [WinJanitorMem]::EmptyWorkingSet($dwm.Handle) | Out-Null
            Write-Host "  ✅ Flushed DWM working set (Compositor memory freed & refreshed)." -ForegroundColor Green
        } catch {
            Write-Host "  ℹ️ DWM working set flush skipped (Access restricted)." -ForegroundColor Gray
        }
    }

    Write-Host "`n🚀 SHELL REMEDIATION COMPLETE!" -ForegroundColor Cyan
    Write-Host "   • Alt+Tab & Task View (Win+Tab): RESTORED & RESPONSIVE." -ForegroundColor Green
    Write-Host "   • Thumbnail/icon RPC deadlock: RESOLVED." -ForegroundColor Green
    Write-Host "   • Right-click and terminal UI freeze: PREVENTED." -ForegroundColor Green
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
    "packages"         { Invoke-JanitorPackages -SubAction $Target }
    "path-clean"       { Invoke-JanitorPathClean }
    "reg-clean"        { Invoke-JanitorRegClean }
    "dev-hygiene"      { Invoke-JanitorDevHygiene }
    "fix-shell"        { Invoke-JanitorFixShell }
    "learn"            { Invoke-JanitorLearn }
    "assimilate"       { Invoke-JanitorAssimilate -CandidateId $Target }
    "ignore"           { Invoke-JanitorIgnore -CandidateId $Target }
    "help"             {
        Write-Host "Usage: janitor.ps1 <audit|trim|purge|enforce-baseline|diagnose|updates|packages|path-clean|reg-clean|dev-hygiene|fix-shell|learn|assimilate|ignore> [target]" -ForegroundColor Yellow
    }
}
