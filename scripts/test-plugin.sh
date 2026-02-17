#!/usr/bin/env bash
# Test suite for the devils-advocate plugin.
# Run from the repo root: bash scripts/test-plugin.sh
#
# Tests go beyond check-consistency.sh by validating semantic content,
# output format templates, scoring formulas, and structural invariants.

set -euo pipefail

# Clean up temp files on exit or interrupt
cleanup() {
  rm -f .devils-advocate/config.json .devils-advocate/.commit-reviewed
}
trap cleanup EXIT

PASS=0
FAIL=0

pass() { ((PASS++)); printf "  \033[32mPASS\033[0m  %s\n" "$1"; }
fail() { ((FAIL++)); printf "  \033[31mFAIL\033[0m  %s\n" "$1"; }

echo "Devils Advocate — Test Suite"
echo "═══════════════════════════════════════"
echo ""

# ---------------------------------------------------------------------------
# 1. Plugin metadata
# ---------------------------------------------------------------------------
echo "Plugin metadata"

# plugin.json has required fields
for field in name version description; do
  if python3 -c "import json; d=json.load(open('.claude-plugin/plugin.json')); assert '$field' in d" 2>/dev/null; then
    pass "plugin.json has '$field' field"
  else
    fail "plugin.json missing '$field' field"
  fi
done

# marketplace.json has required structure
if python3 -c "
import json
d = json.load(open('.claude-plugin/marketplace.json'))
assert 'plugins' in d and len(d['plugins']) > 0
assert 'source' in d['plugins'][0]
" 2>/dev/null; then
  pass "marketplace.json has valid plugin entry with source"
else
  fail "marketplace.json missing valid plugin entry"
fi

# Plugin name matches across files
if python3 -c "
import json
p = json.load(open('.claude-plugin/plugin.json'))['name']
m = json.load(open('.claude-plugin/marketplace.json'))['plugins'][0]['name']
assert p == m, f'{p} != {m}'
" 2>/dev/null; then
  pass "plugin name matches across plugin.json and marketplace.json"
else
  fail "plugin name mismatch between plugin.json and marketplace.json"
fi
echo ""

# ---------------------------------------------------------------------------
# 2. SKILL.md frontmatter validation
# ---------------------------------------------------------------------------
echo "Skill frontmatter"

for skill_dir in skills/*/; do
  skill=$(basename "$skill_dir")
  file="$skill_dir/SKILL.md"

  # Has opening and closing frontmatter delimiters
  if head -1 "$file" | grep -q "^---$"; then
    pass "skills/$skill/SKILL.md starts with frontmatter delimiter"
  else
    fail "skills/$skill/SKILL.md missing opening frontmatter delimiter"
  fi

  # Has name field
  if sed -n '/^---$/,/^---$/p' "$file" | grep -q "^name:"; then
    pass "skills/$skill/SKILL.md has name in frontmatter"
  else
    fail "skills/$skill/SKILL.md missing name in frontmatter"
  fi

  # Has description field
  if sed -n '/^---$/,/^---$/p' "$file" | grep -q "^description:"; then
    pass "skills/$skill/SKILL.md has description in frontmatter"
  else
    fail "skills/$skill/SKILL.md missing description in frontmatter"
  fi

  # Frontmatter name matches directory name
  fm_name=$(sed -n '/^---$/,/^---$/{ /^name:/s/^name: *//p; }' "$file")
  if [ "$fm_name" = "$skill" ]; then
    pass "skills/$skill/SKILL.md frontmatter name matches directory"
  else
    fail "skills/$skill/SKILL.md frontmatter name '$fm_name' != directory '$skill'"
  fi
done
echo ""

# ---------------------------------------------------------------------------
# 3. Scoring formula consistency
# ---------------------------------------------------------------------------
echo "Scoring formula"

