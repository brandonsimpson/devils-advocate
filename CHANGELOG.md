# Changelog

All notable changes to the devils-advocate plugin. Format follows [Keep a Changelog](https://keepachangelog.com/); versions follow [SemVer](https://semver.org/). Older releases (pre-3.0) predate this file — see git history.

## [3.2.1] — 2026-06-10

### Fixed

- **plan-file-detect hook output was silently ignored by Claude Code.** The hook emitted a bare top-level `additionalContext` field; Claude Code only consumes the nested `hookSpecificOutput.additionalContext` shape. The "suggests critique when you write a plan file" feature now actually works.
- **Test scripts died on bash ≥ 4.1.** `((VAR++))` returns exit status 1 when the counter is 0, which kills the script under `set -e` on Linux and CI runners (macOS bash 3.2 masks the bug). All counters now use `VAR=$((VAR+1))`.
- **README manual install instructions were broken.** `--plugin-dir` now points at the `plugin/` subdirectory (where the manifest actually lives), and the nonexistent `settings.json` `"plugins"` key was replaced with the supported skills-directory symlink.
- Corrupted U+FFFD characters in the log skill's output template.
- Plugin keywords updated (`confidence`/`scoring` were leftovers from the pre-3.0 percentage-scoring era).

### Added

- **All-pass verdicts.** A clean critique now ends with an explicit verdict — `READY TO SHIP` for code, `APPROVED` for plans — plus a rule against manufacturing problems to appear thorough.
- **Chain-of-thought dispatch.** The independence-gate subagent is instructed to think step by step before marking each criterion PASS or FAIL.
- **LLM eval suite** (`plugin/scripts/eval.sh`): live `claude -p` evals that feed planted fixtures through the critique skill and assert it catches the planted bugs (TODO placeholder, SQL interpolation) without manufacturing failures on a clean plan.
- Hook-output schema test: `test-plugin.sh` now parses hook stdout and asserts the Claude Code-consumable `hookSpecificOutput` shape. Test suite now at 120 checks, up from 112 in v3.2.0.

## [3.2.0] — 2026-04-11

### Added

- **Architecture dimension** in both criteria sets: `boundaries-respected` (service layers, API boundaries, module interfaces) and `no-hacky-shortcuts` (symptom-fixing, special-case conditionals, bypassing existing systems).
- `no-code-smell` criterion (god classes, feature envy, leaky abstractions).
- Enhanced standards discovery: dominant-pattern mining (5+ instances = established pattern, enforced even if undocumented) and boundary marker detection.
- Code criteria 17 → 20; plan criteria 19 → 22.

## [3.1.0] — 2026-04-08

### Added

- **Independence gate.** Critiquing work written in the same conversation dispatches an independent subagent — the reviewer sees only the artifact and codebase, never the author's reasoning. Falls back to inline critique with a bias warning if the Agent tool is unavailable.

## [3.0.0] — 2026-04-04

### Changed

- **Binary pass/fail evaluation replaces 0-100 scoring** (breaking). Every criterion is PASS or FAIL with `file:line` evidence and a `Fix:` suggestion — no percentage scores.
- Four skills (`critique`, `critique-plan`, `pre`, `second-opinion`) consolidated into a single `critique` skill with code/plan auto-detection.
