#!/usr/bin/env bash
set -euo pipefail

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

log "Backup service starting"

# Init restic repo if not exists
if ! restic --no-lock snapshots &>/dev/null 2>&1; then
  log "Initialising restic repository"
  restic init
fi

# Run initial backup, then schedule via cron loop
/backup/scripts/backup.sh

# Simple cron loop — no crond dependency
while true; do
  # Obsidian vault: every 6 hours
  NEXT_OBSIDIAN=$(( $(date +%s) + 6*3600 ))
  # Full backup: every 24 hours
  NEXT_FULL=$(( $(date +%s) + 24*3600 ))

  sleep 3600  # check every hour

  now=$(date +%s)
  if [ "$now" -ge "$NEXT_OBSIDIAN" ]; then
    /backup/scripts/backup.sh obsidian || log "WARN: obsidian backup failed"
    NEXT_OBSIDIAN=$(( now + 6*3600 ))
  fi
  if [ "$now" -ge "$NEXT_FULL" ]; then
    /backup/scripts/backup.sh full || log "WARN: full backup failed"
    NEXT_FULL=$(( now + 24*3600 ))
  fi
done
