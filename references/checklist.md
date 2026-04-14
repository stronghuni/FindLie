# FindLie — Verification Checklist

Use this checklist to systematically verify code authenticity.
Each section maps to a detection phase in the `/find-lie` workflow.

---

## Phase 1: Static Pattern Scan

- [ ] Run pattern scan for all 10 Types against changed files
- [ ] Exclude known false-positive directories (test, mock, fixture, seed, demo)
- [ ] Exclude files with explicit mock/fake in filename
- [ ] Report all matches with file:line, pattern matched, and severity
- [ ] Count total findings per severity level

## Phase 2: Semantic Analysis

For each function/method in changed files:
- [ ] Extract function name and body
- [ ] Look up the name pattern in `references/intent-map.md`
- [ ] If matched, verify the body contains at least one of the expected operations
- [ ] Check the **Secondary signals** list in intent-map.md:
  - Ignored parameters (declared but never referenced)
  - Constant return (same literal regardless of input)
  - Single-branch control flow (no `if`/`try`/`switch`)
  - Fake-async (`async` keyword with no `await`)

## Phase 3: Integration Verification

- [ ] List all URLs/endpoints in changed files
  - Is each URL a real domain (not localhost/example.com/placeholder)?
  - For `localhost` URLs: are they in dev-only config?
- [ ] List all environment variable references
  - Does each have a value in `.env` or `.env.example`?
  - Do any fall back to empty string silently?
- [ ] List all database/service connection strings
  - Are they real connections (not in-memory/mock)?
  - For in-memory DB: is it test-only?
- [ ] List all imports
  - Is each imported module actually used in the file?

## Phase 4: Test Integrity

- [ ] List all test files for changed code
  - Does each changed source file have corresponding tests?
- [ ] For each test case:
  - Does it assert specific values (not just `toBeDefined`)?
  - Does it test the actual function (not a mock of it)?
  - Is the test not skipped (`skip`, `todo`, `xit`, `xtest`)?
  - Does it test error/edge cases, not just happy path?
- [ ] Are there any tautological assertions? (`expect(true).toBe(true)`)
- [ ] Are there commented-out test cases?

## Phase 5: Redundancy & Dead Code

### Duplicates
- [ ] Hash all source files — any identical files?
- [ ] Compare structurally similar files (same size ±10%) — any >80% similar?
- [ ] Extract all exported names — any duplicates across files?
- [ ] Scan for 5+ line identical code blocks across files
- [ ] Check for same API route defined in multiple handlers

### Dead Code
- [ ] List all exported symbols — check if each is imported somewhere
- [ ] List all imports per file — check if each imported symbol is used in the file
- [ ] Build simplified import graph — any orphan source files?
- [ ] Scan for `return` followed by code in same block
- [ ] Scan for `if (false)` / `while (false)` blocks
- [ ] Scan for large commented-out code blocks (10+ lines)
- [ ] Scan for files with deprecated naming patterns

## Phase 6: Promise Fulfillment

- [ ] Extract stated intent from:
  - Commit messages (`git log origin/<base>..HEAD --oneline`)
  - PR description (`gh pr view --json body -q .body`)
  - TODOS.md (if exists)
  - Plan files (if exist)
- [ ] For each stated feature/fix:
  - Is there corresponding code in the diff?
  - Is the implementation complete (not a stub)?
  - Does the implementation match the description?
- [ ] For each file in the diff:
  - Is the change related to a stated intent?
  - If not, is it scope creep?

---

## Quick Reference: False Positive Rules

These patterns should NOT be flagged:

| Pattern | Why it's OK |
|---------|------------|
| Mock data in `__test__/`, `__mock__/`, `fixture/` | Test infrastructure |
| Mock data in `seed/`, `demo/`, `storybook/` | Data seeding / demos |
| `localhost` in `.env.development` | Dev config |
| `example.com` in documentation/README | Documentation |
| Empty function in interface/abstract class | Language pattern |
| `pass` in Python abstract method | Language pattern |
| `// TODO` in test files | Acceptable technical debt |
| Same filename in `src/` vs `test/` | Test mirrors source |
| Utility re-export (barrel file) | Module organization pattern |
