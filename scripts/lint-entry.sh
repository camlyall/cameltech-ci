#!/usr/bin/env bash
# Usage: lint-entry.sh <language> <repo-root> <mode>
# mode is supplied by the caller workflow (none|advisory|gate), not a central registry.
set -u
here="$(dirname "$0")"; . "$here/lib.sh"
lang="${1:?usage: lint-entry.sh <language> <repo-root> <mode>}"
root="${2:?}"; mode="${3:?}"
case "$mode" in none|advisory|gate) ;; *) die "invalid lint mode '$mode' (want none|advisory|gate)" 4 ;; esac
if [ "$mode" = "none" ]; then log "lint skipped (mode=none)"; exit 0; fi
run_lint="${CI_RUN_LINT:-$here/run-lint.sh}"
bash "$run_lint" "$lang" "$root"; rc=$?
case "$rc" in
  0) log "lint clean"; exit 0 ;;
  2) log "lint INFRA error: failing loud (all modes)"; exit 2 ;;
  1) if [ "$mode" = "advisory" ]; then
       log "advisory: lint findings (non-blocking)"; exit 0
     else
       log "gate: lint findings, FAILING"; exit 1
     fi ;;
  *) log "unexpected run-lint exit $rc, treating as infra"; exit 2 ;;
esac
