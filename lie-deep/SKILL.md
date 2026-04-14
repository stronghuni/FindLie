---
name: lie-deep
version: 1.0.0
description: |
  Deep forensic analysis of codebase for lie code. Runs all detection phases including
  semantic analysis, integration verification, test execution, duplicate detection,
  dead code analysis, and promise fulfillment checks. Takes 10-30 minutes. Use when
  asked to "deep scan", "thorough audit", "full lie check", "forensic analysis",
  or before major releases.
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Grep
  - Glob
  - Agent
  - AskUserQuestion
  - WebSearch
---

You are **FindLie (Deep Forensics mode)**. Run the most thorough analysis possible.
Read every function. Trace every data flow. Execute tests. Verify integrations.
Leave no stone unturned.

**This will take time. That's the point.**

---

## Step 0: Scope & Setup

```bash
_BRANCH=$(git branch --show-current 2>/dev/null || echo "none")
echo "BRANCH: $_BRANCH"

# Detect language/framework
[ -f "package.json" ] && echo "RUNTIME: node" && cat package.json | head -5
[ -f "requirements.txt" ] && echo "RUNTIME: python"
[ -f "Pipfile" ] && echo "RUNTIME: python"
[ -f "go.mod" ] && echo "RUNTIME: go"
[ -f "Cargo.toml" ] && echo "RUNTIME: rust"
[ -f "Gemfile" ] && echo "RUNTIME: ruby"
[ -f "pom.xml" ] && echo "RUNTIME: java"

# Count source files
find . -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.py' -o -name '*.rb' -o -name '*.go' -o -name '*.rs' -o -name '*.java' \) -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/vendor/*' 2>/dev/null | wc -l | tr -d ' '

# Count test files
find . -type f \( -name '*.test.*' -o -name '*.spec.*' -o -name '*_test.*' \) -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null | wc -l | tr -d ' '
```

Tell the user: "Starting deep forensic scan. This will take 10-30 minutes.
I'll analyze every function, run your tests, check integrations, and hunt for
duplicates and dead code."

---

## Phase 1: Complete Static Scan

Run ALL patterns from the `/find-lie` skill Step 1, but without the `head` limits.
Scan the ENTIRE project, not just changed files.

Also add these deep patterns:

### Suspicious hardcoded credentials
```bash
rg -n '(password|secret|api_?key|token|auth)\s*[=:]\s*["'"'"'"][A-Za-z0-9_\-]{8,}["'"'"'"]' -i --glob '!**/node_modules/**' --glob '!**/test/**' --glob '!**/*.test.*' --glob '!**/README*' .
```

### Hardcoded numeric IDs
```bash
rg -n '(userId|user_id|id|ID)\s*[=:]\s*[0-9]+\b' --glob '!**/test/**' --glob '!**/*.test.*' --glob '!**/node_modules/**' --glob '!**/migration*/**' . 2>/dev/null | head -30
```

---

## Phase 2: Deep Semantic Analysis

For EVERY source file in the project (not just diff):

1. **Read each file completely**
2. **Extract all function/method definitions**
3. For each function:
   - What does the name promise?
   - What does the body actually do?
   - Does it use its parameters?
   - Does it have meaningful control flow (if/try/switch)?
   - Does it access external resources it should (DB, API, file system)?
   - Does it always return the same value?
4. Report every intent mismatch

### Deep duplicate detection within files
For each file, look for code blocks that repeat within the same file:
- Copy-pasted switch/case arms with minor variations
- Repeated if/else blocks with similar structure
- Same validation logic applied to different fields

---

## Phase 3: Full Integration Verification

### 3.1 Environment Variable Audit
```bash
# All env vars referenced in code
rg -o 'process\.env\.(\w+)' --no-filename -r '$1' . 2>/dev/null | sort -u > /tmp/findlie-env-used.txt
# All env vars defined
cat .env .env.local .env.development .env.production .env.example 2>/dev/null | grep -v '^#' | grep '=' | cut -d= -f1 | sort -u > /tmp/findlie-env-defined.txt
# Diff
comm -23 /tmp/findlie-env-used.txt /tmp/findlie-env-defined.txt
```

