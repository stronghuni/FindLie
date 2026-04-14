# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

FindLie is **not an application** — it's a distributable skill pack for AI coding agents (Claude Code, Codex, Cursor, Factory, Gemini, etc.). Its "code" is Markdown: three `SKILL.md` files plus a shared `references/` directory. There is no build step, no test suite, no package manager. Changes ship by updating Markdown and running `./setup`.

## Commands

```bash
./setup                    # auto-detect installed agents and symlink skills into each
./setup --host claude      # install only to ~/.claude/skills
./setup --host codex       # ~/.codex/skills
./setup --help             # list supported hosts: claude, codex, cursor, factory, slate, kiro, opencode
```

`setup` is idempotent — it creates symlinks (`ln -sfn`) from each agent's `skills/` directory back to this repo. Edits to `find-lie/SKILL.md` etc. take effect immediately in any agent that has been set up; no reinstall needed.

There are no lint/test/build commands. Validation is manual: run the skill itself (`/find-lie`, `/lie-scan`, `/lie-deep`) inside an installed agent against a real codebase.

## Architecture

Three skills, one shared reference library:

- **`lie-scan/`** — fast (~30s) static-pattern scan. `rg` only, no semantic analysis. For pre-commit / CI.
- **`find-lie/`** — standard 6-phase analysis: static patterns → semantic/intent → integration → tests → redundancy/dead code → promise fulfillment. The default.
- **`lie-deep/`** — exhaustive forensic scan (~10–30 min). Runs tests, full import graph, duplicate hashing.

All three share `references/`:
- `patterns.md` — regex detection patterns by lie type
- `checklist.md` — manual verification steps
- `severity.md` — **authoritative** Trust Score formula, confidence-adjustment rules, and verdict thresholds. Any severity/scoring logic belongs here, not inlined into skills.

The `setup` script symlinks `references/` into each agent's skills dir as `findlie-references/` so skills can read it at runtime.

### Lie taxonomy (10 types)

Mock Data, Stub, No-op, Deceptive Return, Intent Mismatch, Disconnected Integration, Test Deception, Duplicate Code, Redundant Files, Dead Code. Each finding is tagged with one type and one severity (CRITICAL / WARNING / REDUNDANCY / DEAD / INFO). See `README.md` for the full table.

### SKILL.md format

Each `SKILL.md` starts with YAML frontmatter (`name`, `version`, `description`, `allowed-tools`) and contains step-by-step instructions the host agent executes directly. The `description` field is what triggers auto-invocation — keep trigger phrases (e.g., "find lies", "audit code") in it when editing.

## Editing conventions

- When adding a new detection pattern: update `references/patterns.md` **and** the relevant phase section in `find-lie/SKILL.md` / `lie-scan/SKILL.md` / `lie-deep/SKILL.md`. These are duplicated by design (skills must be self-contained for agents that don't follow symlinks reliably) but must stay in sync.
- When changing severity rules or the Trust Score formula: edit `references/severity.md` only. Skills reference it by path.
- Keep `rg` invocations portable — they run inside whatever shell the host agent provides. Always `--glob '!**/node_modules/**'` and exclude test/mock/fixture dirs for non-test scans, or false-positive rate tanks user trust.
- The `AGENTS.md` file documents per-host install steps and must be updated when `setup` gains a new `--host` target.
