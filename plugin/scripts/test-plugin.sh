#!/usr/bin/env bash
# Test suite for the devils-advocate plugin.
# Run from the repo root: bash plugin/scripts/test-plugin.sh
#
# Tests go beyond check-consistency.sh by validating semantic content,
# output format templates, binary criteria completeness, and structural invariants.

set -euo pipefail

# Scripts run from repo root but plugin files are in plugin/
cd "$(dirname "$0")/.."

# Clean up temp files on exit or interrupt
cleanup() {
  rm -f .devils-advocate/config.json .devils-advocate/.commit-reviewed
}
trap cleanup EXIT

PASS=0
FAIL=0

# POSIX-safe increments: ((VAR++)) returns exit status 1 when VAR is 0,
# which kills the script under set -e on bash >= 4.1 (Linux/CI).
pass() { PASS=$((PASS+1)); printf "  \033[32mPASS\033[0m  %s\n" "$1"; }
fail() { FAIL=$((FAIL+1)); printf "  \033[31mFAIL\033[0m  %s\n" "$1"; }

echo "Devils Advocate — Test Suite"
echo "═══════════════════════════════════════"
echo ""

# ---------------------------------------------------------------------------
# 1. Plugin metadata
# ---------------------------------------------------------------------------
echo "Plugin metadata"

# plugin.json has required fields
for field in name version description; do
  if node -e "const d=JSON.parse(require('fs').readFileSync('.claude-plugin/plugin.json','utf8'));if(!('$field' in d))process.exit(1)" 2>/dev/null; then
    pass "plugin.json has '$field' field"
  else
    fail "plugin.json missing '$field' field"
  fi
done

# marketplace.json has required structure
if node -e "
const d=JSON.parse(require('fs').readFileSync('../.claude-plugin/marketplace.json','utf8'));
if(!d.plugins||!d.plugins.length||!d.plugins[0].source)process.exit(1);
" 2>/dev/null; then
  pass "marketplace.json has valid plugin entry with source"
else
  fail "marketplace.json missing valid plugin entry"
fi

# Plugin name matches across files
if node -e "
const p=JSON.parse(require('fs').readFileSync('.claude-plugin/plugin.json','utf8')).name;
const m=JSON.parse(require('fs').readFileSync('../.claude-plugin/marketplace.json','utf8')).plugins[0].name;
if(p!==m)process.exit(1);
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
# 3. Binary criteria completeness
# ---------------------------------------------------------------------------
echo "Binary criteria completeness — Code (20 criteria)"

CODE_CRITERIA="tests-pass logic-correct edge-cases no-secrets input-validated no-injection auth-enforced no-dead-code no-placeholders error-handling no-code-smell no-obvious-perf types-consistent naming-matches patterns-followed imports-correct tests-exist no-regressions boundaries-respected no-hacky-shortcuts"
for criterion in $CODE_CRITERIA; do
  if grep -q "$criterion" "skills/critique/SKILL.md"; then
    pass "code criterion: $criterion"
  else
    fail "code criterion missing: $criterion"
  fi
done
echo ""

echo "Binary criteria completeness — Plan (22 criteria)"

PLAN_CRITERIA="req-coverage no-placeholders edge-cases api-verified patterns-correct tests-per-step verification no-secrets input-validated auth-designed types-consistent naming-matches no-overengineering no-reinvention correct-order deps-available rollback-plan perf-considered imports-correct follows-patterns boundaries-respected no-hacky-shortcuts"
for criterion in $PLAN_CRITERIA; do
  if grep -q "$criterion" "skills/critique/SKILL.md"; then
    pass "plan criterion: $criterion"
  else
    fail "plan criterion missing: $criterion"
  fi
done
echo ""

# ---------------------------------------------------------------------------
# 4. Session log format
# ---------------------------------------------------------------------------
echo "Session log format"

# Critique uses "Critique" label
if grep -q "Critique" "skills/critique/SKILL.md"; then
  pass "skills/critique/SKILL.md uses 'Critique' log label"
else
  fail "skills/critique/SKILL.md missing 'Critique' log label"
fi

# References git SHA in session log
if grep -q "git rev-parse --short HEAD" "skills/critique/SKILL.md"; then
  pass "skills/critique/SKILL.md references git SHA for session log"
else
  fail "skills/critique/SKILL.md missing git SHA reference in session log"
