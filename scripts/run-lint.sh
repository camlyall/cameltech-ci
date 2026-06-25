#!/usr/bin/env bash
# astro check + prettier --check. Deps must be installed in <repo-root> (caller did npm ci).
set -u
here="$(dirname "$0")"; . "$here/lib.sh"
# Canonical prettier config (rules) is the single source of truth; resolve it
# absolutely before we cd into the target. Each repo keeps its own
# .prettierignore (paths are repo-specific) which prettier auto-discovers.
cfg="$(cd "$here/.." && pwd)/configs/prettierrc.json"
[ -f "$cfg" ] || die "run-lint: canonical prettier config missing: $cfg" 2
lang="${1:?}"; root="${2:?}"
[ "$lang" = "astro" ] || die "run-lint: unsupported language '$lang'" 2
cd "$root" || die "cannot cd to $root" 2
findings=0
# astro check: 0 pass, non-zero = type/content findings.
if ! npx --no-install astro check; then findings=1; fi
# prettier --check against the central config: 0 formatted, 1 needs formatting
# (findings), 2+ infra. Plugins resolve from this repo's node_modules.
prc=0; npx --no-install prettier --check . --config "$cfg" || prc=$?
case "$prc" in
  0) ;;
  1) findings=1 ;;
  *) die "prettier infra error (exit $prc)" 2 ;;
esac
[ "$findings" -eq 0 ] && { log "run-lint clean"; exit 0; } || { log "run-lint findings"; exit 1; }
