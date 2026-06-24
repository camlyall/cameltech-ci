#!/usr/bin/env bash
# Bash test suite for the cameltech-ci engine. Run: bash tests/run.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export CI_ROOT="$ROOT"
PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); printf 'ok   - %s\n' "$1"; }
no()   { FAIL=$((FAIL+1)); printf 'FAIL - %s\n' "$1"; }
# assert_exit <desc> <expected-code> <cmd...>
assert_exit() {
  local desc="$1" exp="$2"; shift 2
  local out; out="$("$@" 2>/dev/null)"; local rc=$?
  if [ "$rc" -eq "$exp" ]; then ok "$desc (exit $rc)"; else no "$desc (got $rc want $exp)"; fi
}
# assert_stdout <desc> <expected> <cmd...>
assert_stdout() {
  local desc="$1" exp="$2"; shift 2
  local out; out="$("$@" 2>/dev/null)"
  if [ "$out" = "$exp" ]; then ok "$desc"; else no "$desc (got '$out' want '$exp')"; fi
}

REG="$ROOT/tests/fixtures/registry.tsv"

# --- resolve-mode.sh ---
CI_REGISTRY="$REG" assert_stdout "resolve lint mode for registered repo" "gate" \
  bash "$ROOT/scripts/resolve-mode.sh" demo-gate lint
CI_REGISTRY="$REG" assert_stdout "resolve test mode for registered repo" "advisory" \
  bash "$ROOT/scripts/resolve-mode.sh" demo-gate test
CI_REGISTRY="$REG" assert_exit "unregistered repo -> exit 3" 3 \
  env CI_REGISTRY="$REG" bash "$ROOT/scripts/resolve-mode.sh" nope lint
CI_REGISTRY="$REG" assert_exit "invalid mode -> exit 4" 4 \
  env CI_REGISTRY="$REG" bash "$ROOT/scripts/resolve-mode.sh" demo-bad lint

echo "---"; echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
