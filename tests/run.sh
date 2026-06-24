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

STUB="$(mktemp)"; chmod +x "$STUB"
mkstub() { printf '#!/usr/bin/env bash\nexit %s\n' "$1" > "$STUB"; }

# --- lint-entry.sh: mode passed as 3rd arg; run-lint stubbed via CI_RUN_LINT ---
mkstub 0; assert_exit "lint clean under gate -> 0" 0 \
  env CI_RUN_LINT="$STUB" bash "$ROOT/scripts/lint-entry.sh" astro /tmp gate
mkstub 1; assert_exit "lint findings under gate -> 1" 1 \
  env CI_RUN_LINT="$STUB" bash "$ROOT/scripts/lint-entry.sh" astro /tmp gate
mkstub 1; assert_exit "lint findings under advisory -> 0" 0 \
  env CI_RUN_LINT="$STUB" bash "$ROOT/scripts/lint-entry.sh" astro /tmp advisory
mkstub 2; assert_exit "lint infra under advisory -> 2 (fail loud)" 2 \
  env CI_RUN_LINT="$STUB" bash "$ROOT/scripts/lint-entry.sh" astro /tmp advisory
mkstub 1; assert_exit "lint mode none -> skip 0" 0 \
  env CI_RUN_LINT="$STUB" bash "$ROOT/scripts/lint-entry.sh" astro /tmp none
assert_exit "lint invalid mode -> 4" 4 \
  env CI_RUN_LINT="$STUB" bash "$ROOT/scripts/lint-entry.sh" astro /tmp bogus

# --- test-entry.sh: mode passed as 3rd arg; run-test stubbed via CI_RUN_TEST ---
mkstub 0; assert_exit "test mode none -> skip 0" 0 \
  env CI_RUN_TEST="$STUB" bash "$ROOT/scripts/test-entry.sh" astro /tmp none
mkstub 1; assert_exit "test failures under advisory -> 0" 0 \
  env CI_RUN_TEST="$STUB" bash "$ROOT/scripts/test-entry.sh" astro /tmp advisory
mkstub 1; assert_exit "test failures under gate -> 1" 1 \
  env CI_RUN_TEST="$STUB" bash "$ROOT/scripts/test-entry.sh" astro /tmp gate
mkstub 0; assert_exit "tests clean under gate -> 0" 0 \
  env CI_RUN_TEST="$STUB" bash "$ROOT/scripts/test-entry.sh" astro /tmp gate

# --- sync-config.sh (registry-free; canonical from CI_ROOT/configs) ---
TT="$(mktemp -d)"
assert_exit "sync greenfield writes config -> 0" 0 \
  env CI_ROOT="$ROOT" bash "$ROOT/scripts/sync-config.sh" "$TT"
[ -f "$TT/.prettierrc.json" ] && ok "config written" || no "config written"
assert_exit "sync --check in-sync -> 0" 0 \
  env CI_ROOT="$ROOT" bash "$ROOT/scripts/sync-config.sh" "$TT" --check
printf '{"x":1}\n' > "$TT/.prettierrc.json"
assert_exit "sync --check drift -> 1" 1 \
  env CI_ROOT="$ROOT" bash "$ROOT/scripts/sync-config.sh" "$TT" --check
assert_exit "sync --update overwrites drift -> 0" 0 \
  env CI_ROOT="$ROOT" bash "$ROOT/scripts/sync-config.sh" "$TT" --update
TT2="$(mktemp -d)"
assert_exit "sync --check absent -> 2" 2 \
  env CI_ROOT="$ROOT" bash "$ROOT/scripts/sync-config.sh" "$TT2" --check

# --- fixtures: prettier must pass on clean, fail on dirty ---
PCFG="$ROOT/fixtures/.prettierrc.json"
if npx --yes prettier@3.6.2 --config "$PCFG" --check "$ROOT/fixtures/astro-clean" >/dev/null 2>&1; then
  ok "prettier clean fixture passes"; else no "prettier clean fixture passes"; fi
if npx --yes prettier@3.6.2 --config "$PCFG" --check "$ROOT/fixtures/astro-dirty" >/dev/null 2>&1; then
  no "prettier dirty fixture should fail"; else ok "prettier dirty fixture fails as expected"; fi

echo "---"; echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
