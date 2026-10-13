#!/usr/bin/env bash
# Verify the DNS records single-node OpenShift needs, before an install or rebuild.
#
# Usage: ./scripts/check-dns.sh [cluster-name] [base-domain] [expected-ip]
# Defaults match this lab. Pass a resolver as RESOLVER=1.1.1.1 to bypass local caches.

set -uo pipefail

CLUSTER="${1:-sno}"
DOMAIN="${2:-adelledonne-lab.com}"
EXPECTED_IP="${3:-192.168.1.82}"
RESOLVER="${RESOLVER:-}"

if ! command -v dig >/dev/null 2>&1; then
  echo "dig is not installed" >&2
  exit 2
fi

lookup() {
  if [[ -n "$RESOLVER" ]]; then
    dig +short "$1" "@$RESOLVER" A | tail -n1
  else
    dig +short "$1" A | tail -n1
  fi
}

failures=0

expect_ip() {
  local name="$1" got
  got="$(lookup "$name")"
  if [[ "$got" == "$EXPECTED_IP" ]]; then
    printf 'PASS  %-55s -> %s\n' "$name" "$got"
  else
    printf 'FAIL  %-55s -> %s (expected %s)\n' "$name" "${got:-no answer}" "$EXPECTED_IP"
    failures=$((failures + 1))
  fi
}

expect_none() {
  local name="$1" got
  got="$(lookup "$name")"
  if [[ -z "$got" ]]; then
    printf 'PASS  %-55s -> no answer (no catch-all)\n' "$name"
  else
    printf 'FAIL  %-55s -> %s (should not resolve)\n' "$name" "$got"
    failures=$((failures + 1))
  fi
}

echo "Checking DNS for cluster '$CLUSTER' on '$DOMAIN' (expecting $EXPECTED_IP)${RESOLVER:+ via $RESOLVER}"
expect_ip   "api.$CLUSTER.$DOMAIN"
expect_ip   "api-int.$CLUSTER.$DOMAIN"
expect_ip   "test.apps.$CLUSTER.$DOMAIN"
expect_ip   "console-openshift-console.apps.$CLUSTER.$DOMAIN"
expect_none "validateNoWildcardDNS.$CLUSTER.$DOMAIN"

if (( failures > 0 )); then
  echo "$failures check(s) failed."
  exit 1
fi
echo "All DNS checks passed."
