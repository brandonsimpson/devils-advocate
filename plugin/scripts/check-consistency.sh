#!/usr/bin/env bash
# Consistency checks for the devils-advocate plugin.
# Run from the repo root: bash plugin/scripts/check-consistency.sh

set -euo pipefail

# Scripts run from repo root but plugin files are in plugin/
cd "$(dirname "$0")/.."

PASS=0
FAIL=0
WARN=0

# --quiet / -q: suppress individual PASS lines; failures, warnings, and the
# summary still print. Saves tokens when run by an agent.
QUIET=0
if [ "${1:-}" = "--quiet" ] || [ "${1:-}" = "-q" ]; then QUIET=1; fi

# POSIX-safe increments: ((VAR++)) returns exit status 1 when VAR is 0,
# which kills the script under set -e on bash >= 4.1 (Linux/CI).
pass() { PASS=$((PASS+1)); [ "$QUIET" -eq 1 ] || printf "  \033[32mPASS\033[0m  %s\n" "$1"; }
fail() { FAIL=$((FAIL+1)); printf "  \033[31mFAIL\033[0m  %s\n" "$1"; }
warn() { WARN=$((WARN+1)); printf "  \033[33mWARN\033[0m  %s\n" "$1"; }

echo "Devils Advocate — Consistency Checks"
echo "═══════════════════════════════════════"
echo ""

# 1. JSON validity
echo "JSON validity"
if node -e "JSON.parse(require('fs').readFileSync('hooks/hooks.json','utf8'))" 2>/dev/null; then
  pass "hooks/hooks.json is valid JSON"
else
  fail "hooks/hooks.json is invalid JSON"
fi

if node -e "JSON.parse(require('fs').readFileSync('.claude-plugin/plugin.json','utf8'))" 2>/dev/null; then
  pass ".claude-plugin/plugin.json is valid JSON"
else
  fail ".claude-plugin/plugin.json is invalid JSON"
fi

if node -e "JSON.parse(require('fs').readFileSync('../.claude-plugin/marketplace.json','utf8'))" 2>/dev/null; then
  pass ".claude-plugin/marketplace.json is valid JSON"
else
  fail ".claude-plugin/marketplace.json is invalid JSON"
fi
echo ""

# 2. Version sync between plugin.json and marketplace.json
echo "Version sync"
PLUGIN_VERSION=$(node -e "console.log(JSON.parse(require('fs').readFileSync('.claude-plugin/plugin.json','utf8')).version)")
MARKETPLACE_VERSION=$(node -e "console.log(JSON.parse(require('fs').readFileSync('../.claude-plugin/marketplace.json','utf8')).plugins[0].version)")
if [ "$PLUGIN_VERSION" = "$MARKETPLACE_VERSION" ]; then
  pass "plugin.json ($PLUGIN_VERSION) matches marketplace.json ($MARKETPLACE_VERSION)"
else
  fail "plugin.json ($PLUGIN_VERSION) != marketplace.json ($MARKETPLACE_VERSION)"
fi
echo ""

# 3. Binary criteria present in critique skill
echo "Binary criteria"
if grep -q "Code Criteria" "skills/critique/SKILL.md"; then
  pass "skills/critique/SKILL.md has Code Criteria section"
else
  fail "skills/critique/SKILL.md missing Code Criteria section"
fi

if grep -q "Plan Criteria" "skills/critique/SKILL.md"; then
  pass "skills/critique/SKILL.md has Plan Criteria section"
else
  fail "skills/critique/SKILL.md missing Plan Criteria section"
fi
echo ""

# Count actual code criteria
CODE_COUNT=$(sed -n '/Code Criteria/,/Plan Criteria/{ /^ *[a-z].*—/p; }' "skills/critique/SKILL.md" | wc -l | tr -d ' ')
if [ "$CODE_COUNT" -eq 20 ]; then
  pass "code criteria count is 20"
else
  fail "code criteria count is $CODE_COUNT (expected 20)"
fi

# Count actual plan criteria
PLAN_COUNT=$(sed -n '/Plan Criteria/,/Step 5/{ /^ *[a-z].*—/p; }' "skills/critique/SKILL.md" | wc -l | tr -d ' ')
if [ "$PLAN_COUNT" -eq 22 ]; then
  pass "plan criteria count is 22"
else
  fail "plan criteria count is $PLAN_COUNT (expected 22)"
fi

# Count dimension headers (lines like "Correctness:") and verify the prose
# labels match — "8 dimensions" shipped for two releases while the block had 7
CODE_DIMS=$(sed -n '/Code Criteria/,/Plan Criteria/{ /^[A-Z][a-zA-Z]*:$/p; }' "skills/critique/SKILL.md" | wc -l | tr -d ' ')
if [ "$CODE_DIMS" -eq 7 ]; then
  pass "code dimension count is 7"