# All skills using the overall score formula must use the same formula
for skill in critique critique-plan second-opinion; do
  if grep -q "(average + lowest) / 2" "skills/$skill/SKILL.md"; then
    pass "skills/$skill/SKILL.md uses correct scoring formula"
  else
    fail "skills/$skill/SKILL.md missing or incorrect scoring formula"
  fi
done
echo ""

# ---------------------------------------------------------------------------
# 4. Session log format consistency
# ---------------------------------------------------------------------------
echo "Session log format"

# critique uses "Post-task" format
if grep -q "Post-task" "skills/critique/SKILL.md"; then
  pass "skills/critique/SKILL.md uses 'Post-task' log label"
else
  fail "skills/critique/SKILL.md missing 'Post-task' log label"
fi

# critique-plan uses "Plan critique" format
if grep -q "Plan critique" "skills/critique-plan/SKILL.md"; then
  pass "skills/critique-plan/SKILL.md uses 'Plan critique' log label"
else
  fail "skills/critique-plan/SKILL.md missing 'Plan critique' log label"
fi

# second-opinion uses "Second opinion" format
if grep -q "Second opinion" "skills/second-opinion/SKILL.md"; then
  pass "skills/second-opinion/SKILL.md uses 'Second opinion' log label"
else
  fail "skills/second-opinion/SKILL.md missing 'Second opinion' log label"
fi

# pre uses "Pre-task" format
if grep -q "Pre-task" "skills/pre/SKILL.md"; then
  pass "skills/pre/SKILL.md uses 'Pre-task' log label"
else
  fail "skills/pre/SKILL.md missing 'Pre-task' log label"
fi

# All scoring skills reference git SHA in session log
for skill in critique critique-plan second-opinion pre; do
  if grep -q "git rev-parse --short HEAD" "skills/$skill/SKILL.md"; then
    pass "skills/$skill/SKILL.md references git SHA for session log"
  else
    fail "skills/$skill/SKILL.md missing git SHA reference in session log"
  fi
done
echo ""

# ---------------------------------------------------------------------------
# 5. Output format templates — required sections
# ---------------------------------------------------------------------------
echo "Output format templates"

# critique and second-opinion must have the same scored dimensions
CRITIQUE_DIMS="Correctness Completeness Assumptions Fragility Security Testing Architecture"
for dim in $CRITIQUE_DIMS; do
  for skill in critique second-opinion; do
    if grep -q "$dim:" "skills/$skill/SKILL.md"; then
      pass "skills/$skill/SKILL.md output has $dim dimension"
    else
      fail "skills/$skill/SKILL.md output missing $dim dimension"
    fi
  done
done

# critique-plan has its own dimension set
PLAN_DIMS="Completeness Feasibility Gaps Overscoping Security Architecture"
for dim in $PLAN_DIMS; do
  if grep -q "$dim:" "skills/critique-plan/SKILL.md"; then
    pass "skills/critique-plan/SKILL.md output has $dim dimension"
  else
    fail "skills/critique-plan/SKILL.md output missing $dim dimension"
  fi
done

# pre has its own dimension set
PRE_DIMS="Clarity Feasibility"
for dim in $PRE_DIMS; do
  if grep -q "$dim:" "skills/pre/SKILL.md"; then
    pass "skills/pre/SKILL.md output has $dim dimension"
  else
    fail "skills/pre/SKILL.md output missing $dim dimension"
  fi
done

# All scoring skills have "Overall Score" or "Forecast" in output
for skill in critique critique-plan second-opinion; do
  if grep -q "Overall Score:" "skills/$skill/SKILL.md"; then
    pass "skills/$skill/SKILL.md output has Overall Score"
  else
    fail "skills/$skill/SKILL.md output missing Overall Score"
  fi
done

if grep -q "Forecast:" "skills/pre/SKILL.md"; then
  pass "skills/pre/SKILL.md output has Forecast"
else
  fail "skills/pre/SKILL.md output missing Forecast"
fi

