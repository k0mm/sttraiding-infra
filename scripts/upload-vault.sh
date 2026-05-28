#!/usr/bin/env bash
# Copies local Obsidian Vault into the obsidian-vault Docker volume on the server.
# Usage: ./scripts/upload-vault.sh [local-vault-path]
# Requires: .env at repo root with SERVER_IP, SERVER_USER, LOCAL_SSH_KEY

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load env from repo root (one level up from sttraiding-infra)
ENV_FILE="$ROOT_DIR/../.env"
if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  set -a; source "$ENV_FILE"; set +a
fi

SERVER_IP="${SERVER_IP:?SERVER_IP not set}"
SERVER_USER="${SERVER_USER:-root}"
SSH_KEY="${LOCAL_SSH_KEY:-$HOME/.ssh/id_ed25519}"
LOCAL_VAULT="${1:-$ROOT_DIR/../Vault}"

SSH_OPTS=(-i "$SSH_KEY" -o StrictHostKeyChecking=no -o BatchMode=yes)

echo "==> Checking local vault: $LOCAL_VAULT"
if [[ ! -d "$LOCAL_VAULT" ]]; then
  echo "ERROR: vault directory not found: $LOCAL_VAULT" >&2
  exit 1
fi

echo "==> Ensuring Docker volume exists on server..."
ssh "${SSH_OPTS[@]}" "$SERVER_USER@$SERVER_IP" \
  "docker volume inspect obsidian-vault >/dev/null 2>&1 || docker volume create obsidian-vault"

echo "==> Uploading vault to server (temp location)..."
ssh "${SSH_OPTS[@]}" "$SERVER_USER@$SERVER_IP" "rm -rf /tmp/obsidian-vault-upload && mkdir -p /tmp/obsidian-vault-upload"
rsync -az --delete \
  -e "ssh ${SSH_OPTS[*]}" \
  --exclude='.DS_Store' \
  --exclude='*.tmp' \
  "$LOCAL_VAULT/" \
  "$SERVER_USER@$SERVER_IP:/tmp/obsidian-vault-upload/"

echo "==> Copying from temp location into Docker volume..."
ssh "${SSH_OPTS[@]}" "$SERVER_USER@$SERVER_IP" bash <<'REMOTE'
set -euo pipefail
# Use a throw-away container to populate the volume
docker run --rm \
  -v obsidian-vault:/vault \
  -v /tmp/obsidian-vault-upload:/src:ro \
  alpine sh -c "cp -a /src/. /vault/ && echo 'Done: $(find /vault -type f | wc -l) files in volume'"
rm -rf /tmp/obsidian-vault-upload
REMOTE

echo "==> Vault upload complete."
echo "    Syncthing will detect the files on next startup and make them available for sync."
