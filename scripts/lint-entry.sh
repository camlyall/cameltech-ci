#!/usr/bin/env bash
set -u
here="$(dirname "$0")"; . "$here/lib.sh"
slug="${1:?usage: lint-entry.sh <slug> <language> <repo-root>}"
lang="${2:?}"; root="${3:?}"
mode="$(bash "$here/resolve-mode.sh" "$slug" lint)" || exit $?
if [ "$mode" = "none" ]; then log "lint skipped ($slug, mode=none)"; exit 0; fi
run_lint="${CI_RUN_LINT:-$here/run-lint.sh}"
bash "$run_lint" "$lang" "$root"; rc=$?
case "$rc" in
  0) log "lint clean ($slug)"; exit 0 ;;
  2) log "lint INFRA error ($slug) — failing loud (all modes)"; exit 2 ;;
  1) if [ "$mode" = "advisory" ]; then
       log "advisory: $slug lint findings (non-blocking)"; exit 0
     else
       log "gate: $slug lint findings — FAILING"; exit 1
     fi ;;
  *) log "unexpected run-lint exit $rc ($slug) — treating as infra"; exit 2 ;;
esac
