# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Claude Code plugin** that adds adversarial self-critique capabilities. It's a prompt-only plugin — no build step, no dependencies, no compiled code. The entire plugin is Markdown skill files and Node.js hooks.

## Architecture

The plugin follows the Claude Code plugin structure:

- **`plugin/.claude-plugin/plugin.json`** — Plugin metadata (name, version, description). Version here is the source of truth.
- **`.claude-plugin/marketplace.json`** — Marketplace registry entry (lives at repo root, not inside `plugin/`). Source points to `./plugin`. Version must stay in sync with `plugin.json`.
- **`skills/`** — Each subdirectory contains a `SKILL.md` file that defines a slash command:
  - `critique/` → `/devils-advocate:critique` — Binary pass/fail critique of code or plan documents. Auto-detects target type. 20 criteria for code (8 dimensions), 22 criteria for plans (10 dimensions).
  - `log/` → `/devils-advocate:log` — Display session history
- **`hooks/HOOKS.md`** — Companion documentation explaining the inline hook logic step-by-step (hooks are `node -e` one-liners due to plugin path constraints).
- **`hooks/hooks.json`** — Registers two hooks:
  - `PreToolUse` hook (Bash, key: `pre-commit-warning`) — prints a non-blocking warning on `git commit` if no `.devils-advocate/.commit-reviewed` marker exists, nudging the user to run critique first. The commit proceeds regardless. The marker is created by the critique skill after writing the session log and consumed (deleted) on the next commit, suppressing the warning when critique has already been performed.
  - `PostToolUse` hook (Write, key: `plan-file-detect`) — detects when a plan file is written (matching paths with `plan`/`plans` in the name or directory) and suggests running `/devils-advocate:critique`
  - All hooks are **configurable** via `.devils-advocate/config.json` in the user's project. All hooks are on by default. To disable a hook, set its key to `false` under `hooks`: `{"hooks":{"pre-commit-warning":false}}`

## Key Conventions

- **Binary evaluation** — All critiques use binary pass/fail per criterion. No percentage scores. Each criterion either PASS or FAIL. Every FAIL must cite `file:line` evidence and include a `Fix:` suggestion.
- **Two criteria sets** — Code critiques use 20 criteria across 8 dimensions (Correctness, Security, Quality, Performance, Consistency, Integration, Architecture). Plan critiques use 22 criteria across 10 dimensions (Completeness, Correctness, Testability, Security, Consistency, Simplicity, Dependencies, Resilience, Integration, Architecture).
- **Auto-detection** — The critique skill determines whether it's reviewing code or a plan based on conversation context. No explicit mode flag needed.
- **SKILL.md frontmatter** — Each skill has YAML frontmatter with `name` and `description`. The `description` field must be short enough to avoid `ENAMETOOLONG` errors during plugin installation (this was a real bug — see commit `b381119`).
- **Session log** — The critique skill appends entries to `.devils-advocate/session.md` in the user's project (not this repo). Entries include git SHA, timestamp, check number, and pass count. The log skill only reads, never writes.
- **Individual log files** — The critique skill also writes the full formatted output to `.devils-advocate/logs/check-{N}-critique-{YYYY-MM-DD}-{HHMM}.md`. This preserves the complete critique for later reference. The log skill lists available log files.
- **Scope-bounded critique** — The critique skill only evaluates what was requested, never penalizes for out-of-scope features. If a criterion doesn't apply, it's marked PASS with a note.
- **Standards discovery** — The critique skill reads `CLAUDE.md`, `AGENTS.md`, and searches for ADR files. Standards violations cause relevant criteria to FAIL.
- **Existing patterns detection** — In code mode, the critique skill greps for existing utilities/helpers/conventions that the critiqued code might be duplicating.
- **Architecture enforcement** — The critique skill checks for architectural boundary violations (service layers, API boundaries, module interfaces) and hacky shortcuts (symptom-fixing, special-case conditionals, bypassing existing systems). Pattern discovery is code-enforced: if 5+ instances in the codebase do something one way, that's the established pattern regardless of documentation.
- **Independence gate** — When critiquing your own work (same conversation), the critique skill dispatches an independent subagent to avoid author bias. Falls back to inline critique with a bias warning if the Agent tool is unavailable.
- **Context gate** — The critique skill refuses to produce results if it lacks sufficient context. This prevents false-confidence scoring.
- **Evidence requirement** — Every FAIL must cite `file:line` references. Results without evidence are invalid.
- **Unverified section** — Mandatory in every critique. Must list at least one thing not checked.
- **Version syncing** — When bumping versions, update both `plugin.json` and `marketplace.json`.

## Working in This Repo

Changes are validated by:
1. Running `bash plugin/scripts/check-consistency.sh` — automated checks for JSON validity, version sync, binary criteria presence, context gate, unverified section, session log references, evidence requirements, and frontmatter description lengths
2. Running `bash plugin/scripts/test-plugin.sh` — deeper test suite covering plugin metadata, frontmatter validation, binary criteria completeness, session log format, output format structure, hook validation, standards discovery, context gate refusal format, and CLAUDE.md accuracy
3. Running `bash plugin/scripts/eval.sh` — live-LLM evals (via `claude -p`, ~2-5 min, costs tokens) that feed planted-bug fixtures from `plugin/tests/fixtures/` through the critique skill and assert it catches them without manufacturing failures on clean work. **Required after any change to `skills/critique/SKILL.md`** — the deterministic suites test what the skill says; evals test what the model does.
4. Reading the skill Markdown for correctness
5. Installing the plugin locally and invoking the slash commands

Both shell suites support `--quiet` / `-q` (print only failures and the summary) — prefer it when running them from an agent to save tokens.

To test locally: install the plugin via `claude --plugin-dir ./plugin` from the repo root, then invoke commands like `/devils-advocate:critique` in a project with code changes.

## Historical Context

This plugin was renamed from `confidence-loops` / `confidence-loop` to `devils-advocate`. The `.confidence-loop/` directory contains legacy session data from before the rename. The `docs/` directory (gitignored) contains original design and implementation plans.

v3.0.0 consolidated four scoring skills (`critique`, `critique-plan`, `pre`, `second-opinion`) into a single `critique` skill with binary pass/fail evaluation. Percentage scoring was removed entirely. The `pre` skill was unused, `second-opinion` existed to compensate for lenient percentage scoring (which binary eval solves), and `critique-plan` was folded into `critique` via auto-detection.
