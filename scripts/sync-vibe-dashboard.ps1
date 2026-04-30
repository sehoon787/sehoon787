# VibeDashboard Daily Sync Script
# Collects ccusage data and pushes to sehoon787/sehoon787 profile repo
#
# SETUP ON ANY PC:
#   1. git clone https://github.com/sehoon787/sehoon787.git $env:USERPROFILE\sehoon787
#   2. npm install -g ccusage (or use npx)
#   3. Copy this script to any location
#   4. Register in Task Scheduler:
#      $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"<SCRIPT_PATH>`""
#      $trigger = New-ScheduledTaskTrigger -Daily -At "06:00AM"
#      $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
#      Register-ScheduledTask -TaskName "VibeDashboard Daily Sync" -Action $action -Trigger $trigger -Settings $settings -Force

param(
    [string]$RepoDir = "$env:USERPROFILE\sehoon787",
    [string]$DataFileName = "$env:COMPUTERNAME-cc.json"
)

$ErrorActionPreference = "Stop"
$LogFile = Join-Path (Split-Path $MyInvocation.MyCommand.Path) "vibe-sync.log"

function Write-Log($msg) {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$ts $msg" | Out-File -Append -FilePath $LogFile -Encoding ascii
}

try {
    Write-Log "=== Sync started (host: $env:COMPUTERNAME, file: $DataFileName) ==="

    # Ensure repo exists
    if (-not (Test-Path $RepoDir)) {
        git clone https://github.com/sehoon787/sehoon787.git $RepoDir
        Write-Log "Cloned repo"
    }

    Set-Location $RepoDir
    $ErrorActionPreference = "Continue"
    git pull origin main 2>&1 | Out-Null
    $ErrorActionPreference = "Stop"
    Write-Log "Pulled latest"

    # Collect ccusage data (UTF-8 without BOM)
    $ccOutput = npx ccusage daily --json 2>$null | Out-String
    $outPath = Join-Path $RepoDir $DataFileName
    [System.IO.File]::WriteAllText($outPath, $ccOutput.Trim(), (New-Object System.Text.UTF8Encoding $false))

    $fileSize = (Get-Item $outPath).Length
    Write-Log "ccusage collected: $fileSize bytes"

    if ($fileSize -lt 10) {
        Write-Log "WARNING: ccusage output too small, skipping push"
        exit 0
    }

    # Collect Codex data (if available)
    try {
        $codexOutput = npx @ccusage/codex@latest daily --json 2>$null | Out-String
        if ($codexOutput -and $codexOutput.Trim().Length -gt 10) {
            $codexFile = Join-Path $RepoDir "$env:COMPUTERNAME-codex-cc.json"
            [System.IO.File]::WriteAllText($codexFile, $codexOutput.Trim(), (New-Object System.Text.UTF8Encoding $false))
            git add $codexFile
            Write-Log "Codex data collected: $((Get-Item $codexFile).Length) bytes"
        }
    } catch {
        Write-Log "Codex: not available (skipped)"
    }

    # Collect OpenCode data (if available)
    try {
        $openOutput = npx @ccusage/opencode@latest daily --json 2>$null | Out-String
        if ($openOutput -and $openOutput.Trim().Length -gt 10) {
            $openFile = Join-Path $RepoDir "$env:COMPUTERNAME-opencode-cc.json"
            [System.IO.File]::WriteAllText($openFile, $openOutput.Trim(), (New-Object System.Text.UTF8Encoding $false))
            git add $openFile
            Write-Log "OpenCode data collected: $((Get-Item $openFile).Length) bytes"
        }
    } catch {
        Write-Log "OpenCode: not available (skipped)"
    }

    # Stage and push
    $ErrorActionPreference = "Continue"
    git add *-cc.json *-codex-cc.json *-opencode-cc.json 2>&1 | Out-Null
    git diff --staged --quiet 2>&1 | Out-Null
    $hasStagedChanges = ($LASTEXITCODE -ne 0)
    $ErrorActionPreference = "Stop"
    if ($hasStagedChanges) {
        git commit -m "update: daily usage data from $env:COMPUTERNAME [skip ci]"
        $ErrorActionPreference = "Continue"
        git push origin main 2>&1 | Out-Null
        $ErrorActionPreference = "Stop"
        Write-Log "Pushed successfully"
    } else {
        Write-Log "No changes to push"
    }

    Write-Log "=== Sync completed ==="
} catch {
    Write-Log "ERROR: $_"
    exit 1
}
