# AI Dashboard - Auto Install Guide

> 이 문서는 AI 에이전트 또는 사용자가 새로운 PC에서 AI Dashboard 동기화를 설정하기 위한 설치 가이드입니다.
> 
> **사용법:** Claude Code 등 AI 에이전트에게 아래와 같이 요청하세요:
> ```
> Read https://raw.githubusercontent.com/sehoon787/sehoon787/main/scripts/AI-INSTALL.md and follow every step.
> ```

---

## Prerequisites

- Git (git CLI)
- Node.js 20+
- npm or npx

---

## Step 1: Clone Repository

```bash
# Mac/Linux
git clone https://github.com/sehoon787/sehoon787.git ~/sehoon787

# Windows (PowerShell)
git clone https://github.com/sehoon787/sehoon787.git $env:USERPROFILE\sehoon787
```

## Step 2: Install ccusage

```bash
npm install -g ccusage
```

## Step 3: Test Data Collection

```bash
# Verify ccusage works
npx ccusage daily --json
```

If output is valid JSON with `daily` array, proceed. If empty or error, ensure Claude Code has been used on this machine.

## Step 4: Run Initial Sync

### Mac/Linux
```bash
cd ~/sehoon787
chmod +x scripts/sync-vibe-dashboard.sh
./scripts/sync-vibe-dashboard.sh
```

### Windows (PowerShell)
```powershell
cd $env:USERPROFILE\sehoon787
powershell -ExecutionPolicy Bypass -File scripts\sync-vibe-dashboard.ps1
```

Check the log output. Expected:
- `ccusage collected: XXXX bytes` ✅
- `Codex: not available (skipped)` ← Normal if not using Codex
- `OpenCode: not available (skipped)` ← Normal if not using OpenCode
- `Pushed successfully` or `No changes to push` ✅

## Step 5: Schedule Automatic Sync (Every 6 Hours)

### macOS
```bash
cp ~/sehoon787/scripts/com.sehoon787.vibe-sync.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.sehoon787.vibe-sync.plist
```

Verify:
```bash
launchctl list | grep vibe
```

### Windows (PowerShell - Run as Administrator)
```powershell
$script = "$env:USERPROFILE\sehoon787\scripts\sync-vibe-dashboard.ps1"
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$script`""
$triggers = @(
    New-ScheduledTaskTrigger -Daily -At "00:00AM"
    New-ScheduledTaskTrigger -Daily -At "06:00AM"
    New-ScheduledTaskTrigger -Daily -At "12:00PM"
    New-ScheduledTaskTrigger -Daily -At "06:00PM"
)
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
Register-ScheduledTask -TaskName "VibeDashboard Daily Sync" -Action $action -Trigger $triggers -Settings $settings -Description "AI Dashboard sync every 6h" -Force
```

Verify:
```powershell
Get-ScheduledTask -TaskName "VibeDashboard Daily Sync" | Select-Object State
```

### Linux (cron)
```bash
chmod +x ~/sehoon787/scripts/sync-vibe-dashboard.sh
(crontab -l 2>/dev/null; echo "0 */6 * * * ~/sehoon787/scripts/sync-vibe-dashboard.sh") | crontab -
```

Verify:
```bash
crontab -l | grep vibe
```

## Step 6: Verify Dashboard

1. Visit https://github.com/sehoon787
2. AI Dashboard SVG should display usage data
3. Data updates every 6 hours automatically

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `ccusage` returns empty | Claude Code hasn't been used on this machine yet |
| `git push` fails | Run `git config credential.helper store` and authenticate |
| SVG not updating | Check GitHub Actions: https://github.com/sehoon787/sehoon787/actions |
| Permission denied (Mac) | Run `chmod +x scripts/sync-vibe-dashboard.sh` |
| Task not running (Windows) | Check Task Scheduler → VibeDashboard Daily Sync → History |

## File Naming Convention

Each machine generates a unique data file based on hostname:
- `DESKTOP-ABC-cc.json` ← Windows PC
- `Macbook-Pro-cc.json` ← Mac
- `ubuntu-server-cc.json` ← Linux

GitHub Actions merges all `*-cc.json` files into a single dashboard.

## Supported Tools

| Tool | Package | Auto-collected |
|------|---------|---------------|
| Claude Code | ccusage | ✅ |
| OpenAI Codex | @ccusage/codex | ✅ (if installed) |
| OpenCode | @ccusage/opencode | ✅ (if installed) |

## Uninstall

### macOS
```bash
launchctl unload ~/Library/LaunchAgents/com.sehoon787.vibe-sync.plist
rm ~/Library/LaunchAgents/com.sehoon787.vibe-sync.plist
rm -rf ~/sehoon787
```

### Windows
```powershell
Unregister-ScheduledTask -TaskName "VibeDashboard Daily Sync" -Confirm:$false
Remove-Item -Recurse -Force $env:USERPROFILE\sehoon787
```

### Linux
```bash
crontab -l | grep -v vibe | crontab -
rm -rf ~/sehoon787
```
