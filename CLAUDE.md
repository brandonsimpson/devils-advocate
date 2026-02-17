# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Claude Code plugin** that adds adversarial self-critique capabilities. It's a prompt-only plugin — no build step, no dependencies, no compiled code. The entire plugin is Markdown skill files and a shell hook.

## Architecture

The plugin follows the Claude Code plugin structure:

- **`.claude-plugin/plugin.json`** — Plugin metadata (name, version, description). Version here is the source of truth.
- **`.claude-plugin/marketplace.json`** — Marketplace registry entry for `brandonsimpson/devils-advocate`. Version must stay in sync with `plugin.json`.
- **`skills/`** — Each subdirectory contains a `SKILL.md` file that defines a slash command:
  - `critique/` → `/devils-advocate:critique` — Post-task adversarial scoring across 7 dimensions
  - `pre/` → `/devils-advocate:pre` — Pre-task feasibility forecast
  - `critique-plan/` → `/devils-advocate:critique-plan <path>` — Plan document review
  - `second-opinion/` → `/devils-advocate:second-opinion` — Independent re-evaluation of prior critique
  - `log/` → `/devils-advocate:log` — Display session history
- **`hooks/hooks.json`** — Registers a `Stop` hook with an inline command that reminds users to run critique when uncommitted changes exist

## Key Conventions

- **SKILL.md frontmatter** — Each skill has YAML frontmatter with `name` and `description`. The `description` field must be short enough to avoid `ENAMETOOLONG` errors during plugin installation (this was a real bug — see commit `b381119`).
- **Session log** — All skills that produce scores append entries to `.devils-advocate/session.md` in the user's project (not this repo). Entries include git SHA, timestamp, and check number. The log skill only reads, never writes.
- **Scope-bounded critique** — Skills explicitly instruct Claude to only critique what was requested, never penalize for out-of-scope features. Testing and security are the two exceptions that are always evaluated.
- **Context gates** — The `critique`, `pre`, and `critique-plan` skills have a Step 0 that refuses to produce scores if Claude lacks sufficient context. This prevents false-confidence scoring.
- **Evidence requirement** — Critique scores must cite `file:line` references. Scores without evidence are invalid.
- **Version syncing** — When bumping versions, update both `plugin.json` and `marketplace.json`.

## Working in This Repo

There is no build, lint, or test command. Changes are validated by:
1. Reading the skill Markdown for correctness
2. Installing the plugin locally and invoking the slash commands
3. Checking that `hooks.json` is valid JSON

To test locally: install the plugin via `claude --plugin-dir .` from this directory, then invoke commands like `/devils-advocate:critique` in a project with code changes.

## Historical Context

This plugin was renamed from `confidence-loops` / `confidence-loop` to `devils-advocate`. The `.confidence-loop/` directory contains legacy session data from before the rename. The `docs/` directory (gitignored) contains original design and implementation plans.