# Conditional Standards Compliance in post-work skills
for skill in critique critique-plan second-opinion; do
  if grep -q "Standards Compliance" "skills/$skill/SKILL.md"; then
    pass "skills/$skill/SKILL.md has conditional Standards Compliance"
  else
    fail "skills/$skill/SKILL.md missing Standards Compliance dimension"
  fi
done

# Reinvention Risk output section
for skill in critique critique-plan second-opinion pre; do
  if grep -qi "Reinvention Risk" "skills/$skill/SKILL.md"; then
    pass "skills/$skill/SKILL.md has Reinvention Risk output section"
  else
    fail "skills/$skill/SKILL.md missing Reinvention Risk output section"
  fi
done
echo ""

# ---------------------------------------------------------------------------
# 6. Output section parity (critique vs second-opinion)
# ---------------------------------------------------------------------------
echo "Output section parity"

# Sections that must appear in both critique and second-opinion output formats
OUTPUT_SECTIONS="Strengths Weaknesses"
for section in $OUTPUT_SECTIONS; do
  for skill in critique second-opinion; do
    if grep -q "^${section}:" "skills/$skill/SKILL.md"; then
      pass "skills/$skill/SKILL.md output has $section section"
    else
      fail "skills/$skill/SKILL.md output missing $section section"
    fi
  done
done

# Skeptical Take in both
for skill in critique second-opinion; do
  if grep -q "^Skeptical Take:" "skills/$skill/SKILL.md"; then
    pass "skills/$skill/SKILL.md output has Skeptical Take section"
  else
    fail "skills/$skill/SKILL.md output missing Skeptical Take section"
  fi
done
echo ""

# ---------------------------------------------------------------------------
# 7. Hook validation
# ---------------------------------------------------------------------------
echo "Hook validation"

# hooks.json has PreToolUse hook
if python3 -c "
import json
d = json.load(open('hooks/hooks.json'))
assert 'hooks' in d and 'PreToolUse' in d['hooks']
" 2>/dev/null; then
  pass "hooks.json has PreToolUse hook"
else
  fail "hooks.json missing PreToolUse hook"
fi

# PreToolUse hook has Bash matcher
if python3 -c "
import json
d = json.load(open('hooks/hooks.json'))
assert d['hooks']['PreToolUse'][0]['matcher'] == 'Bash'
" 2>/dev/null; then
  pass "PreToolUse hook matches on Bash tool"
else
  fail "PreToolUse hook missing Bash matcher"
fi

# hooks.json has PostToolUse hook
if python3 -c "
import json
d = json.load(open('hooks/hooks.json'))
assert 'hooks' in d and 'PostToolUse' in d['hooks']
" 2>/dev/null; then
  pass "hooks.json has PostToolUse hook"
else
  fail "hooks.json missing PostToolUse hook"
fi

# PostToolUse hook has Write matcher
if python3 -c "
import json
d = json.load(open('hooks/hooks.json'))
assert d['hooks']['PostToolUse'][0]['matcher'] == 'Write'
" 2>/dev/null; then
  pass "PostToolUse hook matches on Write tool"
else
  fail "PostToolUse hook missing Write matcher"
fi

# All hook commands have safe fallback (|| true)
HOOK_COUNT=$(grep -c "|| true" "hooks/hooks.json")
COMMAND_COUNT=$(grep -c '"command":' "hooks/hooks.json")
if [ "$HOOK_COUNT" -eq "$COMMAND_COUNT" ]; then
  pass "all hook commands have safe fallback (|| true) ($HOOK_COUNT/$COMMAND_COUNT)"
else
  fail "not all hook commands have safe fallback ($HOOK_COUNT/$COMMAND_COUNT)"
fi

# Hook commands reference the plugin name
if grep -q "devils-advocate" "hooks/hooks.json" || grep -q "Devil" "hooks/hooks.json"; then
  pass "hook commands reference plugin name"
else
  fail "hook commands missing plugin name reference"
fi

