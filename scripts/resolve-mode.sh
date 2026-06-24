#!/usr/bin/env bash
set -u
here="$(dirname "$0")"; . "$here/lib.sh"
slug="${1:?usage: resolve-mode.sh <slug> <lint|test>}"
tier="${2:?usage: resolve-mode.sh <slug> <lint|test>}"
reg="${CI_REGISTRY:-${CI_ROOT:?CI_ROOT unset}/registry.tsv}"
[ -f "$reg" ] || die "registry not found at $reg" 2
case "$tier" in
  lint) col=3 ;;
  test) col=4 ;;
  *) die "unknown tier '$tier' (want lint|test)" 2 ;;
esac
mode="$(grep -v '^#' "$reg" | awk -F'\t' -v r="$slug" -v c="$col" '$1==r {print $c; exit}')"
[ -n "$mode" ] || die "repo '$slug' not registered in $reg" 3
case "$mode" in
  none|advisory|gate) printf '%s\n' "$mode" ;;
  *) die "invalid mode '$mode' for $slug/$tier" 4 ;;
esac
