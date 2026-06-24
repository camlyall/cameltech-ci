#!/usr/bin/env bash
# vitest run. Deps installed in <repo-root> by caller. No test script -> clean.
set -u
here="$(dirname "$0")"; . "$here/lib.sh"
lang="${1:?}"; root="${2:?}"
[ "$lang" = "astro" ] || die "run-test: unsupported language '$lang'" 2
cd "$root" || die "cannot cd to $root" 2
if ! node -e "process.exit(require('./package.json').scripts?.test?0:1)" 2>/dev/null; then
  log "no test script in $root, treating as clean"; exit 0
fi
npm test --silent; rc=$?
case "$rc" in
  0) log "run-test clean"; exit 0 ;;
  1) log "run-test failures"; exit 1 ;;
  *) die "test infra error (exit $rc)" 2 ;;
esac