# PostToolUse hook references critique-plan command
if python3 -c "
import json
d = json.load(open('hooks/hooks.json'))
cmd = d['hooks']['PostToolUse'][0]['hooks'][0]['command']
assert 'critique-plan' in cmd
" 2>/dev/null; then
  pass "PostToolUse hook suggests critique-plan command"
else
  fail "PostToolUse hook missing critique-plan suggestion"
fi

# PostToolUse hook: fires on plan file path
POST_CMD=$(python3 -c "import json; print(json.load(open('hooks/hooks.json'))['hooks']['PostToolUse'][0]['hooks'][0]['command'])")

POST_MATCH=$(echo '{"tool_input":{"file_path":"/tmp/plans/design.md"}}' | eval "$POST_CMD" 2>&1)
if echo "$POST_MATCH" | grep -q "Plan file written"; then
  pass "PostToolUse hook fires on plan file path"
else
  fail "PostToolUse hook silent on plan file path"
fi

# PostToolUse hook: silent on non-plan file path
POST_NOMATCH=$(echo '{"tool_input":{"file_path":"/tmp/src/index.ts"}}' | eval "$POST_CMD" 2>&1)
if [ -z "$POST_NOMATCH" ]; then
  pass "PostToolUse hook silent on non-plan file path"
else
  fail "PostToolUse hook fired on non-plan file path"
fi

# PostToolUse hook: handles missing stdin gracefully
POST_EMPTY=$(echo '{}' | eval "$POST_CMD" 2>&1)
if [ $? -eq 0 ]; then
  pass "PostToolUse hook handles empty input gracefully"
else
  fail "PostToolUse hook crashes on empty input"
fi

# PreToolUse hook: warns on git commit without marker (non-blocking)
PRE_CMD=$(python3 -c "import json; print(json.load(open('hooks/hooks.json'))['hooks']['PreToolUse'][0]['hooks'][0]['command'])")
rm -f .devils-advocate/.commit-reviewed

PRE_WARN=$(echo '{"tool_input":{"command":"git commit -m \"test\""}}' | eval "$PRE_CMD" 2>/dev/null)
PRE_STDERR=$(echo '{"tool_input":{"command":"git commit -m \"test\""}}' | eval "$PRE_CMD" 2>&1 >/dev/null)
if echo "$PRE_STDERR" | grep -q "No critique found"; then
  pass "PreToolUse hook warns on git commit without marker"
else
  fail "PreToolUse hook silent on git commit without marker"
fi

# PreToolUse hook: does NOT block (no JSON decision on stdout)
if [ -z "$PRE_WARN" ]; then
  pass "PreToolUse hook does not block commit (warning only)"
else
  fail "PreToolUse hook outputs to stdout (would block): $PRE_WARN"
fi

# PreToolUse hook: silent when marker exists (critique already run)
mkdir -p .devils-advocate
touch .devils-advocate/.commit-reviewed
PRE_QUIET_STDERR=$(echo '{"tool_input":{"command":"git commit -m \"test\""}}' | eval "$PRE_CMD" 2>&1 >/dev/null)
PRE_QUIET_STDOUT=$(echo '{"tool_input":{"command":"git commit -m \"test\""}}' | eval "$PRE_CMD" 2>/dev/null)
# Need to recreate marker since previous call consumed it
touch .devils-advocate/.commit-reviewed
PRE_ALL=$(echo '{"tool_input":{"command":"git commit -m \"test\""}}' | eval "$PRE_CMD" 2>&1)
if ! echo "$PRE_ALL" | grep -q "No critique found"; then
  pass "PreToolUse hook silent when marker exists"
else
  fail "PreToolUse hook warned despite marker"
fi

# PreToolUse hook: removes marker after allowing commit
if [ ! -f .devils-advocate/.commit-reviewed ]; then
  pass "PreToolUse hook removes marker after allowing commit"
else
  fail "PreToolUse hook did not remove marker after allowing commit"
  rm -f .devils-advocate/.commit-reviewed
