#!/usr/bin/env bash
# Quick health summary for the cluster. Needs `oc` and a working kubeconfig
# (default ~/.kube/config, or set KUBECONFIG). Read-only: changes nothing.

set -uo pipefail

if ! command -v oc >/dev/null 2>&1; then
  echo "oc is not installed (brew install openshift-cli)" >&2
  exit 2
fi

if ! oc whoami >/dev/null 2>&1; then
  echo "Not logged in to a cluster. Check your kubeconfig." >&2
  exit 2
fi

echo "== Cluster =="
echo "API:     $(oc whoami --show-server)"
echo "User:    $(oc whoami)"
oc get clusterversion -o custom-columns='VERSION:.status.desired.version,CHANNEL:.spec.channel,AVAILABLE:.status.conditions[?(@.type=="Available")].status' --no-headers
echo

echo "== Nodes =="
oc get nodes -o wide
echo

echo "== Resource use =="
oc adm top nodes 2>/dev/null || echo "(metrics not available yet)"
echo

echo "== Cluster operators that need attention =="
not_ok="$(oc get clusteroperators --no-headers | awk '$3 != "True" || $4 != "False" || $5 != "False"')"
if [[ -z "$not_ok" ]]; then
  echo "All cluster operators are Available and not Progressing or Degraded."
else
  echo "NAME VERSION AVAILABLE PROGRESSING DEGRADED SINCE"
  echo "$not_ok"
fi
echo

echo "== Pods not running or completed =="
bad_pods="$(oc get pods -A --no-headers 2>/dev/null | awk '$4 != "Running" && $4 != "Completed"')"
if [[ -z "$bad_pods" ]]; then
  echo "None."
else
  echo "$bad_pods"
fi
