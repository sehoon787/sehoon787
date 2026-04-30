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

if [ -d "$HOME/.nvm/versions/node" ]; then
    NVM_BIN_DIR=$(find "$HOME/.nvm/versions/node" -maxdepth 2 -type d -name bin 2>/dev/null | sort -V | tail -n 1)
    if [ -n "$NVM_BIN_DIR" ]; then
        PATH="$NVM_BIN_DIR:$PATH"
        export PATH
    fi
fi

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

run_with_timeout() {
    local seconds="$1"
    shift

    if command -v gtimeout >/dev/null 2>&1; then
        gtimeout "$seconds" "$@"
    elif command -v timeout >/dev/null 2>&1; then
        timeout "$seconds" "$@"
    else
        "$@"
    fi
}

log "=== Sync started (host: $(hostname -s), file: $DATA_FILE) ==="

# Ensure repo exists
if [ ! -d "$REPO_DIR" ]; then
    git clone https://github.com/sehoon787/sehoon787.git "$REPO_DIR"
    log "Cloned repo"
fi

cd "$REPO_DIR" || { log "ERROR: Cannot cd to $REPO_DIR"; exit 1; }
if ! git pull --rebase origin main > /dev/null 2>&1; then
    log "ERROR: git pull --rebase failed"
    exit 1
fi
log "Pulled latest"

# Collect ccusage data into a temp file first so scheduler failures do not truncate the last good snapshot.
TMP_DATA_FILE=$(mktemp)
if ! npx ccusage daily --json 2>/dev/null > "$TMP_DATA_FILE"; then
    rm -f "$TMP_DATA_FILE"
    log "ERROR: ccusage collection failed"
    exit 1
fi

FILE_SIZE=$(wc -c < "$TMP_DATA_FILE" | tr -d ' ')
log "ccusage collected: $FILE_SIZE bytes"

if [ "$FILE_SIZE" -lt 10 ]; then
    rm -f "$TMP_DATA_FILE"
    log "WARNING: ccusage output too small, skipping push"
    exit 0
fi

mv "$TMP_DATA_FILE" "$DATA_FILE"

# Collect Codex data (if available)
CODEX_FILE="$(hostname -s)-codex-cc.json"
CODEX_OUTPUT=$(run_with_timeout 30s npx --yes @ccusage/codex@latest daily --json 2>/dev/null)
if [ ${#CODEX_OUTPUT} -gt 10 ]; then
    echo "$CODEX_OUTPUT" > "$CODEX_FILE"
    git add "$CODEX_FILE"
    log "Codex data collected: $(wc -c < "$CODEX_FILE" | tr -d ' ') bytes"
else
    log "Codex: not available or timed out (skipped)"
fi

# Collect OpenCode data (if available)
OPENCODE_FILE="$(hostname -s)-opencode-cc.json"
OPENCODE_OUTPUT=$(run_with_timeout 30s npx --yes @ccusage/opencode@latest daily --json 2>/dev/null)
if [ ${#OPENCODE_OUTPUT} -gt 10 ]; then
    echo "$OPENCODE_OUTPUT" > "$OPENCODE_FILE"
    git add "$OPENCODE_FILE"
    log "OpenCode data collected: $(wc -c < "$OPENCODE_FILE" | tr -d ' ') bytes"
else
    log "OpenCode: not available or timed out (skipped)"
fi

# Stage and push
git add *-cc.json *-codex-cc.json *-opencode-cc.json 2>/dev/null
if ! git diff --staged --quiet 2>/dev/null; then
    git commit -m "update: usage data from $(hostname -s)"
    if git push origin main > /dev/null 2>&1; then
        log "Pushed successfully"
    else
        log "ERROR: git push failed"
        exit 1
    fi
else
    log "No changes to push"
fi

log "=== Sync completed ==="
