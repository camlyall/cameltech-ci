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

# --- lint-entry.sh classification (run-lint stubbed via CI_RUN_LINT) ---
STUB="$(mktemp)"; chmod +x "$STUB"
mkstub() { printf '#!/usr/bin/env bash\nexit %s\n' "$1" > "$STUB"; }

mkstub 0; CI_REGISTRY="$REG" CI_RUN_LINT="$STUB" assert_exit "clean -> 0 (gate)" 0 \
  env CI_REGISTRY="$REG" CI_RUN_LINT="$STUB" bash "$ROOT/scripts/lint-entry.sh" demo-gate astro /tmp
mkstub 1; CI_REGISTRY="$REG" CI_RUN_LINT="$STUB" assert_exit "findings under gate -> 1" 1 \
  env CI_REGISTRY="$REG" CI_RUN_LINT="$STUB" bash "$ROOT/scripts/lint-entry.sh" demo-gate astro /tmp
mkstub 1; assert_exit "findings under advisory -> 0" 0 \
  env CI_REGISTRY="$REG" CI_RUN_LINT="$STUB" bash "$ROOT/scripts/lint-entry.sh" demo-advisory astro /tmp
mkstub 2; assert_exit "infra under advisory -> 2 (fail loud)" 2 \
  env CI_REGISTRY="$REG" CI_RUN_LINT="$STUB" bash "$ROOT/scripts/lint-entry.sh" demo-advisory astro /tmp

# --- test-entry.sh classification (run-test stubbed via CI_RUN_TEST) ---
mkstub 0; assert_exit "test-mode none -> skip 0" 0 \
  env CI_REGISTRY="$REG" CI_RUN_TEST="$STUB" bash "$ROOT/scripts/test-entry.sh" demo-advisory astro /tmp
mkstub 1; assert_exit "test failures under advisory -> 0" 0 \
  env CI_REGISTRY="$REG" CI_RUN_TEST="$STUB" bash "$ROOT/scripts/test-entry.sh" demo-gate astro /tmp
mkstub 0; assert_exit "tests clean under advisory -> 0" 0 \
  env CI_REGISTRY="$REG" CI_RUN_TEST="$STUB" bash "$ROOT/scripts/test-entry.sh" demo-gate astro /tmp
mkstub 1; assert_exit "test failures under gate -> 1" 1 \
  env CI_REGISTRY="$REG" CI_RUN_TEST="$STUB" bash "$ROOT/scripts/test-entry.sh" demo-testgate astro /tmp

# --- sync-config.sh ---
TT="$(mktemp -d)"
assert_exit "sync greenfield writes config -> 0" 0 \
  env CI_REGISTRY="$REG" CI_ROOT="$ROOT" bash "$ROOT/scripts/sync-config.sh" demo-gate "$TT"
[ -f "$TT/.prettierrc.json" ] && ok "config written" || no "config written"
assert_exit "sync --check in-sync -> 0" 0 \
  env CI_REGISTRY="$REG" CI_ROOT="$ROOT" bash "$ROOT/scripts/sync-config.sh" demo-gate "$TT" --check
printf '{"x":1}\n' > "$TT/.prettierrc.json"
assert_exit "sync --check drift -> 1" 1 \
  env CI_REGISTRY="$REG" CI_ROOT="$ROOT" bash "$ROOT/scripts/sync-config.sh" demo-gate "$TT" --check
assert_exit "sync --update overwrites drift -> 0" 0 \
  env CI_REGISTRY="$REG" CI_ROOT="$ROOT" bash "$ROOT/scripts/sync-config.sh" demo-gate "$TT" --update
TT2="$(mktemp -d)"
assert_exit "sync --check absent -> 2" 2 \
  env CI_REGISTRY="$REG" CI_ROOT="$ROOT" bash "$ROOT/scripts/sync-config.sh" demo-gate "$TT2" --check
assert_exit "sync unregistered -> 3" 3 \
  env CI_REGISTRY="$REG" CI_ROOT="$ROOT" bash "$ROOT/scripts/sync-config.sh" nope "$TT"

echo "---"; echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
