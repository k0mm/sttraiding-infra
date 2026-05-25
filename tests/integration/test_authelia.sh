#!/usr/bin/env bash
# tests/integration/test_authelia.sh
# TASK-022: Authelia integration tests
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../helpers/assert.sh"

DOMAIN="${DOMAIN:-sttraiding.ru}"
AUTHELIA_URL="https://auth.${DOMAIN}"

test_health_endpoint() {
  local status
  status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
    "${AUTHELIA_URL}/api/health")
  assert_equals "200" "$status" "Authelia /api/health returns 200"
}

test_syncthing_redirects_to_auth() {
  local location
  location=$(curl -s -o /dev/null -w "%{redirect_url}" --max-time 10 \
    -H "X-Forwarded-Proto: https" \
    "https://syncthing.${DOMAIN}")
  assert_contains "auth.${DOMAIN}" "$location" \
    "Syncthing without session redirects to auth"
}

test_netdata_redirects_to_auth() {
  local location
  location=$(curl -s -o /dev/null -w "%{redirect_url}" --max-time 10 \
    "https://netdata.${DOMAIN}")
  assert_contains "auth.${DOMAIN}" "$location" \
    "Netdata without session redirects to auth"
}

test_authelia_login_page_loads() {
  local status
  status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${AUTHELIA_URL}")
  assert_equals "200" "$status" "Authelia login page returns 200"
}

test_authelia_container_healthy() {
  local health
  health=$(docker inspect --format='{{.State.Health.Status}}' \
    "$(docker ps -q -f name=authelia)" 2>/dev/null || echo "unknown")
  assert_equals "healthy" "$health" "Authelia container is healthy"
}

test_redis_container_healthy() {
  local health
  health=$(docker inspect --format='{{.State.Health.Status}}' \
    "$(docker ps -q -f name=redis)" 2>/dev/null || echo "unknown")
  assert_equals "healthy" "$health" "Redis container is healthy"
}

echo "=== Authelia Integration Tests ==="
test_health_endpoint
test_authelia_login_page_loads
test_authelia_container_healthy
test_redis_container_healthy
test_syncthing_redirects_to_auth
test_netdata_redirects_to_auth
summary