else
  fail "code dimension count is $CODE_DIMS (expected 7)"
fi

PLAN_DIMS=$(sed -n '/Plan Criteria/,/Step 5/{ /^[A-Z][a-zA-Z]*:$/p; }' "skills/critique/SKILL.md" | wc -l | tr -d ' ')
if [ "$PLAN_DIMS" -eq 10 ]; then
  pass "plan dimension count is 10"
else
  fail "plan dimension count is $PLAN_DIMS (expected 10)"
fi

if grep -q "20 criteria, 7 dimensions" "skills/critique/SKILL.md"; then
  pass "code criteria header states 7 dimensions"
else
  fail "code criteria header does not state 7 dimensions"
fi

if grep -q "22 criteria, 10 dimensions" "skills/critique/SKILL.md"; then
  pass "plan criteria header states 10 dimensions"
else
  fail "plan criteria header states wrong dimension count"
fi

# The counts are stated in prose in README and plugin CLAUDE.md too — the
# v3.2.0 bug shipped in all three files, so all three get guarded. Compare
# against the counted headers, not a second hardcoded literal. sort -u puts
# "10 dimensions" before "7 dimensions" (lexicographic).
for entry in "../README.md README.md" "CLAUDE.md plugin/CLAUDE.md"; do
  doc="${entry%% *}"; label="${entry##* }"
  STATED_DIMS=$(grep -oE "[0-9]+ dimensions" "$doc" | sort -u | tr '\n' ' ')
  if [ "$STATED_DIMS" = "${PLAN_DIMS} dimensions ${CODE_DIMS} dimensions " ]; then
    pass "$label states only ${CODE_DIMS}/${PLAN_DIMS} dimensions"
  else
    fail "$label dimension prose is '${STATED_DIMS:-none}' (expected only ${CODE_DIMS} and ${PLAN_DIMS})"
  fi
  # Presence check only — incidental mentions like "5 criteria need fixing"
  # in README's example output are legitimate, so uniqueness can't be asserted
  if grep -q "${CODE_COUNT} criteria" "$doc" && grep -q "${PLAN_COUNT} criteria" "$doc"; then
    pass "$label states ${CODE_COUNT} and ${PLAN_COUNT} criteria"
  else
    fail "$label criteria counts don't match SKILL.md (${CODE_COUNT}/${PLAN_COUNT})"
  fi
done

# Architecture dimension present in both
if grep -q "Architecture:" "skills/critique/SKILL.md"; then
  pass "skills/critique/SKILL.md has Architecture dimension"
else
  fail "skills/critique/SKILL.md missing Architecture dimension"
fi

# New criteria names present
for criterion in boundaries-respected no-hacky-shortcuts no-code-smell; do
  if grep -q "$criterion" "skills/critique/SKILL.md"; then
    pass "criterion present: $criterion"
  else
    fail "criterion missing: $criterion"
  fi
done

# 4. Unverified section
echo "Unverified section"
if grep -q "Unverified" "skills/critique/SKILL.md"; then
  pass "skills/critique/SKILL.md has Unverified section"
else
  fail "skills/critique/SKILL.md missing Unverified section"
fi
echo ""

# 5. Session log reference
echo "Session log reference"
if grep -q "session\.md" "skills/critique/SKILL.md"; then
  pass "skills/critique/SKILL.md references session.md"
else
  fail "skills/critique/SKILL.md missing session.md reference"
fi
echo ""

# 6. Independence gate and context gate
echo "Independence gate"
if grep -q "Independence Gate" "skills/critique/SKILL.md"; then
  pass "skills/critique/SKILL.md has Independence Gate"
else
  fail "skills/critique/SKILL.md missing Independence Gate"
fi

echo ""
echo "Context gate"
if grep -q "Context Gate" "skills/critique/SKILL.md"; then
  pass "skills/critique/SKILL.md has Context Gate"
else
  fail "skills/critique/SKILL.md missing Context Gate"
fi
echo ""