fi

# Uses binary result format (X/Y PASS)
if grep -q "PASS" "skills/critique/SKILL.md" && grep -q "Result:" "skills/critique/SKILL.md"; then
  pass "skills/critique/SKILL.md uses binary result format"
else
  fail "skills/critique/SKILL.md missing binary result format"
fi
echo ""

# ---------------------------------------------------------------------------
# 5. Output format — required sections
# ---------------------------------------------------------------------------
echo "Output format"

# Has the binary eval header
if grep -q "Binary Eval" "skills/critique/SKILL.md"; then
  pass "output format has Binary Eval header"
else
  fail "output format missing Binary Eval header"
fi

# Has Target line
if grep -q "^Target:" "skills/critique/SKILL.md"; then
  pass "output format has Target line"
else
  fail "output format missing Target line"
fi

# Has Result line
if grep -q "^Result:" "skills/critique/SKILL.md"; then
  pass "output format has Result line"
else
  fail "output format missing Result line"
fi

# Has Failing criteria section
if grep -q "Failing criteria with fixes" "skills/critique/SKILL.md"; then
  pass "output format has Failing criteria section"
else
  fail "output format missing Failing criteria section"
fi

# Has Unverified section
if grep -q "^Unverified:" "skills/critique/SKILL.md"; then
  pass "output format has Unverified section"
else
  fail "output format missing Unverified section"
fi

# No percentage scoring remnants in output
if grep -q "Overall Score:" "skills/critique/SKILL.md"; then
  fail "output format still has percentage Overall Score"
else
  pass "output format has no percentage Overall Score"
fi

if grep -q "Skeptical Take:" "skills/critique/SKILL.md"; then
  fail "output format still has Skeptical Take (removed in v3)"
else
  pass "output format has no Skeptical Take"
fi

if grep -q "^Strengths:" "skills/critique/SKILL.md"; then
  fail "output format still has Strengths section (removed in v3)"
else
  pass "output format has no Strengths section"
fi

if grep -q "^Weaknesses:" "skills/critique/SKILL.md"; then
  fail "output format still has Weaknesses section (removed in v3)"
else
  pass "output format has no Weaknesses section"
fi
echo ""

# ---------------------------------------------------------------------------
# 6. Hook validation
# ---------------------------------------------------------------------------
echo "Hook validation"

# hooks.json has PreToolUse hook
if node -e "
const d=JSON.parse(require('fs').readFileSync('hooks/hooks.json','utf8'));
if(!d.hooks||!d.hooks.PreToolUse)process.exit(1);
" 2>/dev/null; then
  pass "hooks.json has PreToolUse hook"
else
  fail "hooks.json missing PreToolUse hook"
fi

# PreToolUse hook has Bash matcher
if node -e "
const d=JSON.parse(require('fs').readFileSync('hooks/hooks.json','utf8'));
if(d.hooks.PreToolUse[0].matcher!=='Bash')process.exit(1);
" 2>/dev/null; then
  pass "PreToolUse hook matches on Bash tool"
else
  fail "PreToolUse hook missing Bash matcher"
fi

# hooks.json has PostToolUse hook
if node -e "
const d=JSON.parse(require('fs').readFileSync('hooks/hooks.json','utf8'));
if(!d.hooks||!d.hooks.PostToolUse)process.exit(1);
" 2>/dev/null; then
  pass "hooks.json has PostToolUse hook"
else
  fail "hooks.json missing PostToolUse hook"
fi

# PostToolUse hook has Write matcher
if node -e "
const d=JSON.parse(require('fs').readFileSync('hooks/hooks.json','utf8'));
if(d.hooks.PostToolUse[0].matcher!=='Write')process.exit(1);
" 2>/dev/null; then
  pass "PostToolUse hook matches on Write tool"
else
  fail "PostToolUse hook missing Write matcher"
fi

# All hook commands use node
NODE_COUNT=$(grep -c '"command": "node -e' "hooks/hooks.json")
COMMAND_COUNT=$(grep -c '"command":' "hooks/hooks.json")
if [ "$NODE_COUNT" -eq "$COMMAND_COUNT" ]; then
  pass "all hook commands use node ($NODE_COUNT/$COMMAND_COUNT)"
else
  fail "not all hook commands use node ($NODE_COUNT/$COMMAND_COUNT)"
fi

