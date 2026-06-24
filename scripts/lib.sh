#!/usr/bin/env bash
# Shared helpers. log() -> stderr (keeps stdout clean for value-returning scripts).
log() { printf '%s\n' "$*" >&2; }
die() { log "ERROR: $1"; exit "${2:-1}"; }
