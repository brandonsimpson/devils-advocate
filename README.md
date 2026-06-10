<p align="center">
  <img src="banner.png" alt="Devil's Advocate" width="100%">
</p>

# devils-advocate

Claude's harshest critic. A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) plugin that critiques Claude's work with binary pass/fail evaluation — every criterion either passes or fails, no percentage scores, no wiggle room.

## Why

Claude writes code confidently. Too confidently. Left unchecked, it'll tell you everything looks wonderful right up until production catches fire. Inspired by [Confidently Wrong](https://brandon.cc/confidently-wrong).

A [devil's advocate](https://en.wikipedia.org/wiki/Devil%27s_advocate) argues against a position not because they believe the other side, but to surface the holes everyone else missed. This plugin gives Claude that role — the skeptical colleague who says "yeah, but what about..." instead of "LGTM."

Every criterion demands `file:line` evidence and a fix suggestion — no hand-waving, no vibes-based reviews.

## What it catches

It'll flag you for reinventing bcrypt, missing authorization checks, duplicating a helper that already exists three directories away, writing plans where step 4 depends on step 7, N+1 queries in hot paths, and shipping without a rollback strategy. It knows when you're hand-rolling auth instead of using a battle-tested library, and it won't let you forget that "works on my machine" isn't a testing strategy.

New in v3.2: it catches **architectural drift** — when Claude bypasses an established API layer to hit a database directly, adds special-case conditionals instead of proper abstractions, or papers over a root cause with a band-aid fix. It mines your codebase for dominant patterns and enforces them, even if they're not documented.

It works on both code and plans — auto-detecting which criteria set to use based on what you're reviewing.

## Install

```
/plugin marketplace add brandonsimpson/devils-advocate
/plugin install devils-advocate@devils-advocate
```

<details>
<summary>Manual install</summary>

```bash
git clone https://github.com/brandonsimpson/devils-advocate.git
```

Single session — note the `/plugin` suffix; the plugin lives in the `plugin/` subdirectory, not the repo root:

```bash
claude --plugin-dir ./devils-advocate/plugin
```

Permanent — link the plugin into your skills directory and it loads every session as `devils-advocate@skills-dir`:

```bash
ln -s "$(pwd)/devils-advocate/plugin" ~/.claude/skills/devils-advocate
```

</details>

## Commands

| Slash command | Natural language |
|---|---|
| `/devils-advocate:critique` | "critique" or "critique this plan" |
| `/devils-advocate:log` | "show critique log" |

### `/devils-advocate:critique`

Binary pass/fail critique across every dimension that matters. Auto-detects whether you're reviewing code or a plan document.

**Independence gate:** When critiquing work Claude wrote in the same conversation, it automatically dispatches an independent subagent to avoid author bias — the reviewer never sees the author's reasoning, only the artifact and codebase.

**Code critique (20 criteria, 8 dimensions):**

- **Correctness** — Tests pass? Logic correct? Edge cases handled?
- **Security** — No hardcoded secrets, input validated, no injection vectors, auth enforced?
- **Quality** — No dead code, no placeholders, errors handled properly, no code smell?
- **Performance** — No N+1 queries, no O(n^2) in hot paths?
- **Consistency** — Types match, naming follows conventions, patterns followed?
- **Integration** — Imports resolve, tests exist, no regressions?
- **Architecture** — Established boundaries respected, no hacky shortcuts?

**Plan critique (22 criteria, 10 dimensions):**

- **Completeness** — Requirements covered, no placeholders, edge cases addressed?
- **Correctness** — APIs verified against docs, patterns match library usage?
- **Testability** — Specific tests per step, E2E verification strategy?
- **Security** — Secrets managed properly, input validated, auth designed?
- **Consistency** — Types consistent, naming follows conventions?
- **Simplicity** — No overengineering, no reinventing solved problems?
- **Dependencies** — Correct task ordering, all deps available?
- **Resilience** — Rollback plan exists, performance considered?
- **Integration** — Import paths valid, follows project patterns?
- **Architecture** — Established boundaries respected, no hacky shortcuts?

Every FAIL comes with a `Fix:` suggestion. Example output:

```
DEVIL'S ADVOCATE CRITIQUE (Binary Eval)
═══════════════════════════════════════

Target: code changes for webhook handler

  Correctness:
    tests-pass ...... PASS
    logic-correct ... PASS
    edge-cases ...... FAIL — No handling for empty payload at webhook.ts:45.
                      Fix: Add early return with 400 status for empty/malformed payloads.

  Security:
    no-secrets ...... PASS
    input-validated . FAIL — String interpolation in buildQuery() at db.ts:23.
                      Fix: Use parameterized query builder.
    no-injection .... FAIL — innerHTML used at dashboard.tsx:89.
                      Fix: Use textContent or a sanitization library.
    auth-enforced ... PASS

  ...

Result: 15/20 PASS — 5 criteria need fixing

Failing criteria with fixes:
1. edge-cases: Add early return for empty payloads at webhook.ts:45
2. input-validated: Use parameterized queries at db.ts:23
3. no-injection: Replace innerHTML at dashboard.tsx:89
4. ...
```

### `/devils-advocate:log`

Session history — total checks, pass rate trend, and git SHA linking each check to a specific commit. Individual critiques are saved to `.devils-advocate/logs/` for later reference.

## Standards & Project Awareness

The critique skill automatically discovers your project's documented standards before evaluating:

- **`CLAUDE.md` / `AGENTS.md`** — Your conventions, required patterns, and constraints. Standards violations cause relevant criteria to FAIL.
- **ADR files** — Searched in `docs/adr/`, `docs/decisions/`, `adr/`, `decisions/`, `doc/architecture/decisions/`, and `**/ADR-*.md`
- **Existing patterns** — Utilities, helpers, and conventions already in your codebase that the critiqued code might be duplicating.
- **Architectural boundaries** — Barrel exports, API client modules, repository patterns, and service layers that indicate intentional boundaries. If 5+ instances in your codebase do something one way, that's the established pattern — violations fail even if undocumented.

## Session Log & Hooks

Every check is logged to `.devils-advocate/session.md` with a git SHA, so you can correlate results with specific commits. Full critique output is saved to individual files in `.devils-advocate/logs/`. Add `.devils-advocate/` to your `.gitignore`.

A pre-commit hook nudges you to run a critique before committing — the commit still proceeds, it's just a reminder. A plan-file hook suggests running `/devils-advocate:critique` when you write a plan file. Both hooks are configurable via `.devils-advocate/config.json`:

```json
{"hooks": {"pre-commit-warning": false, "plan-file-detect": false}}
```

## License

MIT
