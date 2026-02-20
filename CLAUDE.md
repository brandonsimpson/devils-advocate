# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Structure

This repo has two layers:

- **Repo root** — Marketplace registry (`.claude-plugin/marketplace.json`) plus README, LICENSE, and banner
- **`plugin/`** — The actual plugin (skills, hooks, scripts, metadata)

The marketplace points to the plugin via `"source": "./plugin"`. This separation prevents the circular cache loop that occurs when a marketplace and plugin share the same directory.

## Getting Started

See `plugin/CLAUDE.md` for full project documentation including architecture, conventions, and how to validate changes.

## Quick Reference

- **Run consistency checks:** `bash plugin/scripts/check-consistency.sh`
- **Run test suite:** `bash plugin/scripts/test-plugin.sh`
- **Test locally:** `claude --plugin-dir ./plugin`
- **Version source of truth:** `plugin/.claude-plugin/plugin.json` (must stay in sync with `.claude-plugin/marketplace.json`)
