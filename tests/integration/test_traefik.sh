#!/usr/bin/env bash
# tests/integration/test_traefik.sh
# TASK-021: Traefik integration tests
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../helpers/assert.sh"

DOMAIN="${DOMAIN:-sttraiding.ru}"
BASE_URL="https://${DOMAIN}"

test_http_redirects_to_https() {
  local status
  status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "http://${DOMAIN}")
  assert_equals "301" "$status" "HTTP → HTTPS redirect returns 301"
}

test_https_reachable() {
  local status
  status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 -L "$BASE_URL")
  # Any 2xx or 3xx means Traefik is up and terminating TLS
  if [ "$status" -ge 200 ] && [ "$status" -lt 400 ]; then
    echo "  PASS: HTTPS reachable (status=$status)"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: HTTPS not reachable (status=$status)"
    FAIL=$((FAIL + 1))
  fi
}

test_hsts_header_present() {
  local headers
  headers=$(curl -s -I --max-time 10 "$BASE_URL" 2>/dev/null)
  assert_contains "Strict-Transport-Security" "$headers" "HSTS header present"
}

test_unknown_host_returns_404() {
  local status
  status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
    -H "Host: notexist.${DOMAIN}" "https://${DOMAIN}")
  assert_equals "404" "$status" "Unknown host returns 404 (not exposed by default)"
}

test_ping_endpoint() {
  # Traefik healthcheck endpoint — only reachable inside docker network
  # This test runs on the server after deploy
  local status
  status=$(docker inspect --format='{{.State.Health.Status}}' \
    "$(docker ps -q -f name=traefik)" 2>/dev/null || echo "unknown")
  assert_equals "healthy" "$status" "Traefik container is healthy"
}

echo "=== Traefik Integration Tests ==="
test_http_redirects_to_https
test_https_reachable
test_hsts_header_present
test_unknown_host_returns_404
test_ping_endpoint
summary
