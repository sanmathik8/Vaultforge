#!/usr/bin/env bash
# Post-deploy smoke tests — run in-cluster against the just-deployed Service.
# Usage: ./smoke-test.sh <overlay>
set -euo pipefail

OVERLAY="${1:-dev}"
NAMESPACE="vault-forge"
SVC="vault-forge-app"

echo "Running smoke tests against ${SVC}.${NAMESPACE} (${OVERLAY})"

SVC_IP=$(kubectl get svc "$SVC" -n "$NAMESPACE" -o jsonpath='{.spec.clusterIP}')

run_check() {
  local path="$1" expected="$2"
  local code
  code=$(kubectl run "smoke-$$-${RANDOM}" --rm -i --restart=Never --image=curlimages/curl -- \
    curl -s -o /dev/null -w "%{http_code}" "http://${SVC_IP}:8000${path}")
  if [ "$code" != "$expected" ]; then
    echo "::error::Smoke test failed: GET ${path} returned ${code}, expected ${expected}"
    exit 1
  fi
  echo "  OK  GET ${path} -> ${code}"
}

run_check "/health" "200"
run_check "/" "200"

echo "Smoke tests passed."