# Hook commands reference the plugin name
if grep -q "devils-advocate" "hooks/hooks.json" || grep -q "Devil" "hooks/hooks.json"; then
  pass "hook commands reference plugin name"
else
  fail "hook commands missing plugin name reference"
fi

# PostToolUse hook references critique command (not critique-plan)
if node -e "
const d=JSON.parse(require('fs').readFileSync('hooks/hooks.json','utf8'));
const cmd=d.hooks.PostToolUse[0].hooks[0].command;
if(!cmd.includes('critique'))process.exit(1);
if(cmd.includes('critique-plan'))process.exit(1);
" 2>/dev/null; then
  pass "PostToolUse hook suggests /critique (not /critique-plan)"
else
  fail "PostToolUse hook references wrong command"
fi

# PostToolUse hook: fires on plan file path
POST_CMD=$(node -e "console.log(JSON.parse(require('fs').readFileSync('hooks/hooks.json','utf8')).hooks.PostToolUse[0].hooks[0].command)")

POST_MATCH=$(echo '{"tool_input":{"file_path":"/tmp/plans/design.md"}}' | eval "$POST_CMD" 2>&1)
if echo "$POST_MATCH" | grep -q "Plan file written"; then
  pass "PostToolUse hook fires on plan file path"
else
  fail "PostToolUse hook silent on plan file path"
fi

# PostToolUse hook: output is consumable by Claude Code (nested hookSpecificOutput
# schema — a bare top-level additionalContext field is silently ignored)
if echo "$POST_MATCH" | node -e "
let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{
const h=JSON.parse(d).hookSpecificOutput;
if(!h||h.hookEventName!=='PostToolUse'||!h.additionalContext)process.exit(1);
})" 2>/dev/null; then
  pass "PostToolUse hook output uses hookSpecificOutput schema"
else
  fail "PostToolUse hook output not consumable by Claude Code: $POST_MATCH"
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
PRE_CMD=$(node -e "console.log(JSON.parse(require('fs').readFileSync('hooks/hooks.json','utf8')).hooks.PreToolUse[0].hooks[0].command)")
rm -f .devils-advocate/.commit-reviewed

PRE_STDOUT=$(echo '{"tool_input":{"command":"git commit -m \"test\""}}' | eval "$PRE_CMD" 2>/dev/null)
if echo "$PRE_STDOUT" | grep -q "No critique found"; then
  pass "PreToolUse hook warns on git commit without marker"
else
  fail "PreToolUse hook silent on git commit without marker"
fi

# PreToolUse hook: does NOT block (uses additionalContext, not permissionDecision deny)
if echo "$PRE_STDOUT" | grep -q "additionalContext" && ! echo "$PRE_STDOUT" | grep -q '"permissionDecision":"deny"'; then
  pass "PreToolUse hook does not block commit (warning only)"
else
  fail "PreToolUse hook missing additionalContext or has deny decision: $PRE_STDOUT"
fi

# PreToolUse hook: silent when marker exists (critique already run)
mkdir -p .devils-advocate
touch .devils-advocate/.commit-reviewed
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
PRE_AMEND=$(echo '{"tool_input":{"command":"git commit --amend"}}' | eval "$PRE_CMD" 2>/dev/null)
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

# Commit-approved marker instruction in critique skill
if grep -q "commit-reviewed" "skills/critique/SKILL.md"; then
  pass "skills/critique/SKILL.md creates commit-reviewed marker"
else
  fail "skills/critique/SKILL.md missing commit-reviewed marker instruction"
fi

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

# Hook config: hooks degrade gracefully on malformed config.json
echo 'NOT VALID JSON{{{' > .devils-advocate/config.json

PRE_MALFORMED=$(echo '{"tool_input":{"command":"git commit -m \"test\""}}' | eval "$PRE_CMD" 2>&1)
if echo "$PRE_MALFORMED" | grep -q "No critique found"; then
  pass "PreToolUse hook degrades gracefully on malformed config.json"
else
  fail "PreToolUse hook crashes on malformed config.json"
fi

POST_MALFORMED=$(echo '{"tool_input":{"file_path":"/tmp/plans/test.md"}}' | eval "$POST_CMD" 2>&1)
if echo "$POST_MALFORMED" | grep -q "critique"; then
  pass "PostToolUse hook degrades gracefully on malformed config.json"