fi

# PreToolUse hook: silent on non-commit commands
PRE_SILENT=$(echo '{"tool_input":{"command":"npm test"}}' | eval "$PRE_CMD" 2>&1)
if [ -z "$PRE_SILENT" ]; then
  pass "PreToolUse hook silent on non-commit commands"
else
  fail "PreToolUse hook fired on non-commit command"
fi

# PreToolUse hook: warns on git commit --amend without marker
PRE_AMEND=$(echo '{"tool_input":{"command":"git commit --amend"}}' | eval "$PRE_CMD" 2>&1 >/dev/null)
if echo "$PRE_AMEND" | grep -q "No critique found"; then
  pass "PreToolUse hook warns on git commit --amend without marker"
else
  fail "PreToolUse hook silent on git commit --amend without marker"
fi

# PreToolUse hook: handles empty input gracefully
PRE_EMPTY=$(echo '{}' | eval "$PRE_CMD" 2>&1)
if [ $? -eq 0 ]; then
  pass "PreToolUse hook handles empty input gracefully"
else
  fail "PreToolUse hook crashes on empty input"
fi

# Commit-approved marker instruction in scoring skills
for skill in critique critique-plan second-opinion; do
  if grep -q "commit-reviewed" "skills/$skill/SKILL.md"; then
    pass "skills/$skill/SKILL.md creates commit-reviewed marker"
  else
    fail "skills/$skill/SKILL.md missing commit-reviewed marker instruction"
  fi
done

# Hook config: all hooks respect disabled config
mkdir -p .devils-advocate
echo '{"hooks":{"pre-commit-warning":false,"plan-file-detect":false}}' > .devils-advocate/config.json

PRE_DISABLED=$(echo '{"tool_input":{"command":"git commit -m \"test\""}}' | eval "$PRE_CMD" 2>&1)
if [ -z "$PRE_DISABLED" ]; then
  pass "PreToolUse hook respects disabled config"
else
  fail "PreToolUse hook ignores disabled config"
fi

POST_DISABLED=$(echo '{"tool_input":{"file_path":"/tmp/plans/test.md"}}' | eval "$POST_CMD" 2>&1)
if [ -z "$POST_DISABLED" ]; then
  pass "PostToolUse hook respects disabled config"
else
  fail "PostToolUse hook ignores disabled config"
fi

# Hook config: hooks ON when config file missing
rm -f .devils-advocate/config.json

PRE_DEFAULT=$(echo '{"tool_input":{"command":"git commit -m \"test\""}}' | eval "$PRE_CMD" 2>&1 >/dev/null)
if echo "$(echo '{"tool_input":{"command":"git commit -m \"test\""}}' | eval "$PRE_CMD" 2>&1)" | grep -q "No critique found"; then
  pass "PreToolUse hook defaults to enabled without config"
else
  fail "PreToolUse hook defaults to disabled without config"
fi

# Hook config: hooks ON when key missing from config
echo '{"hooks":{}}' > .devils-advocate/config.json
PRE_MISSING_KEY=$(echo '{"tool_input":{"command":"git commit -m \"test\""}}' | eval "$PRE_CMD" 2>&1)
if echo "$PRE_MISSING_KEY" | grep -q "No critique found"; then
  pass "PreToolUse hook defaults to enabled when key missing"
else
  fail "PreToolUse hook disabled when key missing"
fi

rm -f .devils-advocate/config.json .devils-advocate/.commit-reviewed
echo ""

# ---------------------------------------------------------------------------
# 7. Standards discovery consistency
# ---------------------------------------------------------------------------
echo "Standards discovery"

# All scoring skills check for CLAUDE.md and AGENTS.md
for skill in critique critique-plan second-opinion pre; do
  if grep -q "CLAUDE.md" "skills/$skill/SKILL.md" && grep -q "AGENTS.md" "skills/$skill/SKILL.md"; then
    pass "skills/$skill/SKILL.md checks for CLAUDE.md and AGENTS.md"
  else
    fail "skills/$skill/SKILL.md missing CLAUDE.md/AGENTS.md check"
  fi
