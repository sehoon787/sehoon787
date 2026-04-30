# AI Dashboard - Auto Install Guide

> This guide helps AI agents or users set up AI Dashboard sync on a new PC.
> 
> **Usage:** Ask an AI agent (e.g., Claude Code) like this:
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

## Step 2: Configure GitHub Secrets

> **This step is only required when creating a new repository or forking.**
> If you are installing on another PC using the existing sehoon787/sehoon787 repo, Secrets are already configured — skip this step.

Register email addresses in GitHub Secrets to prevent exposure in GitHub Actions workflows.

1. Go to https://github.com/sehoon787/sehoon787/settings/secrets/actions
2. Click **New repository secret**
3. Add the following secrets:

| Name | Value |
|------|-------|
| `EMAIL_PRIMARY` | Primary email address |
| `EMAIL_SECONDARY` | Secondary email address |

These secrets are used as commit author information in `.github/workflows/update-dashboard.yml`.

## Step 3: Install ccusage

```bash
npm install -g ccusage
```

## Step 4: Test Data Collection

```bash
# Verify ccusage works
npx ccusage daily --json
```

If output is valid JSON with `daily` array, proceed. If empty or error, ensure Claude Code has been used on this machine.

## Step 5: Run Initial Sync

### Mac/Linux
```bash
cd ~/sehoon787
chmod +x scripts/sync-ai-dashboard.sh
./scripts/sync-ai-dashboard.sh
```

### Windows (PowerShell)
```powershell
cd $env:USERPROFILE\sehoon787
powershell -ExecutionPolicy Bypass -File scripts\sync-ai-dashboard.ps1
```

Check the log output. Expected:
- `ccusage collected: XXXX bytes` ✅
- `Codex: not available (skipped)` ← Normal if not using Codex
- `OpenCode: not available (skipped)` ← Normal if not using OpenCode
- `Pushed successfully` or `No changes to push` ✅

## Step 6: Schedule Automatic Sync (Every 6 Hours)

### macOS
```bash
cp ~/sehoon787/scripts/com.sehoon787.ai-dashboard-sync.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.sehoon787.ai-dashboard-sync.plist
```

Verify:
```bash
launchctl list | grep ai-dashboard
launchctl kickstart -k gui/$(id -u)/com.sehoon787.ai-dashboard-sync
tail -n 20 ~/sehoon787/scripts/ai-dashboard-sync.log
```

The macOS scheduler runs the script in a non-login shell. The current `sync-ai-dashboard.sh` auto-detects `npx` from `~/.nvm/versions/node/*/bin`, so this verification step is the fastest way to confirm scheduled runs can still find Node tools.

### Windows (PowerShell - Run as Administrator)
```powershell
$script = "$env:USERPROFILE\sehoon787\scripts\sync-ai-dashboard.ps1"
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$script`""
$triggers = @(
    New-ScheduledTaskTrigger -Daily -At "00:00AM"
    New-ScheduledTaskTrigger -Daily -At "06:00AM"
    New-ScheduledTaskTrigger -Daily -At "12:00PM"
    New-ScheduledTaskTrigger -Daily -At "06:00PM"
)
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
Register-ScheduledTask -TaskName "AI Dashboard Daily Sync" -Action $action -Trigger $triggers -Settings $settings -Description "AI Dashboard sync every 6h" -Force
```

Verify:
```powershell
Get-ScheduledTask -TaskName "AI Dashboard Daily Sync" | Select-Object State
```

### Linux (cron)
```bash
chmod +x ~/sehoon787/scripts/sync-ai-dashboard.sh
(crontab -l 2>/dev/null; echo "0 */6 * * * ~/sehoon787/scripts/sync-ai-dashboard.sh") | crontab -
```

Verify:
```bash
crontab -l | grep ai-dashboard
```

## Step 7: Verify Dashboard

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
| macOS scheduled run writes 0-byte JSON | Reload the LaunchAgent, then run `launchctl kickstart -k gui/$(id -u)/com.sehoon787.ai-dashboard-sync` and inspect `~/sehoon787/scripts/ai-dashboard-sync.log` |
| Permission denied (Mac) | Run `chmod +x scripts/sync-ai-dashboard.sh` |
| Task not running (Windows) | Check Task Scheduler → AI Dashboard Daily Sync → History |

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
launchctl unload ~/Library/LaunchAgents/com.sehoon787.ai-dashboard-sync.plist
rm ~/Library/LaunchAgents/com.sehoon787.ai-dashboard-sync.plist
rm -rf ~/sehoon787
```

### Windows
```powershell
Unregister-ScheduledTask -TaskName "AI Dashboard Daily Sync" -Confirm:$false
Remove-Item -Recurse -Force $env:USERPROFILE\sehoon787
```

### Linux
```bash
crontab -l | grep -v vibe | crontab -
rm -rf ~/sehoon787
```