else
  fail "PostToolUse hook crashes on malformed config.json"
fi

rm -f .devils-advocate/config.json .devils-advocate/.commit-reviewed
echo ""

# ---------------------------------------------------------------------------
# 7. Standards discovery
# ---------------------------------------------------------------------------
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

# Enhanced discovery
if grep -q "Architectural domain" "skills/critique/SKILL.md"; then
  pass "skills/critique/SKILL.md has architectural domain discovery step"
else
  fail "skills/critique/SKILL.md missing architectural domain discovery step"
fi

if grep -q "Dominant patterns" "skills/critique/SKILL.md"; then
  pass "skills/critique/SKILL.md has dominant pattern detection step"
else
  fail "skills/critique/SKILL.md missing dominant pattern detection step"
fi

if grep -q "Boundary markers" "skills/critique/SKILL.md"; then
  pass "skills/critique/SKILL.md has boundary marker detection step"
else
  fail "skills/critique/SKILL.md missing boundary marker detection step"
fi
echo ""

# ---------------------------------------------------------------------------
# 8. Evidence requirement
# ---------------------------------------------------------------------------
echo "Evidence requirement"

if grep -q 'file:line' "skills/critique/SKILL.md"; then
  pass "skills/critique/SKILL.md requires file:line evidence"
else
  fail "skills/critique/SKILL.md missing file:line evidence requirement"
fi
echo ""

# ---------------------------------------------------------------------------
# 9. Independence gate and context gate
# ---------------------------------------------------------------------------
echo "Independence gate"

if grep -q "Independence Gate" "skills/critique/SKILL.md"; then
  pass "skills/critique/SKILL.md has Independence Gate"
else
  fail "skills/critique/SKILL.md missing Independence Gate"
fi

if grep -q "subagent" "skills/critique/SKILL.md"; then
  pass "skills/critique/SKILL.md has subagent dispatch instruction"
else
  fail "skills/critique/SKILL.md missing subagent dispatch instruction"
fi

if grep -q "author bias" "skills/critique/SKILL.md"; then
  pass "skills/critique/SKILL.md explains author bias rationale"
else
  fail "skills/critique/SKILL.md missing author bias rationale"
fi
echo ""

echo "Context gate refusal format"

if grep -q "CONTEXT INSUFFICIENT" "skills/critique/SKILL.md"; then
  pass "skills/critique/SKILL.md has CONTEXT INSUFFICIENT refusal block"
else
  fail "skills/critique/SKILL.md missing CONTEXT INSUFFICIENT refusal block"
fi
echo ""

# ---------------------------------------------------------------------------
# 10. CLAUDE.md accuracy — verify documented conventions match reality
# ---------------------------------------------------------------------------
echo "CLAUDE.md accuracy"

