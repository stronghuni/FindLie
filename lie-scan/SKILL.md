---
name: lie-scan
version: 1.0.0
description: |
  Quick static scan for lie code — mock data, stubs, empty catches, placeholder URLs,
  dead code indicators, and duplicate files. Runs in under 30 seconds. No code execution,
  no test running, no deep analysis. Use for fast pre-commit checks or CI integration.
  Trigger: "quick scan", "fast check", "scan for lies", "pre-commit check".
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - AskUserQuestion
---

You are **FindLie (Quick Scan mode)**. Run a fast, pattern-based scan for lie code.
No deep analysis. No code execution. Just grep and report.

**Target: under 30 seconds.**

---

## Step 0: Detect invocation mode

Before anything else, decide whether this is an interactive scan or a CI scan.

```bash
_CI_MODE="interactive"
# Any of these flip the scan into CI mode
case " $* " in *" --ci "*) _CI_MODE="ci" ;; esac
[ -n "${CI:-}" ] && _CI_MODE="ci"
[ -n "${FINDLIE_CI:-}" ] && _CI_MODE="ci"
[ ! -t 1 ] && _CI_MODE="ci"   # stdout is not a TTY (piped/redirected)
echo "CI_MODE: $_CI_MODE"
```

Behavior differences:

| Step                  | interactive                 | ci                              |
| --------------------- | --------------------------- | ------------------------------- |
| Output                | Pretty report               | Machine-readable (one line/hit) |
| Final `AskUserQuestion` | Yes — ask what to fix     | **Skipped** — never prompt      |
| Exit code semantics   | Always 0                    | 0=clean, 1=warning, 2=critical  |
| Evidence snippets     | Included                    | Omitted (just `file:line:type`) |

**Exit-code contract (CI mode):**
- `0` → no findings at CRITICAL or WARNING severity
- `1` → at least one WARNING but no CRITICAL
- `2` → at least one CRITICAL (blocks the pipeline)

Set the exit code as the last step of the skill.

---

## Step 1: Determine scope

```bash
_BRANCH=$(git branch --show-current 2>/dev/null || echo "none")
if [ "$_BRANCH" != "none" ]; then
  _BASE=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
  [ -z "$_BASE" ] && _BASE="main"
  _FILES=$(git diff origin/$_BASE --name-only 2>/dev/null | grep -E '\.(ts|tsx|js|jsx|py|rb|go|rs|java|kt|swift|c|cpp|cs|php|vue|svelte)$')
  _COUNT=$(echo "$_FILES" | grep -c . || echo 0)
  echo "MODE: diff"
  echo "FILES: $_COUNT"
else
  _COUNT=$(find . -type f \( -name '*.ts' -o -name '*.js' -o -name '*.py' -o -name '*.tsx' -o -name '*.jsx' \) -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null | wc -l | tr -d ' ')
  echo "MODE: full"
  echo "FILES: $_COUNT"
fi
```

---

## Step 2: Run all pattern scans

Run these scans in sequence. Collect results.

### Mock/Fake Data (Type 1)
```bash
rg -n '["'"'"'"](john|jane|test|user|admin|foo|bar)@(example|test|fake|dummy)\.' -i --glob '!**/test/**' --glob '!**/mock/**' --glob '!**/*.test.*' --glob '!**/*.spec.*' --glob '!**/README*' --glob '!**/node_modules/**' . 2>/dev/null | head -20
```

### Stubs (Type 2)
```bash
rg -n '\b(TODO|FIXME|HACK|XXX)\b' --glob '!**/node_modules/**' --glob '!**/vendor/**' . 2>/dev/null | head -30
```

```bash
rg -n 'throw\s+new\s+Error\s*\(\s*["'"'"'"](not|todo|fixme)' -i --glob '!**/node_modules/**' . 2>/dev/null | head -10
```

### Empty Catches (Type 3)
```bash
rg -n 'catch\s*\([^)]*\)\s*\{\s*\}' --glob '!**/node_modules/**' . 2>/dev/null | head -10
```

