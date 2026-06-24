#!/usr/bin/env bash
# Usage: test-entry.sh <language> <repo-root> <mode>
# mode is supplied by the caller workflow (none|advisory|gate), not a central registry.
set -u
here="$(dirname "$0")"; . "$here/lib.sh"
lang="${1:?usage: test-entry.sh <language> <repo-root> <mode>}"
root="${2:?}"; mode="${3:?}"
case "$mode" in none|advisory|gate) ;; *) die "invalid test mode '$mode' (want none|advisory|gate)" 4 ;; esac
if [ "$mode" = "none" ]; then log "tests skipped (mode=none)"; exit 0; fi
run_test="${CI_RUN_TEST:-$here/run-test.sh}"
bash "$run_test" "$lang" "$root"; rc=$?
case "$rc" in
  0) log "tests clean"; exit 0 ;;
  2) log "tests INFRA error: failing loud (all modes)"; exit 2 ;;
  1) if [ "$mode" = "advisory" ]; then
       log "advisory: test failures (non-blocking)"; exit 0
     else
       log "gate: test failures, FAILING"; exit 1
     fi ;;
  *) log "unexpected run-test exit $rc, treating as infra"; exit 2 ;;
esac