# CLAUDE.md says 2 skills exist — verify
EXPECTED_SKILLS="critique log"
ACTUAL_SKILLS=$(ls -d skills/*/ 2>/dev/null | xargs -I{} basename {} | sort | tr '\n' ' ' | sed 's/ $//')
if [ "$ACTUAL_SKILLS" = "$EXPECTED_SKILLS" ]; then
  pass "skill directories match CLAUDE.md documentation"
else
  fail "skill directories ($ACTUAL_SKILLS) don't match expected ($EXPECTED_SKILLS)"
fi

# hooks/hooks.json exists as documented
if [ -f "hooks/hooks.json" ]; then
  pass "hooks/hooks.json exists as documented in CLAUDE.md"
else
  fail "hooks/hooks.json missing (documented in CLAUDE.md)"
fi

# plugin.json exists as documented
if [ -f ".claude-plugin/plugin.json" ]; then
  pass "plugin.json exists as documented in CLAUDE.md"
else
  fail "plugin.json missing (documented in CLAUDE.md)"
fi

# banner.png referenced in README exists
if [ -f "../banner.png" ]; then
  pass "banner.png exists (referenced in README.md)"
else
  fail "banner.png missing (referenced in README.md)"
fi
echo ""

# ---------------------------------------------------------------------------
# 11. Individual log file instructions
# ---------------------------------------------------------------------------
echo "Individual log file instructions"

if grep -q "also write the full formatted" "skills/critique/SKILL.md"; then
  pass "skills/critique/SKILL.md has log file write instruction"
else
  fail "skills/critique/SKILL.md missing log file write instruction"
fi

if grep -q "check-{N}-critique-{YYYY-MM-DD}" "skills/critique/SKILL.md"; then
  pass "skills/critique/SKILL.md uses correct log slug 'critique'"
else
  fail "skills/critique/SKILL.md has wrong log slug"
fi

if grep -q "{YYYY-MM-DD}-{HHMM}.md" "skills/critique/SKILL.md"; then
  pass "skills/critique/SKILL.md uses {YYYY-MM-DD}-{HHMM}.md timestamp format"
else
  fail "skills/critique/SKILL.md uses inconsistent timestamp format"
fi

if grep -q 'Create the .* directory if' "skills/critique/SKILL.md"; then
  pass "skills/critique/SKILL.md has logs/ directory creation instruction"
else
  fail "skills/critique/SKILL.md missing logs/ directory creation instruction"
fi
echo ""

# ---------------------------------------------------------------------------
# 12. Auto-detection
# ---------------------------------------------------------------------------
echo "Auto-detection"

if grep -qi "Target Detection" "skills/critique/SKILL.md" || grep -qi "auto-detect\|Determine whether" "skills/critique/SKILL.md"; then
  pass "skills/critique/SKILL.md has target auto-detection"
else
  fail "skills/critique/SKILL.md missing target auto-detection"
fi
echo ""

# ---------------------------------------------------------------------------
# 13. Architecture dimension
# ---------------------------------------------------------------------------
echo "Architecture dimension"

if grep -q "Architecture:" "skills/critique/SKILL.md"; then
  pass "skills/critique/SKILL.md has Architecture dimension"
else
  fail "skills/critique/SKILL.md missing Architecture dimension"
fi

# Architecture dimension appears in both code and plan criteria
ARCH_COUNT=$(grep -c "^Architecture:" "skills/critique/SKILL.md" || true)
if [ "$ARCH_COUNT" -ge 2 ]; then
  pass "Architecture dimension present in both code and plan criteria"
else
  fail "Architecture dimension only appears $ARCH_COUNT time(s), expected 2+"
fi
echo ""

# ---------------------------------------------------------------------------
# 14. CoT instruction and verdict quality
# ---------------------------------------------------------------------------
echo "CoT instruction and verdict quality"

# Dispatch prompt includes CoT instruction
if grep -q "think step by step before marking it PASS or FAIL" "skills/critique/SKILL.md"; then
  pass "dispatch prompt includes CoT instruction"
else
  fail "dispatch prompt missing CoT instruction"
fi

# READY TO SHIP verdict present (code mode)
if grep -q "READY TO SHIP" "skills/critique/SKILL.md"; then
  pass "skills/critique/SKILL.md has READY TO SHIP verdict"
else
  fail "skills/critique/SKILL.md missing READY TO SHIP verdict"
fi

# APPROVED verdict present (plan mode)
if grep -q "VERDICT: APPROVED" "skills/critique/SKILL.md"; then
  pass "skills/critique/SKILL.md has APPROVED verdict for plans"
else
  fail "skills/critique/SKILL.md missing APPROVED verdict for plans"
fi

# Verdicts are mode-specific (not generic)
if grep -q "READY TO SHIP.*code" "skills/critique/SKILL.md" || grep -q "Code critique.*READY TO SHIP\|READY TO SHIP.*20 criteria" "skills/critique/SKILL.md"; then
  pass "READY TO SHIP verdict scoped to code critiques"
else
  fail "READY TO SHIP verdict not scoped to code critiques"
fi

if grep -q "Plan critique.*APPROVED\|APPROVED.*22 criteria" "skills/critique/SKILL.md"; then
  pass "APPROVED verdict scoped to plan critiques"
else
  fail "APPROVED verdict not scoped to plan critiques"
fi

# Anti-manufacturing rule present
if grep -q "do not manufacture\|Do not manufacture" "skills/critique/SKILL.md"; then
  pass "skills/critique/SKILL.md has anti-manufacturing rule"
else
  fail "skills/critique/SKILL.md missing anti-manufacturing rule"
fi

# do-nothing is valid
if grep -q '"do nothing" is a valid' "skills/critique/SKILL.md"; then
  pass "skills/critique/SKILL.md documents that all-pass is a valid outcome"
else
  fail "skills/critique/SKILL.md missing 'do nothing is valid' rule"
fi
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
