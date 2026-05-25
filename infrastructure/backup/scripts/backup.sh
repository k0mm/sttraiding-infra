#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-full}"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] BACKUP | $*"; }

notify() {
  local status="$1" msg="$2"
  if [ -n "${TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${TELEGRAM_CHAT_ID:-}" ]; then
    curl -s -X POST \
      "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
      --proxy "${HTTP_PROXY:-}" \
      -d chat_id="${TELEGRAM_CHAT_ID}" \
      -d text="${status} Backup [${TARGET}]: ${msg}" || true
  fi
}

run_backup() {
  local tag="$1" path="$2"
  log "Starting: tag=$tag path=$path"
  if restic backup --tag "$tag" "$path"; then
    log "OK: $tag"
    restic forget --tag "$tag" \
      --keep-daily 7 --keep-weekly 4 --keep-monthly 3 \
      --prune || true
  else
    log "FAIL: $tag"
    notify "❌" "$tag failed"
    return 1
  fi
}

case "$TARGET" in
  obsidian)
    run_backup "obsidian" /backup/obsidian
    notify "✅" "obsidian vault backed up"
    ;;
  full)
    run_backup "obsidian"  /backup/obsidian
    run_backup "syncthing" /backup/syncthing
    run_backup "authelia"  /backup/authelia
    run_backup "volumes"   /backup/volumes
    notify "✅" "full backup complete"
    ;;
  *)
    log "Unknown target: $TARGET. Use: obsidian | full"
    exit 1
    ;;
esac

# Sync to Yandex Disk via rclone
log "Syncing to Yandex Disk"
rclone sync \
  "${RESTIC_REPOSITORY}" \
  "yandex:sttraiding-backup" \
  --config /backup/rclone.conf \
  --log-level INFO || notify "⚠️" "rclone sync failed"

log "Done"