# 7. Frontmatter description length (warn if > 120 chars)
echo "Description lengths"
MAX_LEN=120
for skill_dir in skills/*/; do
  skill=$(basename "$skill_dir")
  desc=$(sed -n '/^---$/,/^---$/{ /^description:/s/^description: *//p; }' "$skill_dir/SKILL.md")
  len=${#desc}
  if [ "$len" -le "$MAX_LEN" ]; then
    pass "skills/$skill description ($len chars)"
  else
    warn "skills/$skill description ($len chars) — may risk ENAMETOOLONG"
  fi
done
echo ""

# 8. Scope-bounded critique
echo "Scope-bounded critique"
if grep -q "Scope-Bounded Critique" "skills/critique/SKILL.md"; then
  pass "skills/critique/SKILL.md has Scope-Bounded Critique"
else
  fail "skills/critique/SKILL.md missing Scope-Bounded Critique"
fi
echo ""

# 9. Evidence requirement (file:line)
echo "Evidence requirement"
if grep -q 'file:line' "skills/critique/SKILL.md"; then
  pass "skills/critique/SKILL.md requires file:line evidence"
else
  fail "skills/critique/SKILL.md missing file:line evidence requirement"
fi
echo ""

# 10. Individual log file instruction
echo "Individual log files"
if grep -q "devils-advocate/logs/check-" "skills/critique/SKILL.md"; then
  pass "skills/critique/SKILL.md has individual log file instruction"
else
  fail "skills/critique/SKILL.md missing individual log file instruction"
fi
echo ""

# 11. Directory creation instruction
echo "Directory creation instruction"
if grep -q "Create the.*directory.*if" "skills/critique/SKILL.md"; then
  pass "skills/critique/SKILL.md has directory creation instruction"
else
  fail "skills/critique/SKILL.md missing directory creation instruction"
fi
echo ""

# 12. Standards discovery
echo "Standards discovery"
if grep -q "CLAUDE.md" "skills/critique/SKILL.md" && grep -q "AGENTS.md" "skills/critique/SKILL.md"; then
  pass "skills/critique/SKILL.md checks for CLAUDE.md and AGENTS.md"
else
  fail "skills/critique/SKILL.md missing CLAUDE.md/AGENTS.md check"
fi

if grep -qi "ADR" "skills/critique/SKILL.md"; then
  pass "skills/critique/SKILL.md searches for ADR files"
else
  fail "skills/critique/SKILL.md missing ADR search"
fi
echo ""

# Enhanced discovery: architectural domain identification
if grep -q "Architectural domain" "skills/critique/SKILL.md"; then
  pass "skills/critique/SKILL.md has architectural domain discovery"
else
  fail "skills/critique/SKILL.md missing architectural domain discovery"
fi

# Enhanced discovery: dominant pattern detection
if grep -q "Dominant patterns" "skills/critique/SKILL.md"; then
  pass "skills/critique/SKILL.md has dominant pattern detection"
else
  fail "skills/critique/SKILL.md missing dominant pattern detection"
fi

# Enhanced discovery: boundary markers
if grep -q "Boundary markers" "skills/critique/SKILL.md"; then
  pass "skills/critique/SKILL.md has boundary marker detection"
else
  fail "skills/critique/SKILL.md missing boundary marker detection"
fi
echo ""

# 13. No deprecated skills exist
echo "Deprecated skills removed"
for skill in pre second-opinion critique-plan; do
  if [ -d "skills/$skill" ]; then
    fail "skills/$skill/ still exists (should be deleted)"
  else
    pass "skills/$skill/ correctly removed"
  fi
done
echo ""

# 14. Binary output format
echo "Binary output format"
if grep -q "PASS" "skills/critique/SKILL.md" && grep -q "FAIL" "skills/critique/SKILL.md"; then
  pass "skills/critique/SKILL.md uses PASS/FAIL binary format"
else
  fail "skills/critique/SKILL.md missing PASS/FAIL format"
fi

if grep -q "Fix:" "skills/critique/SKILL.md"; then
  pass "skills/critique/SKILL.md requires Fix: with each FAIL"
else
  fail "skills/critique/SKILL.md missing Fix: requirement"
fi
echo ""

# 15. No percentage scoring remnants
echo "No percentage scoring"
if grep -q "Calibration anchors" "skills/critique/SKILL.md"; then
  fail "skills/critique/SKILL.md still has calibration anchors (should be removed)"
else
  pass "skills/critique/SKILL.md has no calibration anchors"
fi

if grep -q "(average + lowest) / 2" "skills/critique/SKILL.md"; then
  fail "skills/critique/SKILL.md still has percentage scoring formula"
else
  pass "skills/critique/SKILL.md has no percentage scoring formula"
fi
echo ""

# Summary
echo "═══════════════════════════════════════"
printf "Results: \033[32m%d passed\033[0m" "$PASS"
if [ "$FAIL" -gt 0 ]; then
  printf ", \033[31m%d failed\033[0m" "$FAIL"
fi
if [ "$WARN" -gt 0 ]; then
  printf ", \033[33m%d warnings\033[0m" "$WARN"
fi
echo ""

exit "$FAIL"
