#!/usr/bin/env bash
# LLM-based eval suite for the devils-advocate critique skill.
# Uses `claude -p` with the current session's auth — no API key needed.
# Run from the repo root: bash plugin/scripts/eval.sh
#
# All 6 evals (3 plan-mode, 3 code-mode) run in parallel — wall-clock time is
# the slowest single eval (~2-5 min).
# Each eval sends a self-contained fixture through the critique skill and asserts
# on the output. --disallowedTools Bash prevents the model from running shell
# commands against the DA repo's filesystem, which causes hangs on fixtures that
# mention test commands.

set -euo pipefail

cd "$(dirname "$0")/.."

SKILL=$(cat skills/critique/SKILL.md)
TMPDIR_EVAL=$(mktemp -d)
# Counters must exist before the EXIT trap is installed — under set -u an
# early abort would otherwise fire cleanup() with them unbound, masking the
# real error.
PASS=0
FAIL=0
ERRORS=0
# Keep output on failure for inspection; clean up only on success
cleanup() { [ "$FAIL" -eq 0 ] && [ "$ERRORS" -eq 0 ] && rm -rf "$TMPDIR_EVAL" || echo "  (raw outputs kept at $TMPDIR_EVAL/)"; }
trap cleanup EXIT

run_plan_critique() {
  local fixture=$1
  claude -p \
    --disallowedTools Bash \
    --system-prompt "$SKILL" \
    "Critique this plan (treat it as a plan critique):

$(cat "$fixture")

IMPORTANT FOR THIS EVAL: Output ONLY the formatted DEVIL'S ADVOCATE CRITIQUE block with criterion-by-criterion PASS/FAIL lines. Skip Step 5 (session log write) entirely." 2>/dev/null
}

run_code_critique() {
  local fixture=$1
  claude -p \
    --disallowedTools Bash \
    --system-prompt "$SKILL" \
    "Critique this code change (treat it as a code critique):

$(cat "$fixture")

IMPORTANT FOR THIS EVAL: Output ONLY the formatted DEVIL'S ADVOCATE CRITIQUE block with criterion-by-criterion PASS/FAIL lines. Skip Step 5 (session log write) entirely." 2>/dev/null
}

# ---------------------------------------------------------------------------
# Launch all evals in parallel
# ---------------------------------------------------------------------------

echo "Devils Advocate — LLM Eval Suite"
echo "═══════════════════════════════════════"
echo "Launching evals in parallel..."
echo ""

# Eval 1: plan with TODO placeholder → no-placeholders FAIL
(run_plan_critique "tests/fixtures/plan-with-placeholder.md" > "$TMPDIR_EVAL/eval1.out" 2>&1) &
PID1=$!

# Eval 2: plan with SQL string interpolation → input-validated FAIL
(run_plan_critique "tests/fixtures/plan-unvalidated-input.md" > "$TMPDIR_EVAL/eval2.out" 2>&1) &
PID2=$!

# Eval 3: clean plan → ≥20/22 PASS (model not manufacturing failures)
(run_plan_critique "tests/fixtures/plan-clean.md" > "$TMPDIR_EVAL/eval3.out" 2>&1) &
PID3=$!

# Eval 4: code with TODO stubs → no-placeholders FAIL
(run_code_critique "tests/fixtures/code-with-placeholder.md" > "$TMPDIR_EVAL/eval4.out" 2>&1) &
PID4=$!

# Eval 5: code with SQL string concatenation → injection criteria FAIL
(run_code_critique "tests/fixtures/code-unvalidated-input.md" > "$TMPDIR_EVAL/eval5.out" 2>&1) &
PID5=$!

# Eval 6: clean code → ≥18/20 PASS (slack for criteria the model can't verify
# without Bash, e.g. actually running the tests)
(run_code_critique "tests/fixtures/code-clean.md" > "$TMPDIR_EVAL/eval6.out" 2>&1) &
PID6=$!

# Wait for all. A failed claude call must not abort the script under set -e —
# the empty-output check in the assert helpers reports it as ERROR instead.
wait $PID1 $PID2 $PID3 $PID4 $PID5 $PID6 || true
echo "All evals complete. Checking results..."
echo ""

# ---------------------------------------------------------------------------
# Assert helpers — write results to a shared log (parallel-safe via append)
# ---------------------------------------------------------------------------

