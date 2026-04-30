#!/bin/bash
# VibeDashboard Daily Sync Script (Mac/Linux)
# Collects ccusage data and pushes to sehoon787/sehoon787 profile repo
#
# SETUP:
#   1. git clone https://github.com/sehoon787/sehoon787.git ~/sehoon787
#   2. npm install -g ccusage (or use npx)
#   3. chmod +x ~/sehoon787/scripts/sync-vibe-dashboard.sh
#   4. Mac: cp ~/sehoon787/scripts/com.sehoon787.vibe-sync.plist ~/Library/LaunchAgents/
#          launchctl load ~/Library/LaunchAgents/com.sehoon787.vibe-sync.plist
#      Linux: crontab -e -> 0 6 * * * ~/sehoon787/scripts/sync-vibe-dashboard.sh

REPO_DIR="${1:-$HOME/sehoon787}"
DATA_FILE="$(hostname -s)-cc.json"
LOG_FILE="$(dirname "$0")/vibe-sync.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

log "=== Sync started (host: $(hostname -s), file: $DATA_FILE) ==="

# Ensure repo exists
if [ ! -d "$REPO_DIR" ]; then
    git clone https://github.com/sehoon787/sehoon787.git "$REPO_DIR"
    log "Cloned repo"
fi

cd "$REPO_DIR" || { log "ERROR: Cannot cd to $REPO_DIR"; exit 1; }
git pull origin main > /dev/null 2>&1
log "Pulled latest"

# Collect ccusage data (no BOM on Mac/Linux by default)
npx ccusage daily --json 2>/dev/null > "$DATA_FILE"
FILE_SIZE=$(wc -c < "$DATA_FILE" | tr -d ' ')
log "ccusage collected: $FILE_SIZE bytes"

if [ "$FILE_SIZE" -lt 10 ]; then
    log "WARNING: ccusage output too small, skipping push"
    exit 0
fi

# Stage and push
git add "$DATA_FILE"
if ! git diff --staged --quiet 2>/dev/null; then
    git commit -m "update: daily ccusage data from $(hostname -s) [skip ci]"
    git push origin main > /dev/null 2>&1
    log "Pushed successfully"
else
    log "No changes to push"
fi

log "=== Sync completed ==="
