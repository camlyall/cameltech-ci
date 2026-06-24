#!/usr/bin/env bash
# astro check + prettier --check. Deps must be installed in <repo-root> (caller did npm ci).
set -u
here="$(dirname "$0")"; . "$here/lib.sh"
lang="${1:?}"; root="${2:?}"
[ "$lang" = "astro" ] || die "run-lint: unsupported language '$lang'" 2
cd "$root" || die "cannot cd to $root" 2
findings=0
# astro check: 0 pass, non-zero = type/content findings.
if ! npx --no-install astro check; then findings=1; fi
# prettier --check: 0 formatted, 1 needs formatting (findings), 2+ infra.
prc=0; npx --no-install prettier --check . || prc=$?
case "$prc" in
  0) ;;
  1) findings=1 ;;
  *) die "prettier infra error (exit $prc)" 2 ;;
esac
[ "$findings" -eq 0 ] && { log "run-lint clean"; exit 0; } || { log "run-lint findings"; exit 1; }