# POSIX-safe increments: ((VAR++)) returns exit status 1 when VAR is 0,
# which kills the script under set -e on bash >= 4.1 (Linux/CI).
pass()  { PASS=$((PASS+1));     printf "  \033[32mPASS\033[0m  %s\n" "$1"; }
fail()  { FAIL=$((FAIL+1));     printf "  \033[31mFAIL\033[0m  %s\n" "$1"; }
error() { ERRORS=$((ERRORS+1)); printf "  \033[33mERROR\033[0m %s\n" "$1"; }

debug_output() {
  local file=$1
  echo "         --- raw output (first 30 lines) ---"
  head -30 "$file" | sed 's/^/         /'
  echo "         ---"
}

assert_fail() {
  local file=$1 criterion=$2 label=$3
  local result
  result=$(cat "$file")
  if [ -z "$result" ]; then
    error "$label — empty response"
    return
  fi
  # Match criterion ID with FAIL in any order/spacing, OR criterion in backticks
  if echo "$result" | grep -qiE "${criterion}[. ]+FAIL|FAIL[. ]+${criterion}|${criterion}.*FAIL|\`${criterion}\`.*FAIL|FAIL.*\`${criterion}\`"; then
    pass "$label"
  else
    fail "$label — expected $criterion FAIL, not found"
    debug_output "$file"
  fi
}

assert_verdict() {
  local file=$1 verdict=$2 label=$3
  local result
  result=$(cat "$file")
  if [ -z "$result" ]; then
    error "$label — empty response"
    return
  fi
  if echo "$result" | grep -q "VERDICT: $verdict"; then
    pass "$label"
  else
    fail "$label — expected 'VERDICT: $verdict' not found"
    debug_output "$file"
  fi
}

assert_min_pass() {
  local file=$1 threshold=$2 total=$3 label=$4
  local result result_line passed
  result=$(cat "$file")
  if [ -z "$result" ]; then
    error "$label — empty response"
    return
  fi
  result_line=$(echo "$result" | grep -oE "Result: [0-9]+/${total} PASS" | head -1)
  passed=$(echo "$result_line" | grep -oE "^Result: [0-9]+" | grep -oE "[0-9]+$")
  if [ -n "$passed" ] && [ "$passed" -ge "$threshold" ]; then
    pass "$label (${passed}/${total} PASS ≥ ${threshold})"
  else
    fail "$label — expected ≥${threshold}/${total} PASS, got: ${result_line:-not found}"
    debug_output "$file"
  fi
}

# ---------------------------------------------------------------------------
# Evaluate results
# ---------------------------------------------------------------------------

echo "Eval 1: plan-with-placeholder"
assert_fail "$TMPDIR_EVAL/eval1.out" "no-placeholders" "catches TODO placeholder (no-placeholders FAIL)"
echo ""

echo "Eval 2: plan-with-unvalidated-input"
assert_fail "$TMPDIR_EVAL/eval2.out" "input-validated" "catches SQL string interpolation (input-validated FAIL)"
echo ""

echo "Eval 3: plan-clean"
assert_min_pass "$TMPDIR_EVAL/eval3.out" "20" "22" "clean plan passes ≥20/22 (not manufacturing failures)"
echo ""

echo "Eval 4: code-with-placeholder"
assert_fail "$TMPDIR_EVAL/eval4.out" "no-placeholders" "catches TODO stubs in code (no-placeholders FAIL)"
echo ""

echo "Eval 5: code-with-unvalidated-input"
assert_fail "$TMPDIR_EVAL/eval5.out" "(no-injection|input-validated)" "catches SQL concatenation in code (injection criteria FAIL)"
echo ""

echo "Eval 6: code-clean"
assert_min_pass "$TMPDIR_EVAL/eval6.out" "18" "20" "clean code passes ≥18/20 (not manufacturing failures)"
echo ""

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo "═══════════════════════════════════════"
printf "Results: \033[32m%d passed\033[0m" "$PASS"
if [ "$FAIL" -gt 0 ]; then
  printf ", \033[31m%d failed\033[0m" "$FAIL"
fi
if [ "$ERRORS" -gt 0 ]; then
  printf ", \033[33m%d errors\033[0m" "$ERRORS"
fi
echo ""

exit "$FAIL"