Report undefined env vars as WARNING.

### 3.2 Route ↔ Handler Cross-Reference
```bash
# Express/Koa-style route registrations
rg -n '(app|router)\.(get|post|put|patch|delete)\s*\(' --glob '!**/node_modules/**' . 2>/dev/null
# Next.js/Remix file-based routes
find . -path '*/app/api/*' -name 'route.*' -o -path '*/pages/api/*' 2>/dev/null
```

For each route found:
1. Extract the path and HTTP method
2. Locate the handler function it points to (follow the callback or default export)
3. Verify the handler body matches the verb: `GET` should read, `POST`/`PUT`/`PATCH` should write, `DELETE` should remove
4. Apply the Intent Map from `references/intent-map.md` to the handler
5. Flag any route whose handler is a stub, always-success return, or no-op as **Type 5 (Intent Mismatch)**

Also detect **route collisions** — same `method + path` registered in multiple
files. Report all but one as Type 9 (Redundant Files).

### 3.3 DB Schema ↔ Model Cross-Reference
```bash
# Find ORM model / schema definitions
rg -n '(model|schema|table|entity|@Entity|@Table|Schema\s*\()' --glob '!**/node_modules/**' . 2>/dev/null
# Find migration/DDL files
find . -path '*/migrations/*' -o -path '*/migrate/*' -o -name '*.sql' 2>/dev/null | grep -v node_modules
```

For each declared model:
1. List its fields/columns
2. Grep the codebase for `INSERT INTO <table>` / `prisma.<model>.create` / equivalent
3. If **no code writes** to the table, report as **Type 10 (Dead Code — orphan model)**
4. Compare model fields against migration/DDL columns — mismatches are **Type 5 (Intent Mismatch)**

### 3.4 Frontend Form ↔ Backend API Cross-Reference
```bash
# Find form field names in frontend code
rg -n '(name|id)\s*=\s*["\x27](\w+)["\x27]' --type-add 'fe:*.{tsx,jsx,vue,svelte,html}' -t fe --glob '!**/node_modules/**' . 2>/dev/null
# Find API payload shapes in backend code
rg -n '(req\.body\.|request\.json\(\)|c\.get_json\(\)|params\.|@Body\(\))' --glob '!**/node_modules/**' . 2>/dev/null
```

For each form in the frontend:
1. Collect the set of field names the form submits
2. Locate the backend handler for the form's submit URL
3. Compare the two sets — fields submitted but not read = dead data, fields
   read but not submitted = missing form input
4. Report mismatches as **Type 5 (Intent Mismatch)** or **Type 10 (Dead Code)**

### 3.5 Type Definition ↔ Usage Cross-Reference
```bash
# Find exported type/interface definitions
rg -n 'export\s+(type|interface)\s+(\w+)' --no-filename -o -r '$2' . 2>/dev/null | sort -u
```

For each exported type:
1. Check if it's imported anywhere
2. If imported 0 times → **Type 10 (Dead Code)**
3. If the same type name is defined in multiple files with different shapes →
   **Type 9 (Redundant Files)** — pick one, have the others re-export

---

## Phase 4: Test Execution & Analysis

### 4.1 Run Tests
```bash
# Detect test framework and run
if [ -f "package.json" ]; then
  if grep -q '"vitest"' package.json 2>/dev/null; then
    npx vitest run --reporter=verbose 2>&1 | tail -50
  elif grep -q '"jest"' package.json 2>/dev/null; then
    npx jest --verbose 2>&1 | tail -50
  elif grep -q '"mocha"' package.json 2>/dev/null; then
    npx mocha --reporter spec 2>&1 | tail -50
  else
    npm test 2>&1 | tail -50
  fi
elif [ -f "pytest.ini" ] || [ -f "setup.cfg" ] || [ -f "pyproject.toml" ]; then
  python -m pytest -v 2>&1 | tail -50
fi
```

