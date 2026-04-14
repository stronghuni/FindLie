# FindLie — Severity Classification

## Severity Levels

### 🔴 CRITICAL — Blocks shipping
Code that **will not work in production**. Fake data, unimplemented functions,
deceptive returns that bypass security. Must fix before deploying.

**Criteria (any one is sufficient):**
- Function named after a critical operation but does nothing (auth, save, send, delete)
- Hardcoded mock data in production source code (not test/seed files)
- Validation function that always returns true
- Empty catch block in error-critical path
- Stub function with `throw new Error("Not implemented")`
- API URL pointing to `example.com` or `placeholder` in production config
- 95%+ identical duplicate files (clear copy-paste without purpose)

**Auto-fix allowed:** No. Always require human review.

---

### 🟡 WARNING — Should fix before shipping
Code that **works but is fragile, misleading, or incomplete**. Silent failures,
weak tests, placeholder patterns.

**Criteria (any one is sufficient):**
- TODO/FIXME/HACK comments in production code
- Empty catch blocks in non-critical paths
- Hardcoded `localhost` URLs in configuration
- `console.log("placeholder")` style markers
- Test assertions that only check `toBeDefined()`
- Skipped or commented-out tests
- Empty environment variable fallbacks `process.env.X || ""`
- Duplicate code blocks (5-20 lines identical)
- Dead conditional branches (`if (false)`)
- Orphan files not imported anywhere

**Auto-fix allowed:** Yes, for obvious cases (unused imports, empty catch → logged catch).

---

### 🟠 REDUNDANCY — Cleanup needed
Duplicate code, duplicate files, duplicate functionality that increases
maintenance burden and signals agent context loss.

**Criteria (any one is sufficient):**
- Two or more files with 80%+ content similarity
- Same export name defined in multiple files
- Same logic implemented in multiple locations (5+ lines identical)
- Same API endpoint handled by multiple route handlers
- Same type/interface defined in multiple files
- Utility function reimplemented instead of imported from existing module

**Auto-fix allowed:** No. Requires human decision on which copy to keep.

---

### ⚫ DEAD CODE — Should remove
Code that exists but serves no purpose. Unreachable paths, unused exports,
orphan files. Increases cognitive load and hides real issues.

**Criteria (any one is sufficient):**
- Exported function/class not imported by any other file
- Import statement where imported symbol is never used in file
- Code after `return` statement in same block
- Files not referenced by any import/require in the project
- Files with `old_`, `backup_`, `_deprecated` prefixes
- Large blocks of commented-out code (10+ consecutive comment lines)
- `if (false)` or `while (false)` blocks

**Auto-fix allowed:** Yes, for unused imports. Ask for file deletion.

---

### 🔵 INFO — Review recommended
Potential issues that **might be intentional**. False positives are common here.
Report them; let the human decide.

**Criteria (any one is sufficient):**
- `localhost` URL in development-specific config (might be correct)
- Single unused import (might be used by side effect)
- Fake-looking data in files that might be seeds/fixtures
- Same-named files in different directories (might serve different purposes)
- Small duplicate code blocks (< 5 lines)

**Auto-fix allowed:** No. Informational only.

---

## Confidence Score

Each finding includes a confidence score (0-100%):

| Score | Meaning | Action |
|-------|---------|--------|
| 90-100% | Almost certainly a lie | Report as-is |
| 70-89% | Likely a lie with some ambiguity | Report, mention uncertainty |
| 50-69% | Possible lie but context-dependent | Report as INFO regardless of pattern severity |
| < 50% | Probably not a lie | Do not report (suppress) |

### Confidence Adjustments

**Increase confidence (+10-20%):**
- File is in `src/` or production code directory
- Multiple lie indicators in the same file
- Function is exported (public API)
- Recent commit by AI agent (detected via commit message patterns)

**Decrease confidence (-10-20%):**
- File is in test/mock/fixture/seed/demo directory
- File has explicit "mock" or "fake" in its name
- Code has a comment explaining WHY it's like this
- File is a configuration or setup file

---

## Trust Score Calculation

Overall Trust Score is a weighted composite:

```
Trust Score = 10 - (CRITICAL * 2) - (WARNING * 0.5) - (REDUNDANCY * 0.3) - (DEAD * 0.2) - (INFO * 0.05)
Minimum: 0, Maximum: 10
```

### Code Health Metrics

