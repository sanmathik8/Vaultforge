#!/usr/bin/env bash
# Post-deploy smoke tests — runs HTTP health checks against the target ALB endpoint or application URL.
# Usage: ./smoke-test.sh <target-url-or-host>
set -euo pipefail

TARGET_HOST="${1:-localhost:8000}"

echo "Running smoke tests against http://${TARGET_HOST}"

run_check() {
  local path="$1" expected="$2"
  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" "http://${TARGET_HOST}${path}") || code="000"
  if [ "$code" != "$expected" ]; then
    echo "::error::Smoke test failed: GET ${path} returned ${code}, expected ${expected}"
    exit 1
  fi
  echo "  OK  GET ${path} -> ${code}"
}

run_check "/health" "200"
run_check "/" "200"

echo "Smoke tests passed."