### 4.2 Analyze Test Quality
For each test file:
1. Read the test file
2. Count assertions per test case (< 1 is suspicious)
3. Check assertion specificity (`.toBe(specific_value)` vs `.toBeDefined()`)
4. Check if test actually invokes the function under test or just a mock
5. Check test-to-source ratio

Report weakly-tested or mock-only tests as Type 7.

---

## Phase 5: Complete Redundancy & Dead Code Analysis

### 5.1 Full Duplicate Detection
Run all dupication checks from `/find-lie` Step 5 without limits.

Additionally, for files with similar names:
```bash
# Find similarly-named files that might be duplicates
find . -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.py' \) -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null | xargs -I{} basename {} | sort | uniq -d | while read dup; do
  echo "SIMILAR_NAME: $dup"
  find . -name "$dup" -not -path '*/node_modules/*' -not -path '*/.git/*'
done
```

For each pair of similar files, read both and compare line-by-line.

### 5.2 Full Dead Code Analysis

**Import graph construction:**
```bash
# Build a simplified import graph
for f in $(find . -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' \) -not -path '*/node_modules/*' -not -path '*/.git/*' -not -name '*.d.ts' 2>/dev/null); do
  IMPORTS=$(rg "from\s+['\"](\./|\.\./)" "$f" -o 2>/dev/null | sed "s/from //;s/['\"]//g")
  [ -n "$IMPORTS" ] && echo "$f -> $IMPORTS"
done
```

Identify files that NO other file points to (orphan files).

**Comprehensive unused export scan:**
For every exported symbol, verify it's consumed somewhere.

---

## Phase 6: Promise Fulfillment (Extended)

Same as `/find-lie` Step 6, but also:

1. Read ALL commit messages since branch creation
2. Read PR description, PR comments, and linked issues
3. Read TODOS.md, plan files, and design documents
4. Build a complete "promise inventory"
5. Cross-reference EVERY promise against the diff
6. Report completion percentage

---

## Phase 7: Generate Deep Report

Use the same **Actionable Fix Spec** schema as `/find-lie` Step 7 — every
finding must include Location, Root cause, Evidence, Required invariant,
Verification command, Exemplar, and Confidence. See `references/severity.md`.

Additions specific to deep mode:

### Extended Summary Section
```
═══════════════════════════════════════════════════════
DEEP ANALYSIS SUMMARY
═══════════════════════════════════════════════════════

  Files analyzed:        <N>
  Functions analyzed:    <N>
  Tests executed:        <pass>/<total> (<fail> failed)
  Test coverage:         <N>% (if available)
  Promises tracked:      <fulfilled>/<total>

  🔴 CRITICAL:    <N>    (fake/broken code)
  🟡 WARNING:     <N>    (fragile/incomplete code)
  🟠 REDUNDANCY:  <N>    (duplicate code/files)
  ⚫ DEAD CODE:    <N>    (unused/unreachable code)
  🔵 INFO:        <N>    (review recommended)

  VERDICT: <verdict>

  Trust Score: <N>/10
  Code Health:
    Duplication Index: <N>% (target: <5%)
    Dead Code Ratio:   <N>% (target: <3%)
    Lie Density:       <N> findings/file
    Test Quality:      <N>/10
    Promise Fulfillment: <N>%
```

### Write report to file
```bash
# Save the report
cat > FINDLIE-REPORT.md << 'EOF'
# FindLie Deep Analysis Report
Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Branch: $_BRANCH

<full report content>
EOF
```

Tell the user: "Deep analysis saved to FINDLIE-REPORT.md"

After the report, use AskUserQuestion:

> Deep forensic scan complete. What would you like to do?
> A) Fix all CRITICAL issues now (I'll make the changes)
> B) Fix everything — CRITICAL + WARNING + cleanup duplicates + remove dead code
> C) I'll review the report and handle it myself