**Duplication Index:**
```
Duplication Index = (duplicate lines / total lines) * 100
Target: < 5%
Warning: > 10%
Critical: > 20%
```

**Dead Code Ratio:**
```
Dead Code Ratio = (dead code lines / total lines) * 100
Target: < 3%
Warning: > 5%
Critical: > 10%
```

**Lie Density:**
```
Lie Density = total findings / total files analyzed
Target: 0
Warning: > 0.5 findings/file
Critical: > 1.0 finding/file
```

---

## Verdict Rules

| Condition | Verdict |
|-----------|---------|
| 0 CRITICAL, 0 WARNING | ✅ CLEAN — Safe to ship |
| 0 CRITICAL, 1+ WARNING | ⚠️ CAUTION — Fix warnings before shipping |
| 1+ CRITICAL | ❌ NOT SAFE TO SHIP — Critical lies detected |
| Trust Score < 3 | ❌ NOT SAFE TO SHIP — Low trust |
| Duplication > 20% | ⚠️ CAUTION — High duplication |
| Dead Code > 10% | ⚠️ CAUTION — Significant dead code |

---

## Actionable Fix Spec (required for every finding)

A FindLie report is only useful if the next agent (or human) can start editing
immediately. Every `[LIE-NNN]` entry MUST include the following seven fields.
Vague fixes like *"implement properly"* or *"add real validation"* are rejected.

| Field | Purpose | Bad example | Good example |
|---|---|---|---|
| **1. Location** | File + line span of the offending code | `src/email.ts` | `src/email.ts:11-14` |
| **2. Root cause** | One sentence naming the specific lie | "This function is fake" | "sendEmail() has no HTTP/SMTP call — only console.log" |
| **3. Evidence** | Verbatim code block from the file | (omitted) | The actual 3–6 lines that prove the lie |
| **4. Required post-fix invariant** | What MUST be true of the code after the fix — phrased as a grep-verifiable claim | "Make it work" | "Function body must contain one of: `sgMail.send`, `nodemailer.sendMail`, `fetch(`, `axios.post(`" |
| **5. Verification command** | Exact shell command the agent runs to prove the fix landed | "Test it" | `grep -E '(sgMail\|nodemailer\|fetch\|axios)' src/email.ts` — must return ≥1 match |
| **6. Exemplar (optional)** | Path:line to a correctly-implemented peer in the same codebase, if one exists | — | `src/notifications.ts:23` already uses sgMail correctly — mirror its pattern |
| **7. Confidence** | 0–100% with a one-phrase reason | `95%` | `95% — name/body mismatch is unambiguous; no test fixture context` |

### Schema (report template)

```
[LIE-<NNN>] <SHORT TITLE IN CAPS>
  Location:     <file>:<start-line>[-<end-line>]
  Type:         <type name> (Type N)
  Severity:     🔴 CRITICAL | 🟡 WARNING | 🟠 REDUNDANCY | ⚫ DEAD CODE | 🔵 INFO
  Root cause:   <one sentence>
  Evidence:
    ─────────────────────────────────
    <verbatim code, 3-6 lines>
    ─────────────────────────────────
  Required invariant: <grep-verifiable claim about post-fix state>
  Verification:       <exact shell command + expected outcome>
  Exemplar:           <file:line of correct peer, or "none in codebase">
  Confidence:         <N>% — <reason>
```

### Why each field matters

- **Location + Evidence** give the agent the exact bytes to delete.
- **Required invariant** converts "fix the thing" into a machine-checkable goal. Without it, a downstream agent can replace one lie with another.
- **Verification command** is the contract between FindLie and the fixing agent: if the command's expected outcome is met, the finding is resolved. No judgment calls.
- **Exemplar** short-circuits the "how would you want this written here?" discussion — it points at the team's actual style.

### What NOT to write as a fix

| Rejected | Why | Replace with |
|---|---|---|
| "Implement real validation" | No invariant, no verification | "Body must contain `if`/`throw` or `return false` path. Verify: `grep -E '(throw\|return false)' <file>` returns ≥1" |
| "Replace with database call" | Which DB? Which call? | "Replace with `await prisma.user.create(...)`. Exemplar: `src/users.ts:40`" |
| "Fix the hardcoded data" | Agent can replace `[{...}]` with `[{...same...}]` and satisfy this | "Remove the inline array and call `await db.query('SELECT ... FROM users')`. Verify: file no longer contains `[{\s*id:\s*[0-9]`" |
