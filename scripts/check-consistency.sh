#!/usr/bin/env bash
# Consistency checks for the devils-advocate plugin.
# Run from the repo root: bash scripts/check-consistency.sh

set -euo pipefail

PASS=0
FAIL=0
WARN=0

pass() { ((PASS++)); printf "  \033[32mPASS\033[0m  %s\n" "$1"; }
fail() { ((FAIL++)); printf "  \033[31mFAIL\033[0m  %s\n" "$1"; }
warn() { ((WARN++)); printf "  \033[33mWARN\033[0m  %s\n" "$1"; }

echo "Devils Advocate — Consistency Checks"
echo "═══════════════════════════════════════"
echo ""

# 1. hooks.json is valid JSON
echo "JSON validity"
if python3 -c "import json; json.load(open('hooks/hooks.json'))" 2>/dev/null; then
  pass "hooks/hooks.json is valid JSON"
else
  fail "hooks/hooks.json is invalid JSON"
fi

if python3 -c "import json; json.load(open('.claude-plugin/plugin.json'))" 2>/dev/null; then
  pass ".claude-plugin/plugin.json is valid JSON"
else
  fail ".claude-plugin/plugin.json is invalid JSON"
fi

if python3 -c "import json; json.load(open('.claude-plugin/marketplace.json'))" 2>/dev/null; then
  pass ".claude-plugin/marketplace.json is valid JSON"
else
  fail ".claude-plugin/marketplace.json is invalid JSON"
fi
echo ""

# 2. Version sync between plugin.json and marketplace.json
echo "Version sync"
PLUGIN_VERSION=$(python3 -c "import json; print(json.load(open('.claude-plugin/plugin.json'))['version'])")
MARKETPLACE_VERSION=$(python3 -c "import json; print(json.load(open('.claude-plugin/marketplace.json'))['plugins'][0]['version'])")
if [ "$PLUGIN_VERSION" = "$MARKETPLACE_VERSION" ]; then
  pass "plugin.json ($PLUGIN_VERSION) matches marketplace.json ($MARKETPLACE_VERSION)"
else
  fail "plugin.json ($PLUGIN_VERSION) != marketplace.json ($MARKETPLACE_VERSION)"
fi
echo ""

# 3. All scoring skills have calibration anchors
echo "Calibration anchors"
for skill in critique critique-plan second-opinion; do
  if grep -q "Calibration anchors" "skills/$skill/SKILL.md"; then
    pass "skills/$skill/SKILL.md has calibration anchors"
  else
    fail "skills/$skill/SKILL.md missing calibration anchors"
  fi
done
echo ""

# 4. All scoring skills have Unverified section
echo "Unverified section"
for skill in critique critique-plan second-opinion pre; do
  if grep -q "Unverified" "skills/$skill/SKILL.md"; then
    pass "skills/$skill/SKILL.md has Unverified section"
  else
    fail "skills/$skill/SKILL.md missing Unverified section"
  fi
done
echo ""

# 5. All scoring skills reference session.md
echo "Session log reference"
for skill in critique critique-plan second-opinion pre; do
  if grep -q "session\.md" "skills/$skill/SKILL.md"; then
    pass "skills/$skill/SKILL.md references session.md"
  else
    fail "skills/$skill/SKILL.md missing session.md reference"
  fi
done
echo ""

# 6. All scoring skills have reinvention risk
echo "Reinvention risk"
for skill in critique critique-plan second-opinion pre; do
  if grep -qi "reinvention" "skills/$skill/SKILL.md"; then
    pass "skills/$skill/SKILL.md has reinvention risk"
  else
    fail "skills/$skill/SKILL.md missing reinvention risk"
  fi
done
echo ""

# 7. Context gates
echo "Context gates"
for skill in critique critique-plan pre second-opinion; do
  if grep -q "Context Gate" "skills/$skill/SKILL.md"; then
    pass "skills/$skill/SKILL.md has Context Gate"
  else
    fail "skills/$skill/SKILL.md missing Context Gate"
  fi
done
echo ""

# 8. Frontmatter description length (warn if > 120 chars)
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

# 9. Scope-bounded critique in post-work skills
echo "Scope-bounded critique"
for skill in critique critique-plan second-opinion; do
  if grep -q "Scope-Bounded Critique" "skills/$skill/SKILL.md"; then
    pass "skills/$skill/SKILL.md has Scope-Bounded Critique"
  else
    fail "skills/$skill/SKILL.md missing Scope-Bounded Critique"
  fi
done
echo ""

# 10. Overconfidence check in post-task critique skills
echo "Overconfidence check"
for skill in critique second-opinion; do
  if grep -q "Overconfidence check" "skills/$skill/SKILL.md"; then
    pass "skills/$skill/SKILL.md has Overconfidence check"
  else
    fail "skills/$skill/SKILL.md missing Overconfidence check"
  fi
done
echo ""

# 11. Skeptical Take in post-task critique output formats
echo "Skeptical Take"
for skill in critique second-opinion; do
  if grep -q "Skeptical Take" "skills/$skill/SKILL.md"; then
    pass "skills/$skill/SKILL.md has Skeptical Take"
  else
    fail "skills/$skill/SKILL.md missing Skeptical Take"
  fi
done
echo ""

# 12. Strengths section in post-task critique output formats
echo "Strengths section"
for skill in critique second-opinion; do
  if grep -q "^Strengths:" "skills/$skill/SKILL.md" || grep -q "^• \[strength" "skills/$skill/SKILL.md"; then
    pass "skills/$skill/SKILL.md has Strengths section"
  else
    fail "skills/$skill/SKILL.md missing Strengths section"
  fi
done
echo ""

# 13. Directory creation instruction in session log write steps
echo "Directory creation instruction"
for skill in critique critique-plan second-opinion pre; do
  if grep -q "Create the directory and file if they don't exist" "skills/$skill/SKILL.md"; then
    pass "skills/$skill/SKILL.md has directory creation instruction"
  else
    fail "skills/$skill/SKILL.md missing directory creation instruction"
  fi
done
echo ""

# 14. Calibration anchors in pre skill
echo "Pre skill calibration"
if grep -q "Calibration anchors" "skills/pre/SKILL.md"; then
  pass "skills/pre/SKILL.md has calibration anchors"
else
  fail "skills/pre/SKILL.md missing calibration anchors"
fi
echo ""

# 15. Existing patterns in critique and second-opinion
echo "Existing patterns detection"
for skill in critique second-opinion; do
  if grep -qi "Existing patterns" "skills/$skill/SKILL.md"; then
    pass "skills/$skill/SKILL.md has existing patterns detection"
  else
    fail "skills/$skill/SKILL.md missing existing patterns detection"
  fi
done
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