done

# All scoring skills search for ADR files
for skill in critique critique-plan second-opinion pre; do
  if grep -qi "ADR" "skills/$skill/SKILL.md"; then
    pass "skills/$skill/SKILL.md searches for ADR files"
  else
    fail "skills/$skill/SKILL.md missing ADR search"
  fi
done
echo ""

# ---------------------------------------------------------------------------
# 8. Evidence requirement
# ---------------------------------------------------------------------------
echo "Evidence requirement"

# Post-work skills require file:line evidence
for skill in critique second-opinion; do
  if grep -q 'file:line' "skills/$skill/SKILL.md"; then
    pass "skills/$skill/SKILL.md requires file:line evidence"
  else
    fail "skills/$skill/SKILL.md missing file:line evidence requirement"
  fi
done
echo ""

# ---------------------------------------------------------------------------
# 9. Context gate refusal format
# ---------------------------------------------------------------------------
echo "Context gate refusal format"

# All gated skills have CONTEXT INSUFFICIENT output
for skill in critique critique-plan second-opinion pre; do
  if grep -q "CONTEXT INSUFFICIENT" "skills/$skill/SKILL.md"; then
    pass "skills/$skill/SKILL.md has CONTEXT INSUFFICIENT refusal block"
  else
    fail "skills/$skill/SKILL.md missing CONTEXT INSUFFICIENT refusal block"
  fi
done
echo ""

# ---------------------------------------------------------------------------
# 10. CLAUDE.md accuracy — verify documented conventions match reality
# ---------------------------------------------------------------------------
echo "CLAUDE.md accuracy"

# CLAUDE.md says 5 skills exist — verify
EXPECTED_SKILLS="critique critique-plan log pre second-opinion"
ACTUAL_SKILLS=$(ls -d skills/*/ 2>/dev/null | xargs -I{} basename {} | sort | tr '\n' ' ' | sed 's/ $//')
if [ "$ACTUAL_SKILLS" = "$EXPECTED_SKILLS" ]; then
  pass "skill directories match CLAUDE.md documentation"
else
  fail "skill directories ($ACTUAL_SKILLS) don't match expected ($EXPECTED_SKILLS)"
fi

# CLAUDE.md says hook is in hooks/hooks.json
if [ -f "hooks/hooks.json" ]; then
  pass "hooks/hooks.json exists as documented in CLAUDE.md"
else
  fail "hooks/hooks.json missing (documented in CLAUDE.md)"
fi

# CLAUDE.md says version source of truth is plugin.json
if [ -f ".claude-plugin/plugin.json" ]; then
  pass "plugin.json exists as documented in CLAUDE.md"
else
  fail "plugin.json missing (documented in CLAUDE.md)"
fi

# banner.png referenced in README exists
if [ -f "banner.png" ]; then
  pass "banner.png exists (referenced in README.md)"
else
  fail "banner.png missing (referenced in README.md)"
fi
echo ""

# ---------------------------------------------------------------------------
# 11. Score threshold documentation
# ---------------------------------------------------------------------------
echo "Score threshold"

# All post-work skills document the < 80 threshold for suggestions
for skill in critique critique-plan second-opinion; do
  if grep -q "Score < 80" "skills/$skill/SKILL.md" || grep -q "score < 80" "skills/$skill/SKILL.md"; then
    pass "skills/$skill/SKILL.md documents < 80 improvement threshold"
  else
    fail "skills/$skill/SKILL.md missing < 80 improvement threshold"
  fi
done
echo ""

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo "═══════════════════════════════════════"
printf "Results: \033[32m%d passed\033[0m" "$PASS"
if [ "$FAIL" -gt 0 ]; then
  printf ", \033[31m%d failed\033[0m" "$FAIL"
fi
echo ""

exit "$FAIL"
