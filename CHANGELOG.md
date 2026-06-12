# Changelog

All notable changes to the devils-advocate plugin. Format follows [Keep a Changelog](https://keepachangelog.com/); versions follow [SemVer](https://semver.org/). Older releases (pre-3.0) predate this file — see git history.

## [Unreleased]

### Fixed

- v3.3.1's drift guards only covered SKILL.md — README.md and plugin/CLAUDE.md, two of the three files the dimension bug actually shipped in, were unguarded. Found by the plugin's own independent critique (check #15, `tests-exist` FAIL). Four new checks verify the dimension/criteria counts stated in both files against the headers counted from SKILL.md (consistency suite at 42; 169 deterministic total). Guard verified by seeded regression: flipping README back to "8 dimensions" fails the suite.

## [3.3.1] — 2026-06-11

### Fixed

- **Code criteria span 7 dimensions, not 8.** The wrong count shipped in README.md, SKILL.md, and plugin/CLAUDE.md since v3.2.0 (whose release notes, ironically, claimed to fix an off-by-one in the *plan* count). Four new consistency checks now count the actual dimension headers in both criteria blocks and verify the prose labels match (consistency suite at 38 checks; 165 deterministic total).

### Changed

- README refresh: architecture-drift detection folded into the main feature prose (was a stale "New in v3.2" callout), added an all-pass verdict example, the fix → re-critique → commit loop, a "How It's Tested" section, and a CHANGELOG link.

## [3.3.0] — 2026-06-11

### Changed

- **Dispatch template is now self-contained.** The independence-gate subagent prompt includes the full session-log instructions (find the next check number, append-preserving format, SHA + timestamp) — previously the subagent never saw Step 5 and could write a malformed log.
- **No more hardcoded `model: "opus"` in the dispatch.** The subagent inherits the session's model, so the gate works on every plan and survives model generations.
- **Verification guidance is stack-agnostic.** "npm list, tsc --noEmit" replaced with "run the project's own test/build/typecheck commands."
- **Chain-of-thought applies to inline critiques too**, not just dispatched ones.

### Added

- **Fix → re-critique → commit loop.** When criteria FAIL, the critique now ends by offering to fix them and re-run — each critique authorizes exactly one commit, so the loop closes itself.
- **`--quiet` / `-q` flag** on both shell suites: print only failures and the summary. Saves a few thousand tokens every time an agent runs them.
- **Code-mode evals.** `eval.sh` now runs 6 evals (3 plan + 3 code): planted TODO stubs, planted SQL concatenation, and clean-work calibration in both modes.
- 7 new deterministic checks (suite now at 127): dispatch self-containment, no pinned model, fix-recheck rule, code fixtures present, quiet-mode behavior.

### Fixed

- The "clean plan" eval fixture wasn't clean — the eval suite itself caught a broken ESM `package.json` named import, a self-contradicting test snippet, and a missing integration-verification step. The fixture (and its code-mode sibling) now survive an honest 22-criteria review.

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