### Placeholder URLs (Type 6)
```bash
rg -n '["'"'"'"](https?://)?(example\.(com|org|net)|placeholder\.[a-z]{2,6}(/|["'"'"'"])|your-?api\.|fake-?api\.|httpbin\.org)' --glob '!**/test/**' --glob '!**/README*' --glob '!**/docs/**' --glob '!**/*.test.*' --glob '!**/node_modules/**' . 2>/dev/null | head -10
```

### Test Deception (Type 7)
```bash
rg -n 'expect\s*\(\s*(true|1)\s*\)\s*\.to(Be|Equal)' --glob '**/*.test.*' --glob '**/*.spec.*' . 2>/dev/null | head -10
rg -n '(it|test|describe)\.(skip|todo)\s*\(' --glob '**/*.test.*' --glob '**/*.spec.*' . 2>/dev/null | head -10
```

### Duplicate Files (Type 8)
```bash
find . -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.py' \) -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/vendor/*' 2>/dev/null | xargs shasum -a 256 2>/dev/null | sort | awk '{print $1}' | uniq -d | while read hash; do
  echo "IDENTICAL FILES:"
  grep "$hash" <(find . -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.py' \) -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null | xargs shasum -a 256 2>/dev/null) | awk '{print "  " $2}'
done
```

### Deprecated/Old Files (Type 10)
```bash
find . -type f \( -name 'old_*' -o -name 'backup_*' -o -name '*_deprecated*' -o -name '*_old.*' -o -name '*.bak' -o -name '*.orig' \) -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null | head -10
```

### Dead Conditionals (Type 10)
```bash
rg -n 'if\s*\(\s*(false|0|!1)\s*\)' --glob '!**/node_modules/**' . 2>/dev/null | head -10
```

### Unused Imports (Type 10)
```bash
# Quick check: find imports and see if they're used
for f in $(git diff origin/${_BASE:-main} --name-only 2>/dev/null | grep -E '\.(ts|tsx|js|jsx)$' | head -10); do
  rg '^import\s+\{([^}]+)\}' "$f" -o -r '$1' 2>/dev/null | tr ',' '\n' | tr -d ' ' | while read sym; do
    [ -z "$sym" ] && continue
    _USES=$(rg -c "\b${sym}\b" "$f" 2>/dev/null || echo 0)
    if [ "$_USES" -le 1 ] 2>/dev/null; then
      echo "UNUSED_IMPORT: ${sym} in ${f}"
    fi
  done
done
```

---

## Step 3: Quick Report

### Interactive mode output

```
🔍 FindLie Quick Scan
━━━━━━━━━━━━━━━━━━━━
Files scanned: <N>
Mode: <diff|full>

Findings:
  🔴 CRITICAL: <N>
  🟡 WARNING:  <N>
  🟠 DUPLICATE: <N>
  ⚫ DEAD CODE: <N>
  🔵 INFO:     <N>

<list each finding: one line per item>
  [TYPE] file:line — description — fix: <one-line action>

VERDICT: <✅ CLEAN | ⚠️ CAUTION | ❌ LIES DETECTED>

💡 Run /find-lie for deep analysis with semantic checks and test verification.
```

**Every finding line MUST end with `— fix: <action>`.** The action must be
concrete enough for the acting agent to start editing without asking questions
(e.g., `fix: replace with fetch() to API_URL`, not `fix: implement properly`).
See `references/severity.md` → **Actionable Fix Spec** for the full schema.

### CI mode output

Emit one line per finding to stdout in this exact format (stable for
`grep`/`awk` consumption):

```
<severity>\t<type>\t<file>:<line>\t<short-description>\t<fix-action>
```

Example:
```
CRITICAL	T5	src/email.ts:12	sendEmail has no HTTP/SMTP call	replace body with sgMail.send(msg) using SENDGRID_API_KEY
WARNING	T2	src/sync.ts:8	TODO marker in production path	remove TODO and implement real sync() or delete the stub
```

Then a final summary line:
```
SUMMARY	critical=<N>	warning=<N>	dead=<N>	info=<N>	exit=<0|1|2>
```

Set the exit code before finishing.

---

## Step 4: Next-action prompt (interactive only)

Skip this entire step if `_CI_MODE == "ci"`.

Use `AskUserQuestion`:
> Quick scan complete. What would you like to do?
> A) Fix all CRITICAL now
> B) Run `/find-lie` for semantic analysis
> C) Done — I'll handle it manually
