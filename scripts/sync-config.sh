#!/usr/bin/env bash
# Usage: sync-config.sh <slug> <target-dir> [--check|--update]
set -u
here="$(dirname "$0")"; . "$here/lib.sh"
slug="${1:?usage: sync-config.sh <slug> <target-dir> [--check|--update]}"
target="${2:?}"; mode="${3:-}"
case "$mode" in ''|--check|--update) ;; *) die "unknown flag '$mode'" 2 ;; esac
[ -d "$target" ] || die "target-dir '$target' does not exist" 2
reg="${CI_REGISTRY:-${CI_ROOT:?CI_ROOT unset}/registry.tsv}"
[ -f "$reg" ] || die "registry not found at $reg" 2
lang="$(grep -v '^#' "$reg" | awk -F'\t' -v r="$slug" '$1==r {print $2; exit}')"
[ -n "$lang" ] || die "repo '$slug' not registered" 3
[ "$lang" = "astro" ] || die "sync not implemented for language '$lang'" 2
src="$CI_ROOT/configs/prettierrc.json"
dst="$target/.prettierrc.json"
[ -f "$src" ] || die "canonical config missing: $src" 2

if [ "$mode" = "--check" ]; then
  [ -f "$dst" ] || { log "DRIFT: $dst absent"; exit 2; }
  if diff -q "$src" "$dst" >/dev/null 2>&1; then log "in sync: $slug"; exit 0; fi
  log "DRIFT: $dst differs from canonical"; diff -u "$dst" "$src" 2>/dev/null || true; exit 1
fi
if [ "$mode" = "--update" ]; then
  cp "$src" "$dst" || die "failed to update $dst" 2; log "updated $dst"; exit 0
fi
# greenfield
if [ -f "$dst" ] && ! diff -q "$src" "$dst" >/dev/null 2>&1; then
  die ".prettierrc.json exists and differs; rerun with --update to overwrite" 2
fi
cp "$src" "$dst" || die "failed to write $dst" 2; log "wrote $dst"; exit 0
