# Hook Logic Reference

The commands in `hooks.json` are inline `node -e` one-liners because Claude Code hooks execute from the user's project directory, not the plugin directory — standalone scripts can't be referenced portably.

Both hooks use Node.js (guaranteed available since Claude Code requires it) instead of python3 or bash-specific constructs, minimizing platform dependencies.

This file documents the logic step-by-step.

## PreToolUse: pre-commit-warning

Matcher: `Bash` — runs before every Bash tool invocation.

```
The entire hook is a single node -e "..." command.

Step 1: Check if hook is disabled
  Reads .devils-advocate/config.json with fs.readFileSync
  If hooks['pre-commit-warning'] is false → process.exit(0)
  If config missing or key missing → continue (default: enabled)
  Wrapped in try/catch so missing config file is silently ignored

Step 2: Read tool input from stdin
  Claude Code pipes tool_input JSON on stdin
  Node reads it asynchronously via process.stdin events
  All remaining logic runs in the 'end' callback

Step 3: Check if it's a git commit
  Regex /git\s+commit/ matches: git commit, git commit -m, git commit --amend

Step 4: Check for critique marker
  If .devils-advocate/.commit-reviewed exists:
    → fs.unlinkSync removes it (consumed — one commit allowed per critique)
    → No warning printed
  If marker does NOT exist:
    → Print yellow warning to stderr via process.stderr.write (non-blocking)
    → "No critique found for uncommitted changes"

Step 5: Safe exit
  All code wrapped in try/catch — errors never propagate
  Output to stderr only — stdout would block Claude Code
```

## PostToolUse: plan-file-detect

Matcher: `Write` — runs after every Write tool invocation.

```
Step 1: Check if hook is disabled
  Same config check as pre-commit-warning
  Key: hooks['plan-file-detect']

Step 2: Read tool input from stdin
  Extracts tool_input.file_path from the JSON

Step 3: Check if path matches plan file patterns
  Regex: /plans?\/|\/plan[-_.]|[-_]plan\./i
  Matches: plans/foo.md, plan/bar.md, /my-plan.md, design_plan.md
  Does NOT match: explanation.md, planet.md, src/planner.ts

Step 4: Print suggestion
  Yellow text to stderr suggesting /devils-advocate:critique-plan <path>

Step 5: Safe exit
  All code wrapped in try/catch — errors never propagate
```

## Config mechanism

Users can disable hooks by creating `.devils-advocate/config.json` in their project:

```json
{"hooks": {"pre-commit-warning": false, "plan-file-detect": false}}
```

Behavior:
- Config file missing → all hooks enabled
- Config file exists, key missing → that hook enabled
- Config file exists, key set to false → that hook disabled

## Dependencies

Both hooks require only `node` (Node.js), which is guaranteed to be available since Claude Code itself requires it. No python3, grep, or other external dependencies.
