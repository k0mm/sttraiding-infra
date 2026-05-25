#!/usr/bin/env bash
set -euo pipefail

# Usage: restore.sh <snapshot-id|latest> <tag> <target-path>
# Example: restore.sh latest obsidian /restore/obsidian

SNAPSHOT="${1:?Usage: restore.sh <snapshot-id|latest> <tag> <target-path>}"
TAG="${2:?provide tag}"
TARGET="${3:?provide target path}"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] RESTORE | $*"; }

log "Restoring snapshot=$SNAPSHOT tag=$TAG to $TARGET"

mkdir -p "$TARGET"

restic restore "$SNAPSHOT" \
  --tag "$TAG" \
  --target "$TARGET"

log "Restore complete: $TARGET"
