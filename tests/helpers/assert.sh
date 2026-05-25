#!/usr/bin/env bash
# Shared assertion helpers for integration and smoke tests

PASS=0
FAIL=0

assert_equals() {
  local expected="$1"
  local actual="$2"
  local message="${3:-assert_equals}"

  if [ "$expected" = "$actual" ]; then
    echo "  PASS: $message"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $message"
    echo "        expected='$expected' got='$actual'"
    FAIL=$((FAIL + 1))
  fi
}

assert_contains() {
  local expected="$1"
  local actual="$2"
  local message="${3:-assert_contains}"

  if echo "$actual" | grep -q "$expected"; then
    echo "  PASS: $message"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $message"
    echo "        '$expected' not found in response"
    FAIL=$((FAIL + 1))
  fi
}

summary() {
  echo ""
  echo "Results: $PASS passed, $FAIL failed"
  [ "$FAIL" -eq 0 ]
}
