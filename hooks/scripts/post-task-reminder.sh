#!/bin/sh
# Post-task reminder to run devil's advocate critique
# Only shows reminder when there are uncommitted code changes
# Sandbox-safe: no writes, no network, just output

# Check for uncommitted changes (staged or unstaged)
if git status --porcelain 2>/dev/null | grep -q .; then
  echo ""
  echo "Devil's Advocate: Uncommitted changes detected. Run /devils-advocate:critique to scrutinize this solution."
  echo ""
fi
