#!/usr/bin/env bash
set -u
here="$(dirname "$0")"; . "$here/lib.sh"
slug="${1:?usage: test-entry.sh <slug> <language> <repo-root>}"
lang="${2:?}"; root="${3:?}"
mode="$(bash "$here/resolve-mode.sh" "$slug" test)" || exit $?
if [ "$mode" = "none" ]; then log "tests skipped ($slug, mode=none)"; exit 0; fi
run_test="${CI_RUN_TEST:-$here/run-test.sh}"
bash "$run_test" "$lang" "$root"; rc=$?
case "$rc" in
  0) log "tests clean ($slug)"; exit 0 ;;
  2) log "tests INFRA error ($slug) — failing loud (all modes)"; exit 2 ;;
  1) if [ "$mode" = "advisory" ]; then
       log "advisory: $slug test failures (non-blocking)"; exit 0
     else
       log "gate: $slug test failures — FAILING"; exit 1
     fi ;;
  *) log "unexpected run-test exit $rc ($slug) — treating as infra"; exit 2 ;;
esac
