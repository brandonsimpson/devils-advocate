# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Claude Code plugin** that adds adversarial self-critique capabilities. It's a prompt-only plugin — no build step, no dependencies, no compiled code. The entire plugin is Markdown skill files and a shell hook.

## Architecture

The plugin follows the Claude Code plugin structure:

- **`.claude-plugin/plugin.json`** — Plugin metadata (name, version, description). Version here is the source of truth.
- **`.claude-plugin/marketplace.json`** — Marketplace registry entry for `brandonsimpson/devils-advocate`. Version must stay in sync with `plugin.json`.
- **`skills/`** — Each subdirectory contains a `SKILL.md` file that defines a slash command:
  - `critique/` → `/devils-advocate:critique` — Post-task adversarial scoring across 7 dimensions (+ conditional Standards Compliance)
  - `pre/` → `/devils-advocate:pre` — Pre-task feasibility forecast
  - `critique-plan/` → `/devils-advocate:critique-plan <path>` — Plan document review
  - `second-opinion/` → `/devils-advocate:second-opinion` — Independent re-evaluation of prior critique
  - `log/` → `/devils-advocate:log` — Display session history
- **`hooks/hooks.json`** — Registers a `Stop` hook with an inline command that reminds users to run critique when uncommitted changes exist

## Key Conventions

- **SKILL.md frontmatter** — Each skill has YAML frontmatter with `name` and `description`. The `description` field must be short enough to avoid `ENAMETOOLONG` errors during plugin installation (this was a real bug — see commit `b381119`).
- **Session log** — All skills that produce scores append entries to `.devils-advocate/session.md` in the user's project (not this repo). Entries include git SHA, timestamp, and check number. The log skill only reads, never writes.
- **Scope-bounded critique** — Skills explicitly instruct Claude to only critique what was requested, never penalize for out-of-scope features. Testing, security, and standards compliance are the three exceptions that are always evaluated (standards compliance only when standards files exist).
- **Standards discovery** — All four scoring skills (`critique`, `critique-plan`, `second-opinion`, `pre`) include a standards discovery step that reads `CLAUDE.md`, `AGENTS.md`, and searches for ADR files. The three post-work skills (`critique`, `critique-plan`, `second-opinion`) add a conditional "Standards Compliance" scoring dimension when standards are found; it is omitted entirely when no standards exist. The `pre` skill weaves discovered standards into its existing evaluations without adding a new dimension.
- **Existing patterns detection** — The `critique` and `second-opinion` skills grep for existing utilities/helpers/conventions that the critiqued code might be duplicating within the codebase.
- **Reinvention risk detection** — All four scoring skills check whether the work builds custom implementations of problems that have well-established, battle-tested solutions (e.g., hand-rolled crypto, custom auth, manual input sanitization). This is distinct from "existing patterns" which looks within the codebase — reinvention risk looks at the industry-wide landscape of solved problems.
- **ADR advisory** — When no ADR files are found in a project with 50+ commits, skills display an advisory suggesting the project adopt architectural decision records.
- **Context gates** — All four scoring skills (`critique`, `pre`, `critique-plan`, `second-opinion`) have a Step 0 that refuses to produce scores if Claude lacks sufficient context. The `second-opinion` gate additionally verifies a prior critique exists in the session log. This prevents false-confidence scoring.
- **Evidence requirement** — Critique scores must cite `file:line` references. Scores without evidence are invalid. Standards Compliance scores must cite both the standard source and the drifting code.
- **Version syncing** — When bumping versions, update both `plugin.json` and `marketplace.json`.

## Working in This Repo

Changes are validated by:
1. Running `bash scripts/check-consistency.sh` — automated checks for JSON validity, version sync, cross-skill consistency (calibration anchors, context gates, reinvention risk, unverified sections, scope-bounded critique, session log references), and frontmatter description lengths
2. Reading the skill Markdown for correctness
3. Installing the plugin locally and invoking the slash commands

To test locally: install the plugin via `claude --plugin-dir .` from this directory, then invoke commands like `/devils-advocate:critique` in a project with code changes.

## Historical Context

This plugin was renamed from `confidence-loops` / `confidence-loop` to `devils-advocate`. The `.confidence-loop/` directory contains legacy session data from before the rename. The `docs/` directory (gitignored) contains original design and implementation plans.
