#!/usr/bin/env bash
# tests/integration/test_syncthing.sh
# TASK-030: Syncthing integration tests
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../helpers/assert.sh"

DOMAIN="${DOMAIN:-sttraiding.ru}"

test_syncthing_redirects_without_auth() {
  local status
  status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
    "https://syncthing.${DOMAIN}")
  # 302 redirect to auth, or 401 from authelia forwardAuth
  if [ "$status" = "302" ] || [ "$status" = "401" ]; then
    echo "  PASS: Syncthing protected (status=$status)"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: Syncthing not protected (status=$status)"
    FAIL=$((FAIL + 1))
  fi
}

test_syncthing_container_healthy() {
  local health
  health=$(docker inspect --format='{{.State.Health.Status}}' \
    "$(docker ps -q -f name=syncthing)" 2>/dev/null || echo "unknown")
  assert_equals "healthy" "$health" "Syncthing container is healthy"
}

test_obsidian_volume_exists() {
  local exit_code
  docker volume inspect obsidian-vault > /dev/null 2>&1
  exit_code=$?
  if [ "$exit_code" -eq 0 ]; then
    echo "  PASS: obsidian-vault volume exists"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: obsidian-vault volume not found"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Syncthing Integration Tests ==="
test_syncthing_redirects_without_auth
test_syncthing_container_healthy
test_obsidian_volume_exists
summary
